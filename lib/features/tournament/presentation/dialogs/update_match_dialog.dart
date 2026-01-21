import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../services/tournament_service.dart';
import '../../data/models/tournament_model.dart';

/// Dialog for referee to update match result
/// Simple: Select winner (Team 1 or Team 2) and optional scores
class UpdateMatchDialog extends ConsumerStatefulWidget {
  final TournamentModel tournament;
  final Map<String, dynamic> match;
  final VoidCallback onUpdated;

  const UpdateMatchDialog({
    super.key,
    required this.tournament,
    required this.match,
    required this.onUpdated,
  });

  @override
  ConsumerState<UpdateMatchDialog> createState() => _UpdateMatchDialogState();
}

class _UpdateMatchDialogState extends ConsumerState<UpdateMatchDialog> {
  String? _selectedWinnerId;
  int? _team1Score;
  int? _team2Score;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedWinnerId = widget.match['winnerId'] as String?;
    _team1Score = widget.match['team1Score'] as int?;
    _team2Score = widget.match['team2Score'] as int?;
  }

  @override
  Widget build(BuildContext context) {
    final team1Id = widget.match['team1Id'] as String?;
    final team2Id = widget.match['team2Id'] as String?;

    final team1 = team1Id != null
        ? widget.tournament.teams.firstWhere(
            (t) => t.teamId == team1Id,
            orElse: () => widget.tournament.teams.first,
          )
        : null;
    final team2 = team2Id != null
        ? widget.tournament.teams.firstWhere(
            (t) => t.teamId == team2Id,
            orElse: () => widget.tournament.teams.first,
          )
        : null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF132E25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(
                        Icons.edit,
                        color: AppTheme.primaryGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Update Match Result',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Match info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          team1?.captainName ?? 'TBD',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'VS',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          team2?.captainName ?? 'TBD',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Winner selection
                  const Text(
                    'Select Winner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Team 1 option
                  _buildWinnerOption(
                    team1?.teamId ?? '',
                    team1?.captainName ?? 'Team 1',
                    Icons.person,
                  ),
                  const SizedBox(height: 12),
                  
                  // Team 2 option
                  _buildWinnerOption(
                    team2?.teamId ?? '',
                    team2?.captainName ?? 'Team 2',
                    Icons.person,
                  ),
                  const SizedBox(height: 24),

                  // Scores (optional)
                  const Text(
                    'Scores (Optional)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildScoreInput(
                          label: team1?.captainName ?? 'Team 1',
                          value: _team1Score,
                          onChanged: (value) => setState(() => _team1Score = value),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildScoreInput(
                          label: team2?.captainName ?? 'Team 2',
                          value: _team2Score,
                          onChanged: (value) => setState(() => _team2Score = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isUpdating
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isUpdating || _selectedWinnerId == null
                              ? null
                              : _updateMatch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isUpdating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Update Match',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerOption(String teamId, String captainName, IconData icon) {
    final isSelected = _selectedWinnerId == teamId;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedWinnerId = teamId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGreen
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white54,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                captainName,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryGreen : Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreInput({
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          onChanged: (value) {
            final intValue = int.tryParse(value);
            onChanged(intValue);
          },
          controller: TextEditingController(
            text: value?.toString() ?? '',
          ),
        ),
      ],
    );
  }

  Future<void> _updateMatch() async {
    if (_selectedWinnerId == null) return;

    setState(() => _isUpdating = true);

    try {
      final tournamentService = TournamentService();
      final result = await tournamentService.updateMatchResult(
        tournamentId: widget.tournament.id,
        matchNumber: widget.match['matchNumber'] as int,
        winnerTeamId: _selectedWinnerId,
        team1Score: _team1Score,
        team2Score: _team2Score,
      );

      if (!mounted) return;

      if (result.success) {
        // Auto-advance winners to next round
        await _autoAdvanceWinners();
        
        widget.onUpdated();
        if (!context.mounted) return;
        Navigator.of(context).pop();
        
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match result updated successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to update match'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorHandler.getUserFriendlyErrorMessage(
              e,
              context: 'tournament',
              defaultMessage: 'Failed to update match result',
            ),
          ),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  /// Auto-advance winners to next round (for knockout brackets)
  Future<void> _autoAdvanceWinners() async {
    // This would be handled by the tournament service
    // For now, it's a placeholder - the backend should handle auto-advancement
    // when updateMatchResult is called
  }
}
