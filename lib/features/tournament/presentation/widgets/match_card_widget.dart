import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/tournament_team_model.dart';
import 'referee_coverage_badge.dart';

/// Single match card showing captain names and scores
/// Minimalist design - captain names only
class MatchCardWidget extends StatelessWidget {
  final Map<String, dynamic> match;
  final TournamentTeamModel? team1;
  final TournamentTeamModel? team2;
  final bool canUpdate;
  final VoidCallback? onTap;
  final String? tournamentId;

  const MatchCardWidget({
    super.key,
    required this.match,
    this.team1,
    this.team2,
    this.canUpdate = false,
    this.onTap,
    this.tournamentId,
  });

  @override
  Widget build(BuildContext context) {
    final status = match['status'] as String? ?? 'PENDING';
    final isCompleted = status == 'COMPLETED';
    final winnerId = match['winnerId'] as String?;
    final team1Score = match['team1Score'] as int?;
    final team2Score = match['team2Score'] as int?;
    
    final team1Name = team1?.captainName ?? 'TBD';
    final team2Name = team2?.captainName ?? 'TBD';
    final team1Won = winnerId != null && team1?.teamId == winnerId;
    final team2Won = winnerId != null && team2?.teamId == winnerId;

    // Get match time if available
    final matchStartTime = match['matchStartTime'] as Timestamp?;
    final matchTime = matchStartTime?.toDate();
    final timeFormat = DateFormat('h:mm a');

    return GestureDetector(
      onTap: canUpdate && !isCompleted ? onTap : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted
                ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    match['round'] as String? ?? 'MATCH',
                    style: TextStyle(
                      color: isCompleted
                          ? AppTheme.primaryGreen
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                // Referee coverage badge
                if (tournamentId != null && match['matchNumber'] != null)
                  RefereeCoverageBadge(
                    tournamentId: tournamentId!,
                    matchNumber: match['matchNumber'] as int,
                  ),
                const SizedBox(width: 8),
                if (canUpdate && !isCompleted)
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Match time display
            if (matchTime != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeFormat.format(matchTime),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Team 1
            _buildTeamRow(
              team1Name,
              team1Score,
              team1Won,
              isCompleted,
            ),
            
            const SizedBox(height: 8),
            
            // VS divider
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            
            const SizedBox(height: 8),
            
            // Team 2
            _buildTeamRow(
              team2Name,
              team2Score,
              team2Won,
              isCompleted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(
    String captainName,
    int? score,
    bool isWinner,
    bool isCompleted,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            captainName,
            style: TextStyle(
              color: isWinner && isCompleted
                  ? AppTheme.primaryGreen
                  : Colors.white,
              fontSize: 14,
              fontWeight: isWinner && isCompleted
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
        if (score != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isWinner && isCompleted
                  ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$score',
              style: TextStyle(
                color: isWinner && isCompleted
                    ? AppTheme.primaryGreen
                    : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
