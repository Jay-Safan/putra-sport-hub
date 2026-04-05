import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../services/badge_service.dart';

class RefereeBadgeManagementDialog extends ConsumerStatefulWidget {
  final UserModel referee;

  const RefereeBadgeManagementDialog({super.key, required this.referee});

  @override
  ConsumerState<RefereeBadgeManagementDialog> createState() =>
      _RefereeBadgeManagementDialogState();
}

class _RefereeBadgeManagementDialogState
    extends ConsumerState<RefereeBadgeManagementDialog> {
  final Set<String> _selectedBadges = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current badges
    if (widget.referee.badges.isNotEmpty) {
      _selectedBadges.addAll(widget.referee.badges);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeService = ref.read(badgeServiceProvider);
    final allBadges = badgeService.getAllAvailableBadges();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3D32),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      widget.referee.displayName.isNotEmpty
                          ? widget.referee.displayName
                              .substring(0, 1)
                              .toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage Badges',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.referee.displayName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Current Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Badges: ${_selectedBadges.length}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Available Badges',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Badge Selection - Simplified for 4 sports
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children:
                    allBadges.map((badge) {
                      final isSelected = _selectedBadges.contains(badge.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isSelected
                                    ? Colors.green.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged:
                              _isLoading
                                  ? null
                                  : (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedBadges.add(badge.id);
                                      } else {
                                        _selectedBadges.remove(badge.id);
                                      }
                                    });
                                  },
                          title: Row(
                            children: [
                              Text(
                                badge.icon,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                badge.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            badge.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                Navigator.of(context).pop();
                              },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveBadges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBadges() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final badgeService = ref.read(badgeServiceProvider);
      await badgeService.setBadgesForUser(
        widget.referee.uid,
        _selectedBadges.toList(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Badges updated successfully for ${widget.referee.displayName}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update badges: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
