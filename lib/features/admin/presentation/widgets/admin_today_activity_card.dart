import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/booking_operations_service.dart';

/// Today's activity summary card for admin dashboard
class AdminTodayActivityCard extends StatelessWidget {
  final AdminTodayActivity activity;

  const AdminTodayActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen.withValues(alpha: 0.15),
                AppTheme.primaryGreenLight.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.today_rounded,
                      color: AppTheme.primaryGreenLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Today's Activity",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Activity metrics grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.book_online_rounded,
                      label: 'Bookings',
                      value: activity.bookingsToday.toString(),
                      color: AppTheme.infoBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.attach_money_rounded,
                      label: 'Revenue',
                      value: 'RM ${activity.revenueToday.toStringAsFixed(0)}',
                      color: AppTheme.successGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.person_add_rounded,
                      label: 'New Users',
                      value: activity.newUsersToday.toString(),
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.emoji_events_rounded,
                      label: 'Tournaments',
                      value: activity.tournamentsCreatedToday.toString(),
                      color: AppTheme.badmintonPurple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
