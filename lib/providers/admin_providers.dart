import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/booking_operations_service.dart';
import '../services/tournament_service.dart';
import '../services/badge_service.dart';
import '../features/auth/data/models/user_model.dart';
import '../features/booking/data/models/booking_model.dart';
import '../features/tournament/data/models/tournament_model.dart';
import '../features/payment/data/models/transaction_model.dart';
import 'service_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN STATS PROVIDERS (Firebase-driven)
// ═══════════════════════════════════════════════════════════════════════════

/// Admin revenue stats provider - fetches from Firebase
final adminRevenueStatsProvider = FutureProvider<AdminRevenueStats>((
  ref,
) async {
  final bookingOperationsService = ref.watch(bookingOperationsServiceProvider);
  return bookingOperationsService.getRevenueStats();
});

/// Admin booking counts provider
final adminBookingCountsProvider = FutureProvider<AdminBookingCounts>((
  ref,
) async {
  final bookingOperationsService = ref.watch(bookingOperationsServiceProvider);
  return bookingOperationsService.getBookingCounts();
});

/// Admin user counts provider
final adminUserCountsProvider = FutureProvider<AdminUserCounts>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getUserCounts();
});

/// Admin tournament stats provider
final adminTournamentStatsProvider = FutureProvider<AdminTournamentStats>((
  ref,
) async {
  final tournamentService = ref.watch(tournamentServiceProvider);
  return tournamentService.getTournamentStats();
});

/// Admin today's activity provider
final adminTodayActivityProvider = FutureProvider<AdminTodayActivity>((
  ref,
) async {
  final bookingOperationsService = ref.watch(bookingOperationsServiceProvider);
  return bookingOperationsService.getTodayActivity();
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
  final bookingOperationsService = ref.watch(bookingOperationsServiceProvider);
  return bookingOperationsService.getAllBookingsStream();
});

/// All tournaments provider (admin only)
final adminAllTournamentsProvider = StreamProvider<List<TournamentModel>>((
  ref,
) {
  final tournamentService = ref.watch(tournamentServiceProvider);
  return tournamentService.getAllTournamentsStream();
});

/// All transactions provider (admin only)
final adminAllTransactionsProvider = StreamProvider<List<TransactionModel>>((
  ref,
) {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getAllTransactionsStream();
});

/// Referee badge statistics provider
final adminRefereeBadgeStatsProvider = FutureProvider<AdminRefereeBadgeStats>((
  ref,
) async {
  final usersAsync = await ref.watch(adminAllUsersProvider.future);
  final badgeService = ref.read(badgeServiceProvider);

  // Calculate referee badge statistics
  final referees =
      usersAsync.where((user) => badgeService.hasAnyBadges(user)).toList();

  final totalReferees = referees.length;
  final totalBadges = referees.fold<int>(
    0,
    (sum, referee) => sum + badgeService.getBadgeCount(referee),
  );

  // Count badges by sport
  final Map<String, int> badgesBySport = {};
  final allBadges = badgeService.getAllAvailableBadges();

  for (final badge in allBadges) {
    badgesBySport[badge.name] =
        referees
            .where(
              (referee) => badgeService.isCertifiedFor(
                referee,
                badge.name.toLowerCase(),
              ),
            )
            .length;
  }

  return AdminRefereeBadgeStats(
    totalReferees: totalReferees,
    totalBadges: totalBadges,
    badgesBySport: badgesBySport,
    sportsOffered: allBadges.length,
  );
});

/// Data class for referee badge statistics
class AdminRefereeBadgeStats {
  final int totalReferees;
  final int totalBadges;
  final Map<String, int> badgesBySport;
  final int sportsOffered;

  const AdminRefereeBadgeStats({
    required this.totalReferees,
    required this.totalBadges,
    required this.badgesBySport,
    required this.sportsOffered,
  });
}
