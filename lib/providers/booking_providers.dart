import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/weather_service.dart';
import '../features/booking/data/models/facility_model.dart';
import '../features/booking/data/models/booking_model.dart';
import '../core/utils/date_time_utils.dart' show TimeSlot;
import '../core/utils/date_time_utils.dart' as dt;
import '../core/constants/app_constants.dart';
import 'service_providers.dart';
import 'auth_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// FACILITY PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// All facilities provider
final facilitiesProvider = FutureProvider<List<FacilityModel>>((ref) {
  return ref.watch(bookingServiceProvider).getFacilities();
});

/// Facilities by sport provider
final facilitiesBySportProvider =
    FutureProvider.family<List<FacilityModel>, SportType>((ref, sport) {
      return ref.watch(bookingServiceProvider).getFacilitiesBySport(sport);
    });

/// Single facility provider
final facilityProvider = FutureProvider.family<FacilityModel?, String>((
  ref,
  facilityId,
) {
  return ref.watch(bookingServiceProvider).getFacilityById(facilityId);
});

/// Available time slots provider (checks for existing bookings)
/// Uses a simple key string to combine parameters
final availableSlotsProvider = FutureProvider.family<List<dt.TimeSlot>, String>(
  (ref, key) {
    // Parse key: "facilityId|date|subUnit"
    final parts = key.split('|');
    final facilityId = parts[0];
    final date = DateTime.parse(parts[1]);
    final subUnit = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;

    return ref
        .watch(bookingServiceProvider)
        .getAvailableSlots(
          facilityId: facilityId,
          date: date,
          subUnit: subUnit,
        );
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// BOOKING PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// User's bookings provider
/// Unified system: Returns ALL bookings for the current user regardless of type (student/public/referee/admin)
/// All bookings are stored in the same Firestore collection
final userBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];

  // Query bookings where user is organizer
  return ref
      .watch(bookingServiceProvider)
      .getUserBookings(user.uid, user.email);
});

/// Upcoming bookings provider
final upcomingBookingsProvider = FutureProvider<List<BookingModel>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  return ref
      .watch(bookingServiceProvider)
      .getUpcomingBookings(user.uid, user.email);
});

/// Single booking by ID provider (Future for reliable initial load)
/// Note: Changed from StreamProvider to FutureProvider for better reliability
/// on initial page load, especially right after booking creation
final bookingByIdProvider = FutureProvider.family<BookingModel?, String>((
  ref,
  bookingId,
) {
  return ref.watch(bookingServiceProvider).getBookingById(bookingId);
});

/// Selected date for booking
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Selected facility for booking
final selectedFacilityProvider = StateProvider<FacilityModel?>((ref) {
  return null;
});

/// Selected time slot for booking
final selectedTimeSlotProvider = StateProvider<TimeSlot?>((ref) {
  return null;
});

/// Selected court (for badminton)
final selectedCourtProvider = StateProvider<String?>((ref) {
  return null;
});

// ═══════════════════════════════════════════════════════════════════════════
// WEATHER PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Weather check for selected date
final weatherCheckProvider = FutureProvider.family<WeatherResult, DateTime>((
  ref,
  date,
) {
  return ref.watch(weatherServiceProvider).checkWeatherForDate(date);
});

/// Current weather provider
final currentWeatherProvider = FutureProvider<WeatherResult>((ref) {
  return ref.watch(weatherServiceProvider).getCurrentWeather();
});
