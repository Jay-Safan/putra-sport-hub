import 'package:firebase_analytics/firebase_analytics.dart';

/// Analytics service for tracking user behavior and app performance
///
/// This service provides a centralized way to log events to Firebase Analytics
/// throughout the app. All analytics tracking should go through this service.
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService() : _analytics = FirebaseAnalytics.instance;

  /// Get the analytics instance (for advanced usage)
  FirebaseAnalytics get analytics => _analytics;

  // ═══════════════════════════════════════════════════════════════════════════
  // USER EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track user login
  Future<void> logLogin({String? loginMethod}) async {
    try {
      await _analytics.logLogin(loginMethod: loginMethod ?? 'email');
    } catch (e) {
      // Non-critical: Analytics logging failure shouldn't block user flow
    }
  }

  /// Track user signup
  Future<void> logSignUp({String? signUpMethod}) async {
    try {
      await _analytics.logSignUp(signUpMethod: signUpMethod ?? 'email');
    } catch (e) {
      // Non-critical: Analytics logging failure shouldn't block user flow
    }
  }

  /// Set user properties (role, student status, etc.)
  Future<void> setUserProperties({
    String? userRole,
    bool? isStudent,
    bool? isReferee,
  }) async {
    try {
      await _analytics.setUserProperty(name: 'user_role', value: userRole);
      if (isStudent != null) {
        await _analytics.setUserProperty(
          name: 'is_student',
          value: isStudent.toString(),
        );
      }
      if (isReferee != null) {
        await _analytics.setUserProperty(
          name: 'is_referee',
          value: isReferee.toString(),
        );
      }
    } catch (e) {
      // Non-critical: Analytics property setting failure shouldn't block user flow
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOKING EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track facility booking creation
  Future<void> logBookingCreated({
    required String facilityId,
    required String facilityName,
    required String sport,
    required double amount,
    bool isStudent = false,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'booking_created',
        parameters: {
          'facility_id': facilityId,
          'facility_name': facilityName,
          'sport': sport,
          'amount': amount,
          'is_student': isStudent,
        },
      );
    } catch (e) {
      // Non-critical: Analytics logging failure shouldn't block user flow
    }
  }

  /// Track booking cancellation
  Future<void> logBookingCancelled({
    required String bookingId,
    required String reason,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'booking_cancelled',
        parameters: {'booking_id': bookingId, 'reason': reason},
      );
    } catch (e) {
      // Non-critical: Analytics logging failure shouldn't block user flow
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOURNAMENT EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track tournament creation
  Future<void> logTournamentCreated({
    required String tournamentId,
    required String sport,
    required String format,
    required double entryFee,
    required int maxTeams,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'tournament_created',
        parameters: {
          'tournament_id': tournamentId,
          'sport': sport,
          'format': format,
          'entry_fee': entryFee,
          'max_teams': maxTeams,
        },
      );
    } catch (e) {
      // Non-critical: Analytics logging failure shouldn't block user flow
    }
  }

  /// Track tournament registration (join)
  Future<void> logTournamentJoined({
    required String tournamentId,
    required String teamName,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'tournament_joined',
        parameters: {'tournament_id': tournamentId, 'team_name': teamName},
      );
    } catch (e) {
      // Non-critical: Analytics logging failure shouldn't block user flow
    }
  }

  /// Track tournament cancellation
  Future<void> logTournamentCancelled({
    required String tournamentId,
    required int currentTeams,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'tournament_cancelled',
        parameters: {
          'tournament_id': tournamentId,
          'current_teams': currentTeams,
        },
      );
    } catch (e) {
      // Non-critical: Analytics logging failure shouldn't block user flow
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAYMENT EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track wallet top-up
  Future<void> logTopUp({
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'top_up',
        parameters: {
          'amount': amount,
          'payment_method': paymentMethod,
          'currency': 'MYR',
        },
      );
      // Also log as purchase event for revenue tracking
      await _analytics.logPurchase(
        currency: 'MYR',
        value: amount,
        parameters: {'payment_method': paymentMethod, 'type': 'top_up'},
      );
    } catch (e) {
      // Non-critical: Analytics logging failure shouldn't block user flow
    }
  }

  /// Track payment for booking
  Future<void> logBookingPayment({
    required String bookingId,
    required double amount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'booking_payment',
        parameters: {
          'booking_id': bookingId,
          'amount': amount,
          'currency': 'MYR',
        },
      );
    } catch (e) {
      // Non-critical: Analytics logging failure shouldn't block user flow
    }
  }

  /// Track tournament entry fee payment
  Future<void> logTournamentPayment({
    required String tournamentId,
    required double amount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'tournament_payment',
        parameters: {
          'tournament_id': tournamentId,
          'amount': amount,
          'currency': 'MYR',
        },
      );
    } catch (e) {
      // Non-critical: Analytics logging failure shouldn't block user flow
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REFEREE EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track referee job application
  Future<void> logRefereeJobApplied({
    required String jobId,
    required String sport,
    required double earnings,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'referee_job_applied',
        parameters: {'job_id': jobId, 'sport': sport, 'earnings': earnings},
      );
    } catch (e) {
      // Non-critical: Analytics logging failure shouldn't block user flow
    }
  }

  /// Track referee job completion
  Future<void> logRefereeJobCompleted({
    required String jobId,
    required double earnings,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'referee_job_completed',
        parameters: {'job_id': jobId, 'earnings': earnings},
      );
    } catch (e) {
      // Non-critical: Analytics logging failure shouldn't block user flow
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION & SCREEN EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track screen view (handled automatically by GoRouter)
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      // Non-critical: Analytics logging failure shouldn't block user flow
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI CHATBOT EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track chatbot message sent
  Future<void> logChatbotMessage({
    required String messageType,
    int? messageLength,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'chatbot_message',
        parameters: {
          'message_type': messageType,
          if (messageLength != null) 'message_length': messageLength,
        },
      );
    } catch (e) {
      // Non-critical: Analytics logging failure shouldn't block user flow
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR TRACKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track app errors and exceptions
  Future<void> logError({
    required String errorMessage,
    String? errorCode,
    String? context,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_message': errorMessage,
          if (errorCode != null) 'error_code': errorCode,
          if (context != null) 'context': context,
        },
      );
    } catch (e) {
      // Non-critical: Analytics error logging failure (silent failure)
    }
  }
}
