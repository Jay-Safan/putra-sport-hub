import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_time_utils.dart';
import '../features/booking/data/models/facility_model.dart';
import '../features/booking/data/models/booking_model.dart';

/// Facility service for facility queries and availability checks
class FacilityService {
  final FirebaseFirestore _firestore;

  FacilityService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // FACILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all active facilities
  Future<List<FacilityModel>> getFacilities() async {
    final snapshot =
        await _firestore
            .collection(AppConstants.facilitiesCollection)
            .where('isActive', isEqualTo: true)
            .get();

    return snapshot.docs
        .map((doc) => FacilityModel.fromFirestore(doc))
        .toList();
  }

  /// Get facilities by sport type
  Future<List<FacilityModel>> getFacilitiesBySport(SportType sport) async {
    final snapshot =
        await _firestore
            .collection(AppConstants.facilitiesCollection)
            .where('sport', isEqualTo: sport.code)
            .where('isActive', isEqualTo: true)
            .get();

    return snapshot.docs
        .map((doc) => FacilityModel.fromFirestore(doc))
        .toList();
  }

  /// Get single facility by ID
  Future<FacilityModel?> getFacilityById(String facilityId) async {
    final doc =
        await _firestore
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

    // Check Friday prayer block
    slots =
        slots.where((slot) {
          return !_isFridayPrayerTime(slot.startTime) &&
              !_isFridayPrayerTime(slot.endTime);
        }).toList();

    // Check blackout dates
    if (await _isBlackoutDate(date)) {
      return [];
    }

    // Get booked slots
    final bookedSlots = await _getBookedSlots(facilityId, date, subUnit);

    // Debug logging
    debugPrint(
      '📊 Facility: $facilityId, Date: ${date.toString().split(' ')[0]}, SubUnit: $subUnit',
    );
    debugPrint('   Total slots generated: ${slots.length}');
    debugPrint('   Booked time ranges: ${bookedSlots.length}');
    if (bookedSlots.isNotEmpty) {
      for (final booked in bookedSlots) {
        debugPrint(
          '   🔴 Booked: ${booked.start.toString().split(' ')[1]} - ${booked.end.toString().split(' ')[1]}',
        );
      }
    }

    // Mark slots as available or booked (return ALL slots with status)
    final slotsWithAvailability =
        slots.map((slot) {
          bool isAvailable = true;

          for (final booked in bookedSlots) {
            if (slot.startTime.isBefore(booked.end) &&
                slot.endTime.isAfter(booked.start)) {
              isAvailable = false;
              debugPrint('   ❌ Slot ${slot.label} marked as BOOKED');
              break;
            }
          }

          // Return slot with correct availability status
          return slot.copyWith(isAvailable: isAvailable);
        }).toList();

    final bookedCount =
        slotsWithAvailability.where((s) => !s.isAvailable).length;
    debugPrint(
      '   ✅ Available slots: ${slotsWithAvailability.length - bookedCount}',
    );
    debugPrint('   ❌ Booked slots: $bookedCount');

    return slotsWithAvailability;
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
    // Simple query - filter status in code
    final snapshot =
        await _firestore
            .collection(AppConstants.bookingsCollection)
            .where('facilityId', isEqualTo: facilityId)
            .where(
              'bookingDate',
              isEqualTo: Timestamp.fromDate(DateTimeUtils.startOfDay(date)),
            )
            .get();

    final activeStatuses = [
      BookingStatus.confirmed.code,
      BookingStatus.pendingPayment.code,
    ];

    final bookedSlots = <({DateTime start, DateTime end})>[];

    for (final doc in snapshot.docs) {
      final booking = BookingModel.fromFirestore(doc);

      // Filter by active status
      if (!activeStatuses.contains(booking.status.code)) continue;

      // For facilities with subUnits (like badminton courts):
      // ONLY include bookings for the SAME court (subUnit)
      // This ensures Court 1 bookings don't affect Court 2 availability
      if (subUnit != null && booking.subUnit != subUnit) {
        continue; // Skip bookings for different courts
      }

      bookedSlots.add((start: booking.startTime, end: booking.endTime));
    }

    return bookedSlots;
  }

  /// Check if date is a blackout date
  Future<bool> _isBlackoutDate(DateTime date) async {
    final dateOnly = DateTimeUtils.startOfDay(date);

    final snapshot =
        await _firestore
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
    final snapshot =
        await _firestore
            .collection(AppConstants.bookingsCollection)
            .where('facilityId', isEqualTo: facilityId)
            .where(
              'bookingDate',
              isEqualTo: Timestamp.fromDate(DateTimeUtils.startOfDay(date)),
            )
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

  /// Check slot availability
  Future<bool> checkSlotAvailability({
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
    const blockStart =
        AppConstants.fridayBlockStartHour * 60 +
        AppConstants.fridayBlockStartMinute;
    const blockEnd =
        AppConstants.fridayBlockEndHour * 60 +
        AppConstants.fridayBlockEndMinute;

    return timeInMinutes >= blockStart && timeInMinutes < blockEnd;
  }

  /// Calculate facility fee based on user type and duration
  double calculateFacilityFee(
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

  /// Get referees required based on sport type
  int getRefereesRequired(SportType sport) {
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
}
