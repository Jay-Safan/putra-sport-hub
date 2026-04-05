import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/tournament/data/models/tournament_model.dart';
import '../core/constants/app_constants.dart';
import 'service_providers.dart';
import 'auth_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TOURNAMENT PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Public tournaments provider (for discovery hub) - uses stream for real-time updates
final publicTournamentsProvider = StreamProvider<List<TournamentModel>>((ref) {
  return ref.watch(tournamentServiceProvider).getPublicTournamentsStream();
});

/// Featured tournaments provider (public, registration open, sorted by start date)
final featuredTournamentsProvider = FutureProvider<List<TournamentModel>>((
  ref,
) async {
  final tournaments = await ref
      .watch(tournamentServiceProvider)
      .getPublicTournaments(statusFilter: TournamentStatus.registrationOpen);
  // Return first 5 tournaments (featured)
  return tournaments.take(5).toList();
});

/// Tournament by ID provider (stream for real-time updates)
/// Use this for tournament detail screens where bracket updates need to be reflected immediately
final tournamentByIdProvider = StreamProvider.family<TournamentModel?, String>((
  ref,
  tournamentId,
) {
  return ref
      .watch(tournamentServiceProvider)
      .getTournamentByIdStream(tournamentId);
});

/// User's tournaments provider (organizer + participant)
final userTournamentsProvider = FutureProvider<List<TournamentModel>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  return ref.watch(tournamentServiceProvider).getUserTournaments(user.uid);
});

/// Tournaments by sport provider
final tournamentsBySportProvider =
    FutureProvider.family<List<TournamentModel>, SportType>((ref, sport) {
      return ref
          .watch(tournamentServiceProvider)
          .getPublicTournaments(
            sportFilter: sport,
            statusFilter: TournamentStatus.registrationOpen,
          );
    });
