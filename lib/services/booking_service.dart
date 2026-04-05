import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_time_utils.dart';
import '../core/utils/qr_utils.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/retry_utils.dart';
import '../features/booking/data/models/booking_model.dart';
import '../features/booking/data/models/facility_model.dart';
import '../features/auth/data/models/user_model.dart';
import '../features/referee/data/models/referee_job_model.dart';
import '../services/tournament_service.dart';
import '../services/notification_service.dart';
import '../services/payment_service.dart';
import '../services/facility_service.dart';
import '../services/referee_service.dart';

/// Booking service for creating, updating, and managing bookings
/// Delegates facility queries to FacilityService
class BookingService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();
  final NotificationService? _notificationService;
  final FacilityService _facilityService;

  BookingService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
    FacilityService? facilityService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationService = notificationService,
       _facilityService =
           facilityService ?? FacilityService(firestore: firestore);

  // ═══════════════════════════════════════════════════════════════════════════
  // FACILITIES (Delegated to FacilityService)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all active facilities
  Future<List<FacilityModel>> getFacilities() =>
      _facilityService.getFacilities();

  /// Get facilities by sport type
  Future<List<FacilityModel>> getFacilitiesBySport(SportType sport) =>
      _facilityService.getFacilitiesBySport(sport);

  /// Get single facility by ID
  Future<FacilityModel?> getFacilityById(String facilityId) =>
      _facilityService.getFacilityById(facilityId);

  // ═══════════════════════════════════════════════════════════════════════════
  // TIME SLOTS & AVAILABILITY (Delegated to FacilityService)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get available time slots for a facility on a specific date
  Future<List<TimeSlot>> getAvailableSlots({
    required String facilityId,
    required DateTime date,
    String? subUnit,
  }) => _facilityService.getAvailableSlots(
    facilityId: facilityId,
    date: date,
    subUnit: subUnit,
  );

  /// Get available sub-units (courts) for badminton on a specific slot
  Future<List<String>> getAvailableCourts({
    required String facilityId,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
  }) => _facilityService.getAvailableCourts(
    facilityId: facilityId,
    date: date,
    startTime: startTime,
    endTime: endTime,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOKINGS - CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create a new booking
  ///
  /// Note: Referees are optionally available for normal bookings (practice sessions).
  /// For tournaments, referees are automatically assigned via TournamentService.
  Future<BookingResult> createBooking({
    required FacilityModel facility,
    required UserModel user,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    String? subUnit,
    BookingType? bookingType,
    TournamentFormat? tournamentFormat,
    bool requestReferee = false, // Optional referee for practice sessions
  }) async {
    try {
      // For facilities with subUnits (like badminton), subUnit is REQUIRED
      if (facility.hasSubUnits && (subUnit == null || subUnit.isEmpty)) {
        return BookingResult.failure(
          'Court selection is required for this facility. Please select a court.',
        );
      }

      // For facilities without subUnits, ensure subUnit is null
      if (!facility.hasSubUnits && subUnit != null) {
        return BookingResult.failure('This facility does not have sub-units');
      }

      // Validate time slot
      if (DateTimeUtils.hasPassed(startTime)) {
        return BookingResult.failure('Cannot book slots in the past');
      }

      // Check availability using FacilityService
      final isAvailable = await _facilityService.checkSlotAvailability(
        facilityId: facility.id,
        date: date,
        startTime: startTime,
        endTime: endTime,
        subUnit: subUnit,
      );

      if (!isAvailable) {
        return BookingResult.failure(
          'Selected time slot is no longer available',
        );
      }

      // Calculate fees using FacilityService
      final facilityFee = _facilityService.calculateFacilityFee(
        facility,
        user.isStudent,
        startTime,
        endTime,
      );

      // Calculate referee fee if requested (practice sessions use lower rate)
      double? refereeFee;
      if (requestReferee && user.isStudent) {
        final refereesRequired = _facilityService.getRefereesRequired(
          facility.sport,
        );
        refereeFee = refereesRequired * AppConstants.refereeEarningsPractice;
      }
      final totalAmount = facilityFee + (refereeFee ?? 0);

      // ⭐ PRE-VALIDATION: Check wallet balance BEFORE creating booking
      // Both students AND public users must have sufficient balance
      final paymentService = PaymentService();
      final wallet = await paymentService.getWallet(user.uid);

      // Check wallet balance for ALL users (students and public)
      if (wallet == null) {
        return BookingResult.failure(
          'Wallet not found. Please try again or contact support.',
        );
      }

      if (!wallet.hasSufficientBalance(totalAmount)) {
        final shortfall = totalAmount - wallet.balance;
        return BookingResult.failure(
          'Insufficient wallet balance. You have RM ${wallet.balance.toStringAsFixed(2)} but need RM ${totalAmount.toStringAsFixed(2)}. '
          'Please top up RM ${shortfall.toStringAsFixed(2)} to continue.',
        );
      }

      // Generate booking ID
      final bookingId = _uuid.v4();

      // Create booking (QR code will be generated and added after)
      final booking = BookingModel(
        id: bookingId,
        facilityId: facility.id,
        facilityName: facility.name,
        sport: facility.sport,
        userId: user.uid,
        userName: user.displayName,
        userEmail: user.email,
        isStudentBooking: user.isStudent,
        subUnit: subUnit,
        bookingDate: DateTimeUtils.startOfDay(date),
        startTime: startTime,
        endTime: endTime,
        facilityFee: facilityFee,
        refereeFee: refereeFee, // Optional referee fee for practice sessions
        totalAmount: totalAmount,
        status: BookingStatus.pendingPayment, // Will be confirmed after payment
        bookingType: bookingType,
        tournamentFormat: tournamentFormat,
        tournamentTeams: tournamentFormat?.teamCount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Generate initial QR code using QRUtils (base64-encoded JSON)
      // Will be updated with actual refereeJobId if referee is requested
      final initialQrCode = QRUtils.generateBookingQR(
        bookingId: bookingId,
        refereeJobId:
            '', // Will be updated after referee job creation if needed
        facilityName: facility.name,
        dateTime: startTime,
      );

      // Create booking with initial QR code
      final bookingWithQr = booking.copyWith(qrCode: initialQrCode);

      // Save to Firestore with retry mechanism
      await RetryUtils.retry(
        operation: () async {
          await _firestore
              .collection(AppConstants.bookingsCollection)
              .doc(bookingId)
              .set(bookingWithQr.toFirestore());
        },
        config: RetryConfig.network,
      );

      // Note: Referee jobs are now created AFTER payment confirmation

      // Create tournament bracket if Match booking with tournament format
      if (bookingType == BookingType.match && tournamentFormat != null) {
        try {
          final tournamentService = TournamentService();
          final bracket = await tournamentService.generateBracket(
            format: tournamentFormat,
            bookingId: bookingId,
            teamIds: [], // Will be populated as participants join
          );

          // Save bracket to Firestore
          await _firestore
              .collection('tournaments')
              .doc(bookingId)
              .set(bracket);
        } catch (e) {
          // Tournament bracket creation is non-critical - continue with booking
          // Error is caught and ignored since booking itself succeeded
        }
      }

      return BookingResult.success(bookingWithQr);
    } catch (e) {
      return BookingResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'booking'),
      );
    }
  }

  /// Get user's bookings
  /// Returns ALL bookings for the user regardless of user type (student/public/referee/admin)
  /// Unified system: All bookings are stored in the same collection
  Future<List<BookingModel>> getUserBookings(
    String userId,
    String userEmail, {
    int limit = 100,
  }) async {
    try {
      // Query 1: Bookings where user is the organizer
      final organizerSnapshot =
          await _firestore
              .collection(AppConstants.bookingsCollection)
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      // Convert to BookingModel list
      final allBookings =
          organizerSnapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList();

      // Trigger automatic referee job cleanup for past bookings (background processing)
      // This ensures referee jobs are completed or cancelled when booking time passes
      _processRefereeJobCleanupInBackground(allBookings);

      return allBookings;
    } catch (e) {
      // Return empty list on error rather than crashing
      // UI will handle empty state gracefully
      return [];
    }
  }

  /// Get upcoming bookings for user
  /// Unified system: Works for ALL user types (student/public/referee/admin)
  Future<List<BookingModel>> getUpcomingBookings(
    String userId,
    String userEmail,
  ) async {
    try {
      final now = DateTime.now();

      // Get all user bookings (organizer + participant)
      final allBookings = await getUserBookings(userId, userEmail);

      final activeStatuses = [
        BookingStatus.confirmed.code,
        BookingStatus.pendingPayment.code,
      ];

      // Filter for upcoming active bookings
      return allBookings
          .where(
            (booking) =>
                booking.startTime.isAfter(now) &&
                activeStatuses.contains(booking.status.code),
          )
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      // Return empty list on error - UI handles gracefully
      return [];
    }
  }

  /// Cancel booking
  Future<BookingResult> cancelBooking({
    required String bookingId,
    required String reason,
    bool forceRefund = false,
  }) async {
    try {
      final doc =
          await _firestore
              .collection(AppConstants.bookingsCollection)
              .doc(bookingId)
              .get();

      if (!doc.exists) {
        return BookingResult.failure('Booking not found');
      }

      final booking = BookingModel.fromFirestore(doc);

      if (!booking.isActive) {
        return BookingResult.failure(
          'Booking is already cancelled or completed',
        );
      }

      // Check cancellation policy (24 hours) - with retry
      await RetryUtils.retry(
        operation: () async {
          await _firestore
              .collection(AppConstants.bookingsCollection)
              .doc(bookingId)
              .update({
                'status': BookingStatus.cancelled.code,
                'cancellationReason': reason,
                'cancelledAt': Timestamp.now(),
                'updatedAt': Timestamp.now(),
              });
        },
        config: RetryConfig.network,
      );

      // ═══════════════════════════════════════════════════════════════════════════
      // REFUND ESCROW AND NOTIFY REFEREES
      // ═══════════════════════════════════════════════════════════════════════════

      // Cancel referee job and refund escrow if exists
      if (booking.refereeJobId != null) {
        try {
          // Get referee job to notify assigned referees
          final jobDoc =
              await _firestore
                  .collection(AppConstants.jobsCollection)
                  .doc(booking.refereeJobId)
                  .get();

          if (jobDoc.exists) {
            final job = RefereeJobModel.fromFirestore(jobDoc);

            // Refund escrow to organizer (automatically refunded)
            if (booking.refereeFee != null && booking.refereeFee! > 0) {
              try {
                final paymentService = PaymentService(
                  notificationService: _notificationService,
                );
                await paymentService.refundEscrow(booking.id, booking.userId);
                // Escrow refund successful
              } catch (e) {
                // Continue with job cancellation even if escrow refund fails
                // Escrow will need to be manually processed
              }
            }

            // Notify assigned referees about job cancellation
            if (job.assignedReferees.isNotEmpty) {
              try {
                final notificationService =
                    _notificationService ?? NotificationService();
                for (final referee in job.assignedReferees) {
                  await notificationService.createNotification(
                    userId: referee.userId,
                    type: NotificationType.refereeJobCancelled,
                    title: 'Referee Job Cancelled',
                    body:
                        'The ${job.sport.displayName} job at ${job.facilityName} has been cancelled',
                    relatedId: job.id,
                    route: '/referee',
                    data: {'bookingId': booking.id, 'reason': reason},
                  );
                }
              } catch (e) {
                // Continue even if notification fails
                // Notifications are non-critical
              }
            }
          }

          // Update referee job status to cancelled - with retry
          await RetryUtils.retry(
            operation: () async {
              await _firestore
                  .collection(AppConstants.jobsCollection)
                  .doc(booking.refereeJobId)
                  .update({
                    'status': JobStatus.cancelled.code,
                    'updatedAt': Timestamp.now(),
                  });
            },
            config: RetryConfig.quick,
          );
        } catch (e) {
          // Continue with booking cancellation even if referee job handling fails
          // Job status will be handled separately
        }
      }

      return BookingResult.success(
        booking.copyWith(
          status: BookingStatus.cancelled,
          cancellationReason: reason,
          cancelledAt: DateTime.now(),
        ),
      );
    } catch (e) {
      return BookingResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(
          e,
          context: 'booking',
          defaultMessage: 'Unable to cancel booking. Please try again.',
        ),
      );
    }
  }

  /// Confirm booking payment
  Future<BookingResult> confirmPayment(String bookingId) async {
    try {
      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .update({
            'status': BookingStatus.confirmed.code,
            'updatedAt': Timestamp.now(),
          });

      final doc =
          await _firestore
              .collection(AppConstants.bookingsCollection)
              .doc(bookingId)
              .get();

      return BookingResult.success(BookingModel.fromFirestore(doc));
    } catch (e) {
      return BookingResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'payment'),
      );
    }
  }

  /// Update booking status (general purpose)
  Future<bool> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .update({'status': status.code, 'updatedAt': Timestamp.now()});
      return true;
    } catch (e) {
      throw Exception(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'booking'),
      );
    }
  }

  /// Get booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc =
          await _firestore
              .collection(AppConstants.bookingsCollection)
              .doc(bookingId)
              .get();

      if (!doc.exists) {
        return null;
      }

      final booking = BookingModel.fromFirestore(doc);

      // Trigger cleanup check for this specific booking (single booking background processing)
      Future.microtask(() async {
        _processRefereeJobCleanupInBackground([booking]);
      });

      return booking;
    } catch (e) {
      // Re-throw so FutureProvider.error() is triggered properly
      rethrow;
    }
  }

  /// Stream booking by ID for real-time updates
  Stream<BookingModel?> bookingStream(String bookingId) {
    return _firestore
        .collection(AppConstants.bookingsCollection)
        .doc(bookingId)
        .snapshots()
        .map((doc) => doc.exists ? BookingModel.fromFirestore(doc) : null);
  }

  /// Background processing for referee job cleanup (non-blocking)
  /// Processes past bookings to complete or cancel their referee jobs
  void _processRefereeJobCleanupInBackground(List<BookingModel> bookings) {
    // Run cleanup in background to avoid blocking UI
    Future.microtask(() async {
      try {
        final now = DateTime.now();

        // Find bookings that have passed endTime and have referee jobs
        final expiredBookingsWithReferees =
            bookings
                .where(
                  (booking) =>
                      booking.refereeJobId != null &&
                      booking.refereeJobId!.isNotEmpty &&
                      now.isAfter(booking.endTime),
                )
                .toList();

        if (expiredBookingsWithReferees.isEmpty) {
          return;
        }

        debugPrint(
          '🔧 Background cleanup: Processing ${expiredBookingsWithReferees.length} expired booking referee jobs',
        );

        // Process each expired booking's referee job
        for (final booking in expiredBookingsWithReferees) {
          await processRefereeJobCleanup(booking);
        }

        debugPrint(
          '✅ Background cleanup completed for ${expiredBookingsWithReferees.length} bookings',
        );
      } catch (e) {
        debugPrint('⚠️ Background referee job cleanup error: $e');
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REFEREE JOB MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Automatic cleanup for referee jobs linked to normal facility bookings
  /// Reuses existing tournament auto-completion logic from TournamentService
  Future<void> processRefereeJobCleanup(BookingModel booking) async {
    // Only process if booking has a referee job
    if (booking.refereeJobId == null || booking.refereeJobId!.isEmpty) {
      return;
    }

    // Only process if booking time has passed
    final now = DateTime.now();
    if (!now.isAfter(booking.endTime)) {
      return;
    }

    try {
      final refereeService = RefereeService();

      // Get referee job to check current status
      final jobDoc =
          await _firestore
              .collection(AppConstants.jobsCollection)
              .doc(booking.refereeJobId)
              .get();

      if (!jobDoc.exists) {
        debugPrint(
          '⚠️ Referee job ${booking.refereeJobId} not found for booking ${booking.id}',
        );
        return;
      }

      final job = RefereeJobModel.fromFirestore(jobDoc);

      // Skip if job is already completed or cancelled
      if (job.status == JobStatus.completed ||
          job.status == JobStatus.cancelled) {
        return;
      }

      debugPrint(
        '⏰ Booking time has passed - processing referee job cleanup for booking ${booking.id}',
      );

      if (job.assignedReferees.isNotEmpty) {
        // Auto-complete assigned referee jobs (reuse tournament logic)
        // This will release escrow to assigned referees
        final result = await refereeService.completeJob(
          jobId: job.id,
          organizerUserId: booking.userId,
          allowAutoComplete: true, // Allow auto-completion when time has passed
        );

        if (result.success) {
          debugPrint(
            '✅ Auto-completed referee job ${job.id} for booking ${booking.id}',
          );
        } else {
          debugPrint(
            '⚠️ Failed to auto-complete referee job ${job.id}: ${result.errorMessage}',
          );
        }
      } else {
        // Cancel unaccepted jobs and refund escrow to organizer
        // Update job status to cancelled
        await _firestore
            .collection(AppConstants.jobsCollection)
            .doc(job.id)
            .update({
              'status': JobStatus.cancelled.code,
              'updatedAt': Timestamp.now(),
            });

        // Refund referee fee to organizer's wallet
        if (booking.refereeFee != null && booking.refereeFee! > 0) {
          try {
            final paymentService = PaymentService(
              notificationService: _notificationService,
            );
            await paymentService.refundEscrow(booking.id, booking.userId);
            debugPrint(
              '✅ Refunded referee fee (RM${booking.refereeFee}) to organizer for unaccepted job ${job.id}',
            );
          } catch (e) {
            debugPrint(
              '⚠️ Failed to refund escrow for unaccepted job ${job.id}: $e',
            );
          }
        }

        debugPrint(
          '✅ Cancelled unaccepted referee job ${job.id} for booking ${booking.id}',
        );
      }
    } catch (e) {
      debugPrint(
        '⚠️ Error processing referee job cleanup for booking ${booking.id}: $e',
      );
    }
  }

  /// Create referee job for a confirmed booking (called after payment confirmation)
  /// This is a public method that can be called from PaymentService
  Future<String?> createRefereeJobForBooking({
    required BookingModel booking,
    required UserModel user,
  }) async {
    // Only create job if referee was requested and booking is confirmed
    if (booking.refereeFee == null || booking.refereeFee! <= 0) {
      return null;
    }

    if (booking.status != BookingStatus.confirmed) {
      return null;
    }

    // Check if referee job already exists (prevent duplicates)
    if (booking.refereeJobId != null && booking.refereeJobId!.isNotEmpty) {
      // Verify the job actually exists in Firestore
      try {
        final existingJobDoc =
            await _firestore
                .collection(AppConstants.jobsCollection)
                .doc(booking.refereeJobId)
                .get();

        if (existingJobDoc.exists) {
          return booking.refereeJobId;
        }
      } catch (e) {
        // Continue to create new job if check fails
      }
    }

    return await _createRefereeJobForBooking(
      bookingId: booking.id,
      facilityId: booking.facilityId,
      facilityName: booking.facilityName,
      sport: booking.sport,
      user: user,
      startTime: booking.startTime,
      endTime: booking.endTime,
      refereeFee: booking.refereeFee!,
    );
  }

  /// Internal helper to create referee job for a booking
  Future<String?> _createRefereeJobForBooking({
    required String bookingId,
    required String facilityId,
    required String facilityName,
    required SportType sport,
    required UserModel user,
    required DateTime startTime,
    required DateTime endTime,
    required double refereeFee,
  }) async {
    try {
      final jobId = _uuid.v4();
      final refereesRequired = _facilityService.getRefereesRequired(sport);

      final job = RefereeJobModel(
        id: jobId,
        bookingId: bookingId,
        facilityId: facilityId,
        facilityName: facilityName,
        sport: sport,
        matchDate: DateTimeUtils.startOfDay(startTime),
        startTime: startTime,
        endTime: endTime,
        location: facilityName,
        earnings: refereeFee / refereesRequired, // Earnings per referee
        refereesRequired: refereesRequired,
        status: JobStatus.open,
        organizerUserId: user.uid,
        organizerName: user.displayName,
        notes: 'Practice Session Booking - $facilityName',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.jobsCollection)
          .doc(jobId)
          .set(job.toFirestore());

      return jobId;
    } catch (e) {
      // Return null on failure - non-critical operation
      return null;
    }
  }
}

/// Booking result wrapper
class BookingResult {
  final bool success;
  final BookingModel? booking;
  final String? errorMessage;

  const BookingResult._({
    required this.success,
    this.booking,
    this.errorMessage,
  });

  factory BookingResult.success(BookingModel booking) {
    return BookingResult._(success: true, booking: booking);
  }

  factory BookingResult.failure(String message) {
    return BookingResult._(success: false, errorMessage: message);
  }
}
