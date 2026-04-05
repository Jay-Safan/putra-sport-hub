import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/tournament_service.dart';

/// Badge showing referee coverage status for a match
/// Displays: Fully Staffed, Partial, No Referee, or loading state
class RefereeCoverageBadge extends ConsumerWidget {
  final String tournamentId;
  final int matchNumber;
  final bool showDetails;

  const RefereeCoverageBadge({
    super.key,
    required this.tournamentId,
    required this.matchNumber,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<MatchRefereeCoverage>(
      future: TournamentService().getMatchRefereeCoverage(
        tournamentId: tournamentId,
        matchNumber: matchNumber,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingBadge();
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final coverage = snapshot.data!;

        // Don't show badge if no job created yet
        if (coverage.hasNoJob) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: coverage.indicatorColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: coverage.indicatorColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForStatus(coverage.status),
                size: 12,
                color: coverage.indicatorColor,
              ),
              if (showDetails) ...[
                const SizedBox(width: 4),
                Text(
                  coverage.displayText,
                  style: TextStyle(
                    color: coverage.indicatorColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                const SizedBox(width: 4),
                Text(
                  '${coverage.assignedCount}/${coverage.requiredCount}',
                  style: TextStyle(
                    color: coverage.indicatorColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'full':
        return Icons.check_circle;
      case 'partial':
        return Icons.warning;
      case 'empty':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}
