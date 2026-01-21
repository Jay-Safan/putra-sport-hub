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
import '../services/referee_service.dart';

/// Booking service for facility reservations
class BookingService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();
  final NotificationService? _notificationService;

  BookingService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService;

  // ═══════════════════════════════════════════════════════════════════════════
  // FACILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all active facilities
  Future<List<FacilityModel>> getFacilities() async {
    final snapshot = await _firestore
        .collection(AppConstants.facilitiesCollection)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => FacilityModel.fromFirestore(doc)).toList();
  }

  /// Get facilities by sport type
  Future<List<FacilityModel>> getFacilitiesBySport(SportType sport) async {
    final snapshot = await _firestore
        .collection(AppConstants.facilitiesCollection)
        .where('sport', isEqualTo: sport.code)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => FacilityModel.fromFirestore(doc)).toList();
  }

  /// Get single facility by ID
  Future<FacilityModel?> getFacilityById(String facilityId) async {
    final doc = await _firestore
        .collection(AppConstants.facilitiesCollection)
        .doc(facilityId)
        .get();

    if (doc.exists) {
      return FacilityModel.fromFirestore(doc);
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIME SLOTS & AVAILABILITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get available time slots for a facility on a specific date
  /// For facilities with subUnits (like badminton), each court has independent availability
  /// If no subUnit is specified for a facility with subUnits, returns empty list
  Future<List<TimeSlot>> getAvailableSlots({
    required String facilityId,
    required DateTime date,
    String? subUnit,
  }) async {
    final facility = await getFacilityById(facilityId);
    if (facility == null) return [];

    // For facilities with subUnits, subUnit is REQUIRED to check availability
    // Each court has independent time slots - Court 1 bookings don't affect Court 2
    if (facility.hasSubUnits && (subUnit == null || subUnit.isEmpty)) {
      // Return empty list - court must be selected first
      return [];
    }

    // Generate slots based on facility type
    List<TimeSlot> slots;
    if (facility.type == FacilityType.session) {
      slots = DateTimeUtils.generateSessionSlots(date);
    } else {
      slots = DateTimeUtils.generateHourlySlots(date);
    }

    // Check for blackout dates
    final isBlackout = await _isBlackoutDate(date);
    if (isBlackout) {
      return []; // No slots available on blackout dates
    }

    // Get existing bookings for this facility/date/court
    // For facilities with subUnits, this will only return bookings for the specific court
    // Each court's bookings are completely independent
    final bookedSlots = await _getBookedSlots(facilityId, date, subUnit);

    // Mark unavailable slots - only based on bookings for THIS specific court
    return slots.map((slot) {
      final isBooked = bookedSlots.any((booked) =>
          slot.startTime.isBefore(booked.end) &&
          slot.endTime.isAfter(booked.start));
      return slot.copyWith(isAvailable: !isBooked);
    }).toList();
  }

  /// Get booked time ranges for a facility
  /// UNIFIED SYSTEM: Includes ALL bookings (normal bookings + tournament bookings)
  /// Tournament bookings are created through BookingService, so they're already in bookings collection
  /// For facilities with subUnits (like badminton courts), each court has independent availability
  Future<List<({DateTime start, DateTime end})>> _getBookedSlots(
    String facilityId,
    DateTime date,
    String? subUnit,
  ) async {
    final bookingDate = DateTimeUtils.startOfDay(date);
    
    // Get facility to check if it has subUnits
    final facility = await getFacilityById(facilityId);
    final hasSubUnits = facility?.hasSubUnits ?? false;

    // UNIFIED QUERY: Get ALL bookings for this facility/date
    // This includes both normal bookings AND tournament bookings (since tournaments create bookings)
    // Simple query - just facility and exact date
    // Filter status and sub-unit in code to avoid complex index
    final snapshot = await _firestore
        .collection(AppConstants.bookingsCollection)
        .where('facilityId', isEqualTo: facilityId)
        .where('bookingDate', isEqualTo: Timestamp.fromDate(bookingDate))
        .get();

    // Active booking statuses that block availability
    // Includes confirmed bookings, pending payments, and in-progress bookings
    // Tournament bookings use the same status system, so they're automatically included
    final activeStatuses = [
      BookingStatus.confirmed.code,
      BookingStatus.pendingPayment.code,
      BookingStatus.inProgress.code,
    ];

    final bookedSlots = <({DateTime start, DateTime end})>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      
      // Filter by active status - only include bookings that block availability
      if (!activeStatuses.contains(data['status'])) {
        continue;
      }
      
      // For facilities with subUnits (like badminton), each court is independent
      if (hasSubUnits) {
        // If checking for a specific court, only include bookings for that exact court
        if (subUnit != null) {
          // Only include bookings that match this specific court
          if (data['subUnit'] != subUnit) {
            continue; // Different court - doesn't affect this court's availability
          }
        } else {
          // If no court specified but facility has subUnits, don't include any bookings
          // This ensures we require court selection first
          continue;
        }
      } else {
        // For facilities without subUnits, include all bookings
        // subUnit parameter is ignored for these facilities
      }
      
      // Extract booking time range
      final startTime = (data['startTime'] as Timestamp?)?.toDate();
      final endTime = (data['endTime'] as Timestamp?)?.toDate();
      
      if (startTime != null && endTime != null) {
        bookedSlots.add((
          start: startTime,
          end: endTime,
        ));
      }
    }

    return bookedSlots;
  }

  /// Check if date is a blackout date
  Future<bool> _isBlackoutDate(DateTime date) async {
    final dateOnly = DateTimeUtils.startOfDay(date);

    final snapshot = await _firestore
        .collection(AppConstants.blackoutDatesCollection)
        .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Get available sub-units (courts) for badminton on a specific slot
  Future<List<String>> getAvailableCourts({
    required String facilityId,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final facility = await getFacilityById(facilityId);
    if (facility == null || !facility.hasSubUnits) return [];

    final bookedCourts = <String>[];

    // Get bookings for this time slot
    // Simple query - filter status in code
    final snapshot = await _firestore
        .collection(AppConstants.bookingsCollection)
        .where('facilityId', isEqualTo: facilityId)
        .where('bookingDate',
            isEqualTo: Timestamp.fromDate(DateTimeUtils.startOfDay(date)))
        .get();
    
    final activeStatuses = [
      BookingStatus.confirmed.code,
      BookingStatus.pendingPayment.code,
    ];

    for (final doc in snapshot.docs) {
      final booking = BookingModel.fromFirestore(doc);
      // Filter by active status and time overlap
      if (!activeStatuses.contains(booking.status.code)) continue;
      
      if (booking.startTime.isBefore(endTime) &&
          booking.endTime.isAfter(startTime)) {
        if (booking.subUnit != null) {
          bookedCourts.add(booking.subUnit!);
        }
      }
    }

    // Return available courts
    return facility.subUnits
        .where((court) => !bookedCourts.contains(court))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOKINGS
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
    bool isSplitBill = false,
    List<SplitBillParticipant>? splitParticipants,
    BookingType? bookingType,
    TournamentFormat? tournamentFormat,
    bool requestReferee = false, // Optional referee for practice sessions
  }) async {
    try {
      // For facilities with subUnits (like badminton), subUnit is REQUIRED
      if (facility.hasSubUnits && (subUnit == null || subUnit.isEmpty)) {
        return BookingResult.failure(
            'Court selection is required for this facility. Please select a court.');
      }
      
      // For facilities without subUnits, ensure subUnit is null
      if (!facility.hasSubUnits && subUnit != null) {
        return BookingResult.failure('This facility does not have sub-units');
      }
      
      // Validate time slot
      if (DateTimeUtils.hasPassed(startTime)) {
        return BookingResult.failure('Cannot book slots in the past');
      }

      // Check Friday prayer block
      if (_isFridayPrayerTime(startTime) || _isFridayPrayerTime(endTime)) {
        return BookingResult.failure(
            'Booking not allowed during Friday prayer time (12:30 PM - 2:30 PM)');
      }

      // Check availability - this checks only the specific court for facilities with subUnits
      // Each court has independent availability
      final isAvailable = await _checkSlotAvailability(
        facilityId: facility.id,
        date: date,
        startTime: startTime,
        endTime: endTime,
        subUnit: subUnit,
      );

      if (!isAvailable) {
        return BookingResult.failure('Selected time slot is no longer available');
      }

      // Calculate fees
      final facilityFee = _calculateFacilityFee(facility, user.isStudent, startTime, endTime);
      
      // Calculate referee fee if requested (practice sessions use lower rate)
      double? refereeFee;
      if (requestReferee && user.isStudent) {
        final refereesRequired = _getRefereesRequired(facility.sport);
        refereeFee = refereesRequired * AppConstants.refereeEarningsPractice;
      }
      final totalAmount = facilityFee + (refereeFee ?? 0);

      // Generate booking ID
      final bookingId = _uuid.v4();
      
      // Generate team code if split bill is enabled
      final teamCode = isSplitBill ? QRUtils.generateTeamCode() : null;

      // Set payment deadline for split bill (24 hours before booking startTime)
      // Allows organizer to remove non-paying participants after deadline
      final splitBillPaymentDeadline = isSplitBill
          ? startTime.subtract(const Duration(hours: 24))
          : null;

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
        status: BookingStatus.pendingPayment,
        isSplitBill: isSplitBill,
        splitBillParticipants: splitParticipants ?? [],
        teamCode: teamCode,
        splitBillPaymentDeadline: splitBillPaymentDeadline,
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
        refereeJobId: '', // Will be updated after referee job creation if needed
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
      // See PaymentService._processNormalBookingPayment() and processSplitBillPayment()

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
          
          // Add organizer as first team if split bill is enabled
          if (isSplitBill) {
            await tournamentService.addTeamToTournament(
              bookingId: bookingId,
              teamId: user.uid,
              teamName: user.displayName,
            );
          }
        } catch (e) {
          // Log error but don't fail booking creation
          debugPrint('Warning: Failed to create tournament bracket: $e');
        }
      }

      return BookingResult.success(bookingWithQr);
    } catch (e) {
      return BookingResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'booking'),
      );
    }
  }

  /// Check slot availability
  Future<bool> _checkSlotAvailability({
    required String facilityId,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    String? subUnit,
  }) async {
    final bookedSlots = await _getBookedSlots(facilityId, date, subUnit);
    
    for (final booked in bookedSlots) {
      if (startTime.isBefore(booked.end) && endTime.isAfter(booked.start)) {
        return false;
      }
    }
    return true;
  }

  /// Check if time falls within Friday prayer block
  bool _isFridayPrayerTime(DateTime time) {
    if (time.weekday != DateTime.friday) return false;

    final timeInMinutes = time.hour * 60 + time.minute;
    const blockStart = AppConstants.fridayBlockStartHour * 60 +
        AppConstants.fridayBlockStartMinute;
    const blockEnd =
        AppConstants.fridayBlockEndHour * 60 + AppConstants.fridayBlockEndMinute;

    return timeInMinutes >= blockStart && timeInMinutes < blockEnd;
  }

  /// Calculate facility fee based on user type and duration
  double _calculateFacilityFee(
    FacilityModel facility,
    bool isStudent,
    DateTime startTime,
    DateTime endTime,
  ) {
    final price = facility.getPrice(isStudent);
    final durationHours = endTime.difference(startTime).inMinutes / 60;

    if (facility.type == FacilityType.session) {
      // Session-based: flat rate per session
      return price;
    } else {
      // Hourly: price × hours
      return price * durationHours;
    }
  }

  // Note: Referee job creation for normal bookings has been removed.
  // Referee jobs are now only created for tournament matches via TournamentService._createRefereeJobsForTournament()

  /// Get user's bookings
  /// Returns ALL bookings for the user regardless of user type (student/public/referee/admin)
  /// Unified system: All bookings are stored in the same collection
  Future<List<BookingModel>> getUserBookings(String userId, String userEmail, {int limit = 100}) async {
    try {
      // Query 1: Bookings where user is the organizer
      final organizerSnapshot = await _firestore
          .collection(AppConstants.bookingsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      // Query 2: Split bill bookings where user is a participant
      // Note: We need to fetch all split bill bookings and filter in code
      // because Firestore doesn't easily support querying nested arrays
      final allSplitBillSnapshot = await _firestore
          .collection(AppConstants.bookingsCollection)
          .where('isSplitBill', isEqualTo: true)
          .limit(limit * 2) // Fetch more to account for filtering
          .get();

      // Combine both queries
      final allBookingIds = <String>{};
      final allBookings = <BookingModel>[];

      // Add organizer bookings
      for (final doc in organizerSnapshot.docs) {
        final booking = BookingModel.fromFirestore(doc);
        allBookingIds.add(booking.id);
        allBookings.add(booking);
      }

      // Filter and add participant bookings
      for (final doc in allSplitBillSnapshot.docs) {
        if (allBookingIds.contains(doc.id)) {
          continue; // Already added as organizer booking
        }

        final booking = BookingModel.fromFirestore(doc);
        
        // Check if user is a participant
        final isParticipant = booking.splitBillParticipants.any(
          (p) => p.email.toLowerCase() == userEmail.toLowerCase(),
        );

        if (isParticipant) {
          allBookings.add(booking);
        }
      }

      // Sort by createdAt descending
      allBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply limit after combining both queries
      return allBookings.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching user bookings: $e');
      // Return empty list on error rather than crashing
      return [];
    }
  }

  /// Get upcoming bookings for user
  /// Includes bookings where user is organizer OR participant (split bill)
  /// Unified system: Works for ALL user types (student/public/referee/admin)
  Future<List<BookingModel>> getUpcomingBookings(String userId, String userEmail) async {
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
          .where((booking) =>
              booking.startTime.isAfter(now) &&
              activeStatuses.contains(booking.status.code))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      debugPrint('Error fetching upcoming bookings: $e');
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
      final doc = await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .get();

      if (!doc.exists) {
        return BookingResult.failure('Booking not found');
      }

      final booking = BookingModel.fromFirestore(doc);

      if (!booking.isActive) {
        return BookingResult.failure('Booking is already cancelled or completed');
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
          final jobDoc = await _firestore
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
                debugPrint('✅ Escrow refunded for booking ${booking.id}');
              } catch (e) {
                debugPrint('⚠️ Failed to refund escrow: $e');
                // Continue with job cancellation even if escrow refund fails
              }
            }

            // Notify assigned referees about job cancellation
            if (job.assignedReferees.isNotEmpty) {
              try {
                final notificationService = _notificationService ?? NotificationService();
                for (final referee in job.assignedReferees) {
                  await notificationService.createNotification(
                    userId: referee.userId,
                    type: NotificationType.refereeJobCancelled,
                    title: 'Referee Job Cancelled',
                    body: 'The ${job.sport.displayName} job at ${job.facilityName} has been cancelled',
                    relatedId: job.id,
                    route: '/referee',
                    data: {'bookingId': booking.id, 'reason': reason},
                  );
                }
              } catch (e) {
                debugPrint('⚠️ Failed to notify referees: $e');
                // Continue even if notification fails
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
          debugPrint('⚠️ Error handling referee job cancellation: $e');
          // Continue with booking cancellation even if referee job handling fails
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
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'booking', defaultMessage: 'Unable to cancel booking. Please try again.'),
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

      final doc = await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .get();

      return BookingResult.success(BookingModel.fromFirestore(doc));
    } catch (e) {
      return BookingResult.failure('Failed to confirm payment');
    }
  }

  /// Update booking status (general purpose)
  Future<bool> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .update({
        'status': status.code,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('❌ Failed to update booking status: $e');
      return false;
    }
  }

  /// Auto-complete bookings when endTime passes
  /// This method should be called periodically (e.g., via Cloud Functions or background task)
  /// Auto-completes confirmed bookings whose endTime has passed
  /// For split bill bookings: Auto-completes if endTime passed (even if not all paid)
  Future<int> autoCompletePastBookings() async {
    try {
      final now = DateTime.now();
      
      // Find all confirmed bookings where endTime has passed
      final pastBookingsSnapshot = await _firestore
          .collection(AppConstants.bookingsCollection)
          .where('status', isEqualTo: BookingStatus.confirmed.code)
          .where('endTime', isLessThan: Timestamp.fromDate(now))
          .limit(50) // Process in batches
          .get();

      int completedCount = 0;

      for (final doc in pastBookingsSnapshot.docs) {
        try {
          final booking = BookingModel.fromFirestore(doc);
          
          // Double-check: Only auto-complete if endTime has passed
          if (booking.endTime.isBefore(now) && booking.status == BookingStatus.confirmed) {
            // Update booking status to completed
            await _firestore
                .collection(AppConstants.bookingsCollection)
                .doc(booking.id)
                .update({
              'status': BookingStatus.completed.code,
              'updatedAt': Timestamp.now(),
            });

            // Auto-complete associated referee job if exists (releases escrow)
            if (booking.refereeJobId != null) {
              try {
                final refereeService = RefereeService();
                final jobResult = await refereeService.completeJob(
                  jobId: booking.refereeJobId!,
                  organizerUserId: booking.userId,
                  allowAutoComplete: true, // Allow auto-completion
                );
                if (jobResult.success) {
                  debugPrint('✅ Auto-completed referee job ${booking.refereeJobId} for booking ${booking.id}');
                } else {
                  debugPrint('⚠️ Failed to auto-complete referee job: ${jobResult.errorMessage}');
                }
              } catch (e) {
                debugPrint('⚠️ Error auto-completing referee job: $e');
                // Continue even if referee job completion fails
              }
            }

            completedCount++;
            debugPrint('✅ Auto-completed booking ${booking.id} (endTime: ${booking.endTime})');
          }
        } catch (e) {
          debugPrint('⚠️ Error processing booking ${doc.id} for auto-completion: $e');
          // Continue with next booking
        }
      }

      if (completedCount > 0) {
        debugPrint('✅ Auto-completed $completedCount booking(s)');
      }

      return completedCount;
    } catch (e) {
      debugPrint('❌ Error in autoCompletePastBookings: $e');
      return 0;
    }
  }

  /// Check-in for booking (used with QR code)
  Future<bool> checkInBooking(String bookingId) async {
    try {
      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .update({
        'isCheckedIn': true,
        'checkedInAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('❌ Failed to check-in booking: $e');
      return false;
    }
  }

  /// Complete booking (called after game ends)
  /// Note: Player merit points are ONLY awarded for tournament participation, NOT normal bookings
  Future<bool> completeBooking(String bookingId) async {
    try {
      // Check if booking exists
      final bookingDoc = await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        debugPrint('❌ Booking not found: $bookingId');
        return false;
      }

      // Update booking status
      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .update({
        'status': BookingStatus.completed.code,
        'completedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Note: Player merit points (+2) are ONLY awarded for tournament participation, NOT normal bookings
      // Tournament participants receive merit points when they join/participate in tournaments
      // Normal facility bookings do NOT award player merit points

      return true;
    } catch (e) {
      debugPrint('❌ Failed to complete booking: $e');
      return false;
    }
  }

  /// Get booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      debugPrint('🔍 Fetching booking with ID: $bookingId');
      final doc = await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .get();

      if (!doc.exists) {
        debugPrint('⚠️ Booking document does not exist: $bookingId');
        return null;
      }

      debugPrint('✅ Booking document found, parsing...');
      final booking = BookingModel.fromFirestore(doc);
      debugPrint('✅ Booking parsed successfully: ${booking.facilityName}');
      return booking;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to get booking: $e');
      debugPrint('Stack trace: $stackTrace');
      // Re-throw so FutureProvider.error() is triggered properly
      rethrow;
    }
  }

  /// Join a booking by team code (for split bill)
  Future<BookingResult> joinBookingByTeamCode({
    required String teamCode,
    required UserModel user,
  }) async {
    try {
      // Find booking by team code
      final snapshot = await _firestore
          .collection(AppConstants.bookingsCollection)
          .where('teamCode', isEqualTo: teamCode)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return BookingResult.failure('Invalid team code. Please check and try again.');
      }

      final doc = snapshot.docs.first;
      final booking = BookingModel.fromFirestore(doc);

      // Verify booking is split bill
      if (!booking.isSplitBill) {
        return BookingResult.failure('This booking does not support split bill');
      }

      // Check if booking is still active
      if (!booking.isActive) {
        return BookingResult.failure('This booking is no longer available');
      }

      // Check if user is already a participant
      final existingParticipant = booking.splitBillParticipants.firstWhere(
        (p) => p.email == user.email,
        orElse: () => const SplitBillParticipant(
          oderId: '',
          email: '',
          name: '',
          amount: 0,
        ),
      );

      if (existingParticipant.email == user.email) {
        // User already joined, return success with booking
        return BookingResult.success(booking);
      }

      // Get sport-specific max participants limit
      final facility = await getFacilityById(booking.facilityId);
      final maxParticipants = facility != null 
          ? AppConstants.getMaxSplitBillParticipants(facility.sport)
          : 10; // Fallback
      
      // Check if there's space for more participants
      if (booking.splitBillParticipants.length >= maxParticipants) {
        return BookingResult.failure(
          'This booking is full (max $maxParticipants participants for ${facility?.sport.displayName ?? "this sport"})',
        );
      }

      // Recalculate all participant shares to distribute evenly
      final totalParticipants = booking.splitBillParticipants.length + 1;
      final newShare = booking.totalAmount / totalParticipants;
      
      // Update existing participants with new share (create new instances)
      // NOTE: If someone already paid and shares are recalculated, their share amount
      // is updated but their payment status remains. Future enhancement could handle
      // refunds/adjustments for share changes after payment.
      final updatedParticipants = booking.splitBillParticipants.map((p) {
        return SplitBillParticipant(
          oderId: p.oderId,
          email: p.email,
          name: p.name,
          amount: newShare, // Updated share amount
          hasPaid: p.hasPaid, // Keep payment status
          paidAt: p.paidAt,
        );
      }).toList();

      // Add new participant
      final newParticipant = SplitBillParticipant(
        oderId: _uuid.v4(),
        email: user.email,
        name: user.displayName,
        amount: newShare,
        hasPaid: false,
      );
      updatedParticipants.add(newParticipant);

      // Update booking with new participant list
      await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(booking.id)
          .update({
        'splitBillParticipants': updatedParticipants.map((p) => p.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      // Return updated booking
      final updatedBooking = booking.copyWith(
        splitBillParticipants: updatedParticipants,
      );

      // Notify organizer that participant joined
      if (_notificationService != null) {
        await _notificationService.notifyParticipantJoined(
          organizerUserId: booking.userId,
          bookingId: booking.id,
          participantName: user.displayName,
          facilityName: booking.facilityName,
          totalParticipants: updatedParticipants.length,
        );
      }

      return BookingResult.success(updatedBooking);
    } catch (e) {
      debugPrint('❌ Failed to join booking: $e');
      return BookingResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'booking', defaultMessage: 'Unable to join booking. Please try again.'),
      );
    }
  }

  /// Remove participant from split bill booking (organizer only)
  /// Allows organizer to remove non-paying participants
  Future<BookingResult> removeParticipantFromSplitBill({
    required String bookingId,
    required String organizerUserId,
    required String participantEmail,
  }) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .get();

      if (!doc.exists) {
        return BookingResult.failure('Booking not found');
      }

      final booking = BookingModel.fromFirestore(doc);

      if (!booking.isSplitBill) {
        return BookingResult.failure('This booking does not use split bill');
      }

      // Verify user is the organizer
      if (booking.userId != organizerUserId) {
        return BookingResult.failure('Only the organizer can remove participants');
      }

      // Check if booking is still active
      if (!booking.isActive) {
        return BookingResult.failure('This booking is no longer active');
      }

      // Find participant
      final participantIndex = booking.splitBillParticipants.indexWhere(
        (p) => p.email.toLowerCase() == participantEmail.toLowerCase(),
      );

      if (participantIndex == -1) {
        return BookingResult.failure('Participant not found in this booking');
      }

      final participant = booking.splitBillParticipants[participantIndex];

      // Only allow removing participants who haven't paid
      if (participant.hasPaid) {
        return BookingResult.failure(
          'Cannot remove participant who has already paid. '
          'Please refund them first if needed.',
        );
      }

      // Prevent removing organizer (organizer is always a participant)
      if (booking.userEmail.toLowerCase() == participantEmail.toLowerCase()) {
        return BookingResult.failure('Cannot remove organizer from booking');
      }

      // Remove participant
      final updatedParticipants = List<SplitBillParticipant>.from(
        booking.splitBillParticipants,
      );
      updatedParticipants.removeAt(participantIndex);

      // Recalculate shares for remaining participants
      if (updatedParticipants.isNotEmpty) {
        final newShare = booking.totalAmount / updatedParticipants.length;
        final recalculatedParticipants = updatedParticipants.map((p) {
          return SplitBillParticipant(
            oderId: p.oderId,
            email: p.email,
            name: p.name,
            amount: newShare,
            hasPaid: p.hasPaid, // Keep payment status
            paidAt: p.paidAt,
          );
        }).toList();

        // Update booking
        await _firestore
            .collection(AppConstants.bookingsCollection)
            .doc(bookingId)
            .update({
          'splitBillParticipants': recalculatedParticipants.map((p) => p.toMap()).toList(),
          'updatedAt': Timestamp.now(),
        });

        final updatedBooking = booking.copyWith(
          splitBillParticipants: recalculatedParticipants,
        );

        // Notify removed participant if notification service is available
        if (_notificationService != null) {
          try {
            // Find user by email to get userId
            final userSnapshot = await _firestore
                .collection(AppConstants.usersCollection)
                .where('email', isEqualTo: participantEmail)
                .limit(1)
                .get();

            if (userSnapshot.docs.isNotEmpty) {
              final userId = userSnapshot.docs.first.id;
              await _notificationService.createNotification(
                userId: userId,
                type: NotificationType.bookingCancelled, // Use bookingCancelled as closest match
                title: 'Removed from Split Bill',
                body: 'You have been removed from the split bill booking for ${booking.facilityName}',
                relatedId: booking.id,
                route: '/bookings',
                data: {'bookingId': booking.id},
              );
            }
          } catch (e) {
            debugPrint('⚠️ Failed to notify removed participant: $e');
            // Continue even if notification fails
          }
        }

        return BookingResult.success(updatedBooking);
      } else {
        // No participants left - this shouldn't happen (organizer is always a participant)
        return BookingResult.failure('Cannot remove last participant');
      }
    } catch (e) {
      debugPrint('❌ Failed to remove participant: $e');
      return BookingResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'booking', defaultMessage: 'Unable to remove participant. Please try again.'),
      );
    }
  }

  /// Remove participant from split bill booking (leave booking)
  /// Only participants who haven't paid can leave
  Future<BookingResult> leaveSplitBillBooking({
    required String bookingId,
    required UserModel user,
  }) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId)
          .get();

      if (!doc.exists) {
        return BookingResult.failure('Booking not found');
      }

      final booking = BookingModel.fromFirestore(doc);

      if (!booking.isSplitBill) {
        return BookingResult.failure('This booking does not use split bill');
      }

      // Check if booking is still active
      if (!booking.isActive) {
        return BookingResult.failure('This booking is no longer active');
      }

      // Find participant
      final participantIndex = booking.splitBillParticipants.indexWhere(
        (p) => p.email.toLowerCase() == user.email.toLowerCase(),
      );

      if (participantIndex == -1) {
        return BookingResult.failure('You are not a participant in this booking');
      }

      final participant = booking.splitBillParticipants[participantIndex];

      // Prevent organizer from leaving (they can cancel the booking instead)
      if (booking.userId == user.uid) {
        return BookingResult.failure('Organizer cannot leave. Please cancel the booking if needed.');
      }

      // Prevent participants who already paid from leaving (they'd lose their money)
      if (participant.hasPaid) {
        return BookingResult.failure(
          'Cannot leave: You have already paid your share (RM ${participant.amount.toStringAsFixed(2)}). '
          'Please contact the organizer to cancel the booking for a refund.',
        );
      }

      // Remove participant
      final updatedParticipants = List<SplitBillParticipant>.from(
        booking.splitBillParticipants,
      );
      updatedParticipants.removeAt(participantIndex);

      // Recalculate shares for remaining participants
      if (updatedParticipants.isNotEmpty) {
        final newShare = booking.totalAmount / updatedParticipants.length;
        final recalculatedParticipants = updatedParticipants.map((p) {
          return SplitBillParticipant(
            oderId: p.oderId,
            email: p.email,
            name: p.name,
            amount: newShare,
            hasPaid: p.hasPaid, // Keep payment status
            paidAt: p.paidAt,
          );
        }).toList();

        // Update booking
        await _firestore
            .collection(AppConstants.bookingsCollection)
            .doc(bookingId)
            .update({
          'splitBillParticipants': recalculatedParticipants.map((p) => p.toMap()).toList(),
          'updatedAt': Timestamp.now(),
        });

        final updatedBooking = booking.copyWith(
          splitBillParticipants: recalculatedParticipants,
        );

        return BookingResult.success(updatedBooking);
      } else {
        // No participants left - this shouldn't happen (organizer is always a participant)
        return BookingResult.failure('Cannot remove last participant');
      }
    } catch (e) {
      debugPrint('❌ Failed to leave booking: $e');
      return BookingResult.failure(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'booking', defaultMessage: 'Unable to leave booking. Please try again.'),
      );
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

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN STATS (Firebase-driven)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get revenue statistics from Firebase
  Future<AdminRevenueStats> getRevenueStats() async {
    try {
      // Read from admin revenue document (single source of truth)
      final adminRevenueDoc = await _firestore
          .collection(AppConstants.adminRevenueCollection)
          .doc('total_revenue')
          .get();
      
      if (adminRevenueDoc.exists) {
        final data = adminRevenueDoc.data()!;
        
        // Get referee job count for stats
        final jobsSnapshot = await _firestore
            .collection(AppConstants.jobsCollection)
            .get();
        
        return AdminRevenueStats(
          totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
          facilityRevenue: (data['facilityRevenue'] as num?)?.toDouble() ?? 0.0,
          refereePayouts: 0.0, // Referee payouts are tracked separately in escrow
          totalBookings: (data['transactionCount'] as int?) ?? 0,
          refereeJobs: jobsSnapshot.docs.length,
        );
      }
      
      // Fallback: Calculate from bookings if admin revenue doc doesn't exist yet
      final bookingsSnapshot = await _firestore
          .collection(AppConstants.bookingsCollection)
          .where('status', isEqualTo: BookingStatus.completed.code)
          .get();

      double facilityRevenue = 0;
      double refereePayouts = 0;
      final int totalBookings = bookingsSnapshot.docs.length;

      for (final doc in bookingsSnapshot.docs) {
        final booking = BookingModel.fromFirestore(doc);
        facilityRevenue += booking.facilityFee;
        if (booking.refereeFee != null) {
          refereePayouts += booking.refereeFee!;
        }
      }

      // Get referee job count
      final jobsSnapshot = await _firestore
          .collection(AppConstants.jobsCollection)
          .where('status', isEqualTo: JobStatus.paid.code)
          .get();

      return AdminRevenueStats(
        totalRevenue: facilityRevenue + refereePayouts,
        facilityRevenue: facilityRevenue,
        refereePayouts: refereePayouts,
        totalBookings: totalBookings,
        refereeJobs: jobsSnapshot.docs.length,
      );
    } catch (e) {
      debugPrint('❌ Failed to get revenue stats: $e');
      return const AdminRevenueStats();
    }
  }

  /// Get booking counts by status from Firebase
  Future<AdminBookingCounts> getBookingCounts() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.bookingsCollection)
          .get();

      int pending = 0;
      int confirmed = 0;
      int completed = 0;
      int cancelled = 0;

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String?;
        switch (status) {
          case 'PENDING_PAYMENT':
            pending++;
            break;
          case 'CONFIRMED':
            confirmed++;
            break;
          case 'COMPLETED':
            completed++;
            break;
          case 'CANCELLED':
            cancelled++;
            break;
        }
      }

      return AdminBookingCounts(
        pending: pending,
        confirmed: confirmed,
        completed: completed,
        cancelled: cancelled,
      );
    } catch (e) {
      debugPrint('❌ Failed to get booking counts: $e');
      return const AdminBookingCounts();
    }
  }

  /// Get today's activity statistics for admin dashboard
  Future<AdminTodayActivity> getTodayActivity() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get bookings created today
      final bookingsSnapshot = await _firestore
          .collection(AppConstants.bookingsCollection)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('createdAt', isLessThan: Timestamp.fromDate(todayEnd))
          .get();

      final int bookingsToday = bookingsSnapshot.docs.length;
      double revenueToday = 0.0;

      // Calculate revenue from completed bookings today
      final completedBookingsToday = bookingsSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'COMPLETED';
      }).toList();

      for (final doc in completedBookingsToday) {
        final booking = BookingModel.fromFirestore(doc);
        revenueToday += booking.facilityFee;
        if (booking.refereeFee != null) {
          revenueToday += booking.refereeFee!;
        }
      }

      // Get new users today
      final usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('createdAt', isLessThan: Timestamp.fromDate(todayEnd))
          .get();

      final newUsersToday = usersSnapshot.docs.length;

      // Get tournaments created today
      final tournamentsSnapshot = await _firestore
          .collection(AppConstants.tournamentsCollection)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('createdAt', isLessThan: Timestamp.fromDate(todayEnd))
          .get();

      final tournamentsCreatedToday = tournamentsSnapshot.docs.length;

      // Get referee jobs completed today
      final jobsSnapshot = await _firestore
          .collection(AppConstants.jobsCollection)
          .where('status', isEqualTo: 'PAID')
          .get();

      int refereeJobsCompletedToday = 0;
      for (final doc in jobsSnapshot.docs) {
        final data = doc.data();
        final completedAt = (data['completedAt'] as Timestamp?)?.toDate();
        if (completedAt != null &&
            completedAt.isAfter(todayStart) &&
            completedAt.isBefore(todayEnd)) {
          refereeJobsCompletedToday++;
        }
      }

      return AdminTodayActivity(
        bookingsToday: bookingsToday,
        revenueToday: revenueToday,
        newUsersToday: newUsersToday,
        tournamentsCreatedToday: tournamentsCreatedToday,
        refereeJobsCompletedToday: refereeJobsCompletedToday,
      );
    } catch (e) {
      debugPrint('❌ Failed to get today activity: $e');
      return const AdminTodayActivity();
    }
  }

  /// Get all bookings (admin only)
  Future<List<BookingModel>> getAllBookings() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.bookingsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Failed to get all bookings: $e');
      return [];
    }
  }

  /// Stream of all bookings (admin only)
  Stream<List<BookingModel>> getAllBookingsStream() {
    return _firestore
        .collection(AppConstants.bookingsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // REFEREE JOB MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Get referees required based on sport type
  int _getRefereesRequired(SportType sport) {
    switch (sport) {
      case SportType.football:
        return 3; // 1 main referee + 2 linesmen
      case SportType.futsal:
        return 1; // Solo referee
      case SportType.badminton:
        return 1; // Umpire
      case SportType.tennis:
        return 1; // Chair umpire (optional)
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
      debugPrint('⚠️ Cannot create referee job for non-confirmed booking');
      return null;
    }

    // Check if referee job already exists (prevent duplicates)
    if (booking.refereeJobId != null && booking.refereeJobId!.isNotEmpty) {
      // Verify the job actually exists in Firestore
      try {
        final existingJobDoc = await _firestore
            .collection(AppConstants.jobsCollection)
            .doc(booking.refereeJobId)
            .get();
        
        if (existingJobDoc.exists) {
          debugPrint('✅ Referee job already exists for booking: ${booking.id} (job: ${booking.refereeJobId})');
          return booking.refereeJobId;
        }
      } catch (e) {
        debugPrint('⚠️ Error checking existing referee job: $e');
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
      final refereesRequired = _getRefereesRequired(sport);
      
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
      
      debugPrint('✅ Created referee job for booking: $jobId');
      return jobId;
    } catch (e) {
      debugPrint('❌ Failed to create referee job: $e');
      return null;
    }
  }
}

/// Admin revenue stats model
class AdminRevenueStats {
  final double totalRevenue;
  final double facilityRevenue;
  final double refereePayouts;
  final int totalBookings;
  final int refereeJobs;

  const AdminRevenueStats({
    this.totalRevenue = 0,
    this.facilityRevenue = 0,
    this.refereePayouts = 0,
    this.totalBookings = 0,
    this.refereeJobs = 0,
  });
}

/// Admin booking counts model
class AdminBookingCounts {
  final int pending;
  final int confirmed;
  final int completed;
  final int cancelled;

  const AdminBookingCounts({
    this.pending = 0,
    this.confirmed = 0,
    this.completed = 0,
    this.cancelled = 0,
  });

  int get total => pending + confirmed + completed + cancelled;
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

/// Admin today's activity statistics model
class AdminTodayActivity {
  final int bookingsToday;
  final double revenueToday;
  final int newUsersToday;
  final int tournamentsCreatedToday;
  final int refereeJobsCompletedToday;

  const AdminTodayActivity({
    this.bookingsToday = 0,
    this.revenueToday = 0.0,
    this.newUsersToday = 0,
    this.tournamentsCreatedToday = 0,
    this.refereeJobsCompletedToday = 0,
  });
}
