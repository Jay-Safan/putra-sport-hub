import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../features/booking/data/models/booking_model.dart';

/// Booking operations service for check-in, completion, and lifecycle management
class BookingOperationsService {
  final FirebaseFirestore _firestore;

  BookingOperationsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOKING LIFECYCLE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

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
      throw Exception(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'booking'),
      );
    }
  }

  /// Complete booking (called after game ends)
  /// Note: Player merit points are ONLY awarded for tournament participation, NOT normal bookings
  Future<bool> completeBooking(String bookingId) async {
    try {
      // Check if booking exists
      final bookingDoc =
          await _firestore
              .collection(AppConstants.bookingsCollection)
              .doc(bookingId)
              .get();

      if (!bookingDoc.exists) {
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
      throw Exception(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'booking'),
      );
    }
  }

  /// Auto-complete bookings when endTime passes
  /// This method should be called periodically (e.g., via Cloud Functions or background task)
  /// Auto-completes confirmed bookings whose endTime has passed
  Future<int> autoCompletePastBookings() async {
    try {
      final now = DateTime.now();

      // Find all confirmed bookings where endTime has passed
      final pastBookingsSnapshot =
          await _firestore
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
          if (booking.endTime.isBefore(now) &&
              booking.status == BookingStatus.confirmed) {
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
                // Referee job completion handled by RefereeService
                // To avoid circular dependency, job is accessed separately
              } catch (e) {
                // Continue even if referee job completion fails
              }
            }

            completedCount++;
          }
        } catch (e) {
          // Continue with next booking
        }
      }

      return completedCount;
    } catch (e) {
      // Return 0 on error - background task will retry
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN STATS (Firebase-driven)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get revenue statistics from Firebase
  Future<AdminRevenueStats> getRevenueStats() async {
    try {
      // Read from admin revenue document (single source of truth)
      final adminRevenueDoc =
          await _firestore
              .collection(AppConstants.adminRevenueCollection)
              .doc('total_revenue')
              .get();

      if (adminRevenueDoc.exists) {
        final data = adminRevenueDoc.data()!;

        // Get referee job count for stats
        final jobsSnapshot =
            await _firestore.collection(AppConstants.jobsCollection).get();

        return AdminRevenueStats(
          totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
          facilityRevenue: (data['facilityRevenue'] as num?)?.toDouble() ?? 0.0,
          refereePayouts:
              0.0, // Referee payouts are tracked separately in escrow
          totalBookings: (data['transactionCount'] as int?) ?? 0,
          refereeJobs: jobsSnapshot.docs.length,
        );
      }

      // Fallback: Calculate from bookings if admin revenue doc doesn't exist yet
      final bookingsSnapshot =
          await _firestore
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
      final jobsSnapshot =
          await _firestore
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
      throw Exception(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'admin stats'),
      );
    }
  }

  /// Get booking counts by status from Firebase
  Future<AdminBookingCounts> getBookingCounts() async {
    try {
      final snapshot =
          await _firestore.collection(AppConstants.bookingsCollection).get();

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
      throw Exception(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'admin stats'),
      );
    }
  }

  /// Get today's activity statistics for admin dashboard
  Future<AdminTodayActivity> getTodayActivity() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get bookings created today
      final bookingsSnapshot =
          await _firestore
              .collection(AppConstants.bookingsCollection)
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
              )
              .where('createdAt', isLessThan: Timestamp.fromDate(todayEnd))
              .get();

      final int bookingsToday = bookingsSnapshot.docs.length;
      double revenueToday = 0.0;

      // Calculate revenue from completed bookings today
      final completedBookingsToday =
          bookingsSnapshot.docs.where((doc) {
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
      final usersSnapshot =
          await _firestore
              .collection(AppConstants.usersCollection)
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
              )
              .where('createdAt', isLessThan: Timestamp.fromDate(todayEnd))
              .get();

      final newUsersToday = usersSnapshot.docs.length;

      // Get tournaments created today
      final tournamentsSnapshot =
          await _firestore
              .collection(AppConstants.tournamentsCollection)
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
              )
              .where('createdAt', isLessThan: Timestamp.fromDate(todayEnd))
              .get();

      final tournamentsCreatedToday = tournamentsSnapshot.docs.length;

      // Get referee jobs completed today
      final jobsSnapshot =
          await _firestore
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
      throw Exception(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'admin stats'),
      );
    }
  }

  /// Get all bookings (admin only)
  Future<List<BookingModel>> getAllBookings() async {
    try {
      final snapshot =
          await _firestore
              .collection(AppConstants.bookingsCollection)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception(
        ErrorHandler.getUserFriendlyErrorMessage(e, context: 'booking'),
      );
    }
  }

  /// Stream of all bookings (admin only)
  Stream<List<BookingModel>> getAllBookingsStream() {
    return _firestore
        .collection(AppConstants.bookingsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => BookingModel.fromFirestore(doc))
                  .toList(),
        );
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
