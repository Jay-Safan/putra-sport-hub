import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/models/user_model.dart';
import '../../../providers/admin_providers.dart';
import '../../../services/badge_service.dart';
import 'widgets/referee_badge_management_dialog.dart';

/// Referees management screen for admin
class RefereesListScreen extends ConsumerWidget {
  const RefereesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminAllUsersProvider);
    final badgeService = ref.read(badgeServiceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Referee Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1F1A),
              Color(0xFF132E25),
              Color(0xFF1A3D32),
              Color(0xFF0D1F1A),
            ],
          ),
        ),
        child: SafeArea(
          child: usersAsync.when(
            data: (users) {
              final referees =
                  users.where((user) => user.badges.isNotEmpty).toList();

              if (referees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sports_kabaddi,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Referees Found',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No users have been assigned referee badges yet.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Stats
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            'Total Referees',
                            '${referees.length}',
                            Icons.sports_kabaddi,
                          ),
                          _buildStatColumn(
                            'Total Badges',
                            '${referees.fold<int>(0, (sum, ref) => sum + ref.badges.length)}',
                            Icons.emoji_events,
                          ),
                          _buildStatColumn(
                            'Sports Covered',
                            '${badgeService.getAllAvailableBadges().length}',
                            Icons.sports_soccer,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Referees List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: referees.length,
                      itemBuilder: (context, index) {
                        final referee = referees[index];
                        final badges = badgeService.getUserBadges(referee);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              child: Text(
                                referee.displayName.isNotEmpty
                                    ? referee.displayName
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              referee.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  referee.email,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (badges.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children:
                                        badges
                                            .map(
                                              (badge) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      badge.icon,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      badge.name,
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.9,
                                                            ),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  )
                                else
                                  Text(
                                    'No badges assigned',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.settings,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              onPressed:
                                  () => _showBadgeManagementDialog(
                                    context,
                                    ref,
                                    referee,
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading:
                () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            error:
                (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load referees',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          color: Colors.red.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showBadgeManagementDialog(
    BuildContext context,
    WidgetRef ref,
    UserModel referee,
  ) {
    showDialog(
      context: context,
      builder: (context) => RefereeBadgeManagementDialog(referee: referee),
    );
  }
}
