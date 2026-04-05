import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/tournament_model.dart';
import 'match_card_widget.dart';
import '../dialogs/update_match_dialog.dart';
import '../../../../providers/providers.dart';

/// Tournament bracket widget - displays matches in minimalist style
/// Shows captain names only
class TournamentBracketWidget extends ConsumerWidget {
  final TournamentModel tournament;
  final bool canUpdate;

  const TournamentBracketWidget({
    super.key,
    required this.tournament,
    this.canUpdate = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tournament.bracketData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tour_outlined,
                size: 64,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Bracket not initialized',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bracket will be generated when registration closes',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final bracketData = tournament.bracketData!;
    final matches =
        (bracketData['matches'] as List<dynamic>?)
            ?.map((m) => Map<String, dynamic>.from(m))
            .toList() ??
        [];

    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No matches yet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    // Group matches by round
    final quarterFinals =
        matches.where((m) => m['round'] == 'QUARTER_FINAL').toList()..sort(
          (a, b) =>
              (a['matchNumber'] as int).compareTo(b['matchNumber'] as int),
        );

    final semiFinals =
        matches.where((m) => m['round'] == 'SEMI_FINAL').toList()..sort(
          (a, b) =>
              (a['matchNumber'] as int).compareTo(b['matchNumber'] as int),
        );

    final semifinalMatches =
        matches.where((m) => m['round'] == 'SEMIFINAL').toList()..sort(
          (a, b) =>
              (a['matchNumber'] as int).compareTo(b['matchNumber'] as int),
        );

    final finalMatches =
        matches.where((m) => m['round'] == 'FINAL').toList()..sort(
          (a, b) =>
              (a['matchNumber'] as int).compareTo(b['matchNumber'] as int),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.tour, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Tournament Bracket',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (canUpdate)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'Referee Mode',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // 8-Team Knockout Bracket
          if (tournament.format == TournamentFormat.eightTeamKnockout) ...[
            if (quarterFinals.isNotEmpty) ...[
              _buildRoundHeader('Quarter-Finals'),
              const SizedBox(height: 12),
              ...quarterFinals.map(
                (match) => _buildMatchCard(context, ref, match),
              ),
              const SizedBox(height: 32),
            ],
            if (semiFinals.isNotEmpty) ...[
              _buildRoundHeader('Semi-Finals'),
              const SizedBox(height: 12),
              ...semiFinals.map(
                (match) => _buildMatchCard(context, ref, match),
              ),
              const SizedBox(height: 32),
            ],
            if (finalMatches.isNotEmpty) ...[
              _buildRoundHeader('Final'),
              const SizedBox(height: 12),
              ...finalMatches.map(
                (match) => _buildMatchCard(context, ref, match),
              ),
            ],
          ] else if (tournament.format == TournamentFormat.fourTeamGroup) ...[
            // 4-Team Knockout
            if (semifinalMatches.isNotEmpty) ...[
              _buildRoundHeader('Semifinals'),
              const SizedBox(height: 12),
              ...semifinalMatches.map(
                (match) => _buildMatchCard(context, ref, match),
              ),
              const SizedBox(height: 24),
            ],
            if (finalMatches.isNotEmpty) ...[
              _buildRoundHeader('Final'),
              const SizedBox(height: 12),
              ...finalMatches.map(
                (match) => _buildMatchCard(context, ref, match),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRoundHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> match,
  ) {
    // Get teams by ID
    final team1Id = match['team1Id'] as String?;
    final team2Id = match['team2Id'] as String?;

    final team1 =
        team1Id != null
            ? tournament.teams.firstWhere(
              (t) => t.teamId == team1Id,
              orElse: () => tournament.teams.first, // Fallback
            )
            : null;
    final team2 =
        team2Id != null
            ? tournament.teams.firstWhere(
              (t) => t.teamId == team2Id,
              orElse: () => tournament.teams.first, // Fallback
            )
            : null;

    return MatchCardWidget(
      match: match,
      team1: team1,
      team2: team2,
      canUpdate: canUpdate,
      tournamentId: tournament.id,
      onTap: () => _showUpdateMatchDialog(context, ref, match),
    );
  }

  Future<void> _showUpdateMatchDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> match,
  ) async {
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => UpdateMatchDialog(
            tournament: tournament,
            match: match,
            onUpdated: () {
              // Refresh tournament data
              ref.invalidate(tournamentByIdProvider(tournament.id));
            },
          ),
    );
  }
}
