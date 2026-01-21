import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/weather_service.dart';
import '../services/referee_service.dart';
import '../services/merit_service.dart';
import '../services/payment_service.dart';
import '../services/tournament_service.dart';
import '../services/chatbot_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';
import '../features/auth/data/models/user_model.dart';
import '../features/booking/data/models/facility_model.dart';
import '../features/booking/data/models/booking_model.dart';
import '../features/referee/data/models/referee_job_model.dart';
import '../features/merit/data/models/merit_record_model.dart';
import '../features/tournament/data/models/tournament_model.dart';
import '../features/notifications/data/models/notification_model.dart';
import '../features/payment/data/models/transaction_model.dart';
import '../core/constants/app_constants.dart';
import '../core/config/api_keys.dart';
import '../core/utils/date_time_utils.dart' show TimeSlot;
import '../core/utils/date_time_utils.dart' as dt;
import '../core/utils/network_utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  );
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

// ═══════════════════════════════════════════════════════════════════════════
// AUTH PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Firebase auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Current user model provider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user != null) {
        return ref.watch(authServiceProvider).userModelStream(user.uid);
      }
      return Stream.value(null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Check if current user is student
final isStudentProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.isStudent ?? false;
});

/// User role provider
final userRoleProvider = Provider<UserRole>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role ?? UserRole.public;
});

/// Flag to track if profile picture is being updated/removed
/// This prevents router redirects and splash navigation during profile operations
final isUpdatingProfileProvider = StateProvider<bool>((ref) => false);

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
final facilityProvider =
    FutureProvider.family<FacilityModel?, String>((ref, facilityId) {
  return ref.watch(bookingServiceProvider).getFacilityById(facilityId);
});

/// Available time slots provider (checks for existing bookings)
/// Uses a simple key string to combine parameters
final availableSlotsProvider = FutureProvider.family<List<dt.TimeSlot>, String>((ref, key) {
  // Parse key: "facilityId|date|subUnit"
  final parts = key.split('|');
  final facilityId = parts[0];
  final date = DateTime.parse(parts[1]);
  final subUnit = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
  
  return ref.watch(bookingServiceProvider).getAvailableSlots(
        facilityId: facilityId,
        date: date,
        subUnit: subUnit,
      );
});

// ═══════════════════════════════════════════════════════════════════════════
// BOOKING PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// User's bookings provider
/// Unified system: Returns ALL bookings for the current user regardless of type (student/public/referee/admin)
/// All bookings are stored in the same Firestore collection
/// Includes bookings where user is organizer OR participant (split bill)
final userBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  
  // Query bookings where user is organizer OR participant
  // This ensures users see bookings they created AND bookings they joined via split bill
  return ref.watch(bookingServiceProvider).getUserBookings(user.uid, user.email);
});

/// Upcoming bookings provider
/// Includes bookings where user is organizer OR participant (split bill)
final upcomingBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  return ref.watch(bookingServiceProvider).getUpcomingBookings(user.uid, user.email);
});

/// Single booking by ID provider (Future for reliable initial load)
/// Note: Changed from StreamProvider to FutureProvider for better reliability
/// on initial page load, especially right after booking creation
final bookingByIdProvider = FutureProvider.family<BookingModel?, String>((ref, bookingId) {
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
// REFEREE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Available referee jobs provider
final availableJobsProvider = FutureProvider<List<RefereeJobModel>>((ref) {
  return ref.watch(refereeServiceProvider).getAvailableJobs();
});

/// Available jobs by sport provider
final availableJobsBySportProvider =
    FutureProvider.family<List<RefereeJobModel>, SportType>((ref, sport) {
  return ref.watch(refereeServiceProvider).getAvailableJobsBySport(sport);
});

/// User's referee jobs provider
final userRefereeJobsProvider = FutureProvider<List<RefereeJobModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  return ref.watch(refereeServiceProvider).getRefereeJobs(user.uid);
});

/// Upcoming referee jobs provider
final upcomingRefereeJobsProvider = FutureProvider<List<RefereeJobModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  return ref.watch(refereeServiceProvider).getUpcomingRefereeJobs(user.uid);
});

/// Filtered available jobs based on user badges (v5.0 spec)
/// Shows only jobs the user is certified to officiate
final filteredAvailableJobsProvider = FutureProvider<List<RefereeJobModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final jobs = await ref.watch(availableJobsProvider.future);
  
  if (user == null || user.badges.isEmpty) {
    return jobs; // Return all jobs if no user or no badges
  }
  
  // Filter jobs based on user's referee badges
  return jobs.where((job) {
    switch (job.sport) {
      case SportType.football:
        return user.badges.contains(AppConstants.badgeRefFootball);
      case SportType.futsal:
        return user.badges.contains(AppConstants.badgeRefFutsal);
      case SportType.badminton:
        return user.badges.contains(AppConstants.badgeRefBadminton);
      case SportType.tennis:
        return user.badges.contains(AppConstants.badgeRefTennis);
    }
  }).toList();
});

/// Referee average rating provider
final refereeRatingProvider =
    FutureProvider.family<double?, String>((ref, userId) {
  return ref.watch(refereeServiceProvider).getRefereeRating(userId);
});

// ═══════════════════════════════════════════════════════════════════════════
// MERIT PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// User's merit records provider
final meritRecordsProvider = FutureProvider<List<MeritRecordModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  return ref.watch(meritServiceProvider).getUserMeritRecords(user.uid);
});

/// Alias for merit records (used in UI)
final userMeritRecordsProvider = meritRecordsProvider;

/// Merit summary by category provider
final meritSummaryProvider = FutureProvider<Map<MeritCategory, int>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return {};
  return ref.watch(meritServiceProvider).getMeritSummary(user.uid);
});

/// Total merit points provider
final totalMeritPointsProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return 0;
  return ref.watch(meritServiceProvider).getTotalMeritPoints(user.uid);
});

// ═══════════════════════════════════════════════════════════════════════════
// PAYMENT & WALLET PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// User's wallet provider
final walletProvider = StreamProvider((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(paymentServiceProvider).walletStream(user.uid);
});

/// Transaction history provider
final transactionHistoryProvider = FutureProvider((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  return ref.watch(paymentServiceProvider).getTransactionHistory(user.uid);
});

// ═══════════════════════════════════════════════════════════════════════════
// TOURNAMENT PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Public tournaments provider (for discovery hub) - uses stream for real-time updates
final publicTournamentsProvider = StreamProvider<List<TournamentModel>>((ref) {
  return ref.watch(tournamentServiceProvider).getPublicTournamentsStream();
});

/// Featured tournaments provider (public, registration open, sorted by start date)
final featuredTournamentsProvider = FutureProvider<List<TournamentModel>>((ref) async {
  final tournaments = await ref.watch(tournamentServiceProvider).getPublicTournaments(
    statusFilter: TournamentStatus.registrationOpen,
  );
  // Return first 5 tournaments (featured)
  return tournaments.take(5).toList();
});

/// Tournament by ID provider (stream for real-time updates)
/// Use this for tournament detail screens where bracket updates need to be reflected immediately
final tournamentByIdProvider = StreamProvider.family<TournamentModel?, String>((ref, tournamentId) {
  return ref.watch(tournamentServiceProvider).getTournamentByIdStream(tournamentId);
});

/// User's tournaments provider (organizer + participant)
final userTournamentsProvider = FutureProvider<List<TournamentModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  return ref.watch(tournamentServiceProvider).getUserTournaments(user.uid);
});

/// Tournaments by sport provider
final tournamentsBySportProvider = FutureProvider.family<List<TournamentModel>, SportType>((ref, sport) {
  return ref.watch(tournamentServiceProvider).getPublicTournaments(
    sportFilter: sport,
    statusFilter: TournamentStatus.registrationOpen,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// WEATHER PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Weather check for selected date
final weatherCheckProvider = FutureProvider.family<WeatherResult, DateTime>((ref, date) {
  return ref.watch(weatherServiceProvider).checkWeatherForDate(date);
});

/// Current weather provider
final currentWeatherProvider = FutureProvider<WeatherResult>((ref) {
  return ref.watch(weatherServiceProvider).getCurrentWeather();
});

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN STATS PROVIDERS (Firebase-driven)
// ═══════════════════════════════════════════════════════════════════════════

/// Admin revenue stats provider - fetches from Firebase
final adminRevenueStatsProvider = FutureProvider<AdminRevenueStats>((ref) async {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getRevenueStats();
});

/// Admin booking counts provider
final adminBookingCountsProvider = FutureProvider<AdminBookingCounts>((ref) async {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getBookingCounts();
});

/// Admin user counts provider
final adminUserCountsProvider = FutureProvider<AdminUserCounts>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getUserCounts();
});

/// Admin tournament stats provider
final adminTournamentStatsProvider = FutureProvider<AdminTournamentStats>((ref) async {
  final tournamentService = ref.watch(tournamentServiceProvider);
  return tournamentService.getTournamentStats();
});

/// Admin today's activity provider
final adminTodayActivityProvider = FutureProvider<AdminTodayActivity>((ref) async {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getTodayActivity();
});

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN MANAGEMENT PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// All users provider (admin only)
final adminAllUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.getAllUsersStream();
});

/// All bookings provider (admin only)
final adminAllBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getAllBookingsStream();
});

/// All tournaments provider (admin only)
final adminAllTournamentsProvider = StreamProvider<List<TournamentModel>>((ref) {
  final tournamentService = ref.watch(tournamentServiceProvider);
  return tournamentService.getAllTournamentsStream();
});

/// All transactions provider (admin only)
final adminAllTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getAllTransactionsStream();
});

// ═══════════════════════════════════════════════════════════════════════════
// USER MODE PROVIDER (Student Mode vs Referee Mode)
// ═══════════════════════════════════════════════════════════════════════════

/// Active user mode (Student or Referee)
/// Defaults to Student Mode or user's preferred mode from Firebase
/// Referee Mode only available if user has referee badges
/// This allows users to switch between different app experiences based on their role
final activeUserModeProvider = StateProvider<UserMode>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  
  // Check if user has a preferred mode saved in Firebase
  if (user?.preferredMode != null) {
    try {
      final preferredMode = UserMode.fromCode(user!.preferredMode!);
      // Only return preferred mode if user can actually use it
      if (preferredMode == UserMode.referee && user.isVerifiedReferee) {
        return preferredMode;
      } else if (preferredMode == UserMode.student) {
        return preferredMode;
      }
    } catch (e) {
      // Invalid mode, fall through to default
    }
  }
  
  // Default to Student Mode
  // If user has referee badges, they can switch to Referee Mode via Profile
  return UserMode.student;
});

/// Check if user can switch to referee mode (must have referee badges)
final canSwitchToRefereeModeProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.isVerifiedReferee ?? false;
});

// ═══════════════════════════════════════════════════════════════════════════
// UI STATE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Current bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// Last login error message (persists across route changes)
final lastLoginErrorProvider = StateProvider<String?>((ref) => null);

/// Splash screen start time provider (tracks when splash was first shown)
final splashStartTimeProvider = StateProvider<DateTime?>((ref) => null);

/// Theme mode provider
final themeModeProvider = StateProvider<bool>((ref) => false); // false = light

/// Loading state provider
final isLoadingProvider = StateProvider<bool>((ref) => false);

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATION PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// User notifications stream provider
final userNotificationsProvider = StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  return ref.watch(notificationServiceProvider).getUserNotifications(userId);
});

/// Unread notifications count provider
final unreadNotificationsCountProvider = StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(notificationServiceProvider).getUnreadCount(userId);
});

// ═══════════════════════════════════════════════════════════════════════════
// NETWORK PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Network connectivity status stream provider
/// Returns `List<ConnectivityResult>` - may contain multiple connection types
final connectivityStatusProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return NetworkUtils.connectivityStream;
});

/// Is connected to internet provider (simplified boolean)
final isConnectedProvider = StreamProvider<bool>((ref) async* {
  await for (final connectivityResults in NetworkUtils.connectivityStream) {
    // If no connectivity or only 'none', return false
    yield connectivityResults.isNotEmpty && 
           !connectivityResults.contains(ConnectivityResult.none);
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// CHATBOT PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Chat history provider (session-based, cleared on app restart)
/// Stores conversation history during app session
/// Messages persist when navigating away and coming back to chatbot
final chatHistoryProvider = StateNotifierProvider<ChatHistoryNotifier, List<ChatMessage>>((ref) {
  return ChatHistoryNotifier();
});

/// Chat history notifier
class ChatHistoryNotifier extends StateNotifier<List<ChatMessage>> {
  ChatHistoryNotifier() : super([]);
  
  /// Add a single message to chat history
  void addMessage(ChatMessage message) {
    state = [...state, message];
  }
  
  /// Add multiple messages to chat history
  void addMessages(List<ChatMessage> messages) {
    state = [...state, ...messages];
  }
  
  /// Clear all chat history
  void clearHistory() {
    state = [];
  }
  
  /// Remove a specific message by ID
  void removeMessage(String messageId) {
    state = state.where((m) => m.id != messageId).toList();
  }
  
  /// Get conversation history excluding welcome messages
  /// Used for sending context to AI API
  List<ChatMessage> getConversationHistory() {
    return state.where((m) => m.type != MessageType.welcome).toList();
  }
  
  /// Check if welcome message exists
  bool hasWelcomeMessage() {
    return state.any((m) => m.type == MessageType.welcome);
  }
}
