import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/facility_service.dart';
import '../services/booking_operations_service.dart';
import '../services/weather_service.dart';
import '../services/referee_service.dart';
import '../services/merit_service.dart';
import '../services/payment_service.dart';
import '../services/tournament_service.dart';
import '../services/chatbot_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';
import '../core/config/api_keys.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SERVICE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Analytics service provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Booking service provider
final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(
    notificationService: ref.watch(notificationServiceProvider),
    facilityService: ref.watch(facilityServiceProvider),
  );
});

/// Facility service provider
final facilityServiceProvider = Provider<FacilityService>((ref) {
  return FacilityService();
});

/// Booking operations service provider
final bookingOperationsServiceProvider = Provider<BookingOperationsService>((
  ref,
) {
  return BookingOperationsService();
});

/// Weather service provider
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(apiKey: ApiKeys.openWeatherMap);
});

/// Referee service provider
final refereeServiceProvider = Provider<RefereeService>((ref) {
  return RefereeService();
});

/// Merit service provider
final meritServiceProvider = Provider<MeritService>((ref) {
  return MeritService();
});

/// Payment service provider
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(
    notificationService: ref.watch(notificationServiceProvider),
  );
});

/// Tournament service provider
final tournamentServiceProvider = Provider<TournamentService>((ref) {
  return TournamentService();
});

/// Chatbot service provider (AI assistant)
final chatbotServiceProvider = Provider<ChatbotService>((ref) {
  return ChatbotService(apiKey: ApiKeys.gemini);
});

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
