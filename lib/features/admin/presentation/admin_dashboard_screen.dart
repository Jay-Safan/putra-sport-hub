import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/seed_service.dart';
import '../../../providers/providers.dart';
import 'widgets/admin_stat_card.dart';
import 'widgets/admin_stat_card_shimmer.dart';
import 'widgets/admin_quick_action_card.dart';
import 'widgets/admin_today_activity_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _allowPointerEvents = false;

  @override
  void initState() {
    super.initState();
    // Delay pointer events until after transition completes (400ms + small buffer)
    // This prevents mouse tracker errors during login-to-admin navigation transition
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        setState(() {
          _allowPointerEvents = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: IgnorePointer(
        ignoring: !_allowPointerEvents,
        child: Container(
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // Extra bottom padding for nav
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Header Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.upmRed, AppTheme.upmRedLight],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.upmRed.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage system data and operations',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Stats Overview Section
                _buildStatsOverview(),
                const SizedBox(height: 32),
                
                // Today's Activity Section
                _buildTodayActivity(),
                const SizedBox(height: 32),
                
                // Quick Actions Grid
                _buildQuickActions(),
                const SizedBox(height: 32),
                
                // System Tools Section
                _buildResetDataSection(),
                const SizedBox(height: 40), // Extra space for navigation buttons
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final userCountsAsync = ref.watch(adminUserCountsProvider);
    final revenueStatsAsync = ref.watch(adminRevenueStatsProvider);
    final bookingCountsAsync = ref.watch(adminBookingCountsProvider);
    final tournamentStatsAsync = ref.watch(adminTournamentStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // 2x2 Grid of stat cards
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: userCountsAsync.when(
                    data: (counts) => AdminStatCard(
                      label: 'Total Users',
                      value: counts.totalUsers.toString(),
                      icon: Icons.people_rounded,
                      gradientStart: AppTheme.infoBlue,
                      gradientEnd: AppTheme.futsalBlue,
                    ),
                    loading: () => const AdminStatCardShimmer(),
                    error: (_, __) => const AdminStatCard(
                      label: 'Total Users',
                      value: '0',
                      icon: Icons.people_rounded,
                      gradientStart: AppTheme.infoBlue,
                      gradientEnd: AppTheme.futsalBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: revenueStatsAsync.when(
                    data: (stats) => AdminStatCard(
                      label: 'Total Revenue',
                      value: 'RM ${stats.totalRevenue.toStringAsFixed(0)}',
                      icon: Icons.attach_money_rounded,
                      gradientStart: AppTheme.successGreen,
                      gradientEnd: AppTheme.primaryGreen,
                    ),
                    loading: () => const AdminStatCardShimmer(),
                    error: (_, __) => const AdminStatCard(
                      label: 'Total Revenue',
                      value: 'RM 0',
                      icon: Icons.attach_money_rounded,
                      gradientStart: AppTheme.successGreen,
                      gradientEnd: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: bookingCountsAsync.when(
                    data: (counts) => AdminStatCard(
                      label: 'Active Bookings',
                      value: counts.confirmed.toString(),
                      icon: Icons.book_online_rounded,
                      gradientStart: AppTheme.warningAmber,
                      gradientEnd: AppTheme.accentGold,
                    ),
                    loading: () => const AdminStatCardShimmer(),
                    error: (_, __) => const AdminStatCard(
                      label: 'Active Bookings',
                      value: '0',
                      icon: Icons.book_online_rounded,
                      gradientStart: AppTheme.warningAmber,
                      gradientEnd: AppTheme.accentGold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: tournamentStatsAsync.when(
                    data: (stats) => AdminStatCard(
                      label: 'Active Tournaments',
                      value: stats.active.toString(),
                      icon: Icons.emoji_events_rounded,
                      gradientStart: AppTheme.badmintonPurple,
                      gradientEnd: const Color(0xFFBA68C8),
                    ),
                    loading: () => const AdminStatCardShimmer(),
                    error: (_, __) => const AdminStatCard(
                      label: 'Active Tournaments',
                      value: '0',
                      icon: Icons.emoji_events_rounded,
                      gradientStart: AppTheme.badmintonPurple,
                      gradientEnd: Color(0xFFBA68C8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayActivity() {
    final todayActivityAsync = ref.watch(adminTodayActivityProvider);

    return todayActivityAsync.when(
      data: (activity) => AdminTodayActivityCard(activity: activity),
      loading: () => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // 3-column grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            AdminQuickActionCard(
              icon: Icons.people_rounded,
              label: 'Users',
              color: AppTheme.infoBlue,
              onTap: () => context.push('/admin/users'),
            ),
            AdminQuickActionCard(
              icon: Icons.book_online_rounded,
              label: 'Bookings',
              color: AppTheme.warningAmber,
              onTap: () => context.push('/admin/bookings'),
            ),
            AdminQuickActionCard(
              icon: Icons.emoji_events_rounded,
              label: 'Tournaments',
              color: AppTheme.badmintonPurple,
              onTap: () => context.push('/admin/tournaments'),
            ),
            AdminQuickActionCard(
              icon: Icons.sports_soccer_rounded,
              label: 'Facilities',
              color: AppTheme.primaryGreen,
              onTap: () => context.push('/admin/facilities'),
            ),
            AdminQuickActionCard(
              icon: Icons.gavel_rounded,
              label: 'Referees',
              color: AppTheme.futsalBlue,
              onTap: () => context.push('/admin/referees'),
            ),
            AdminQuickActionCard(
              icon: Icons.receipt_long_rounded,
              label: 'Transactions',
              color: AppTheme.successGreen,
              onTap: () => context.push('/admin/transactions'),
            ),
            AdminQuickActionCard(
              icon: Icons.analytics_rounded,
              label: 'Analytics',
              color: AppTheme.footballOrange,
              onTap: () => context.push('/admin/analytics'),
            ),
            AdminQuickActionCard(
              icon: Icons.settings_rounded,
              label: 'System Tools',
              color: AppTheme.upmRed,
              onTap: () {
                // Scroll to system tools section
                // For now, just show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scroll down for system tools')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResetDataSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.warningAmber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.warningAmber.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningAmber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: AppTheme.warningAmber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reset All Data',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Demo & Testing',
                          style: TextStyle(
                            color: AppTheme.warningAmber,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Clear all bookings, transactions, tournaments, wallets, and other data. This is useful for demo purposes and testing.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              
              // What gets deleted
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Will be deleted:',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBulletPoint('All bookings'),
                    _buildBulletPoint('All transactions'),
                    _buildBulletPoint('All tournaments'),
                    _buildBulletPoint('All referee jobs'),
                    _buildBulletPoint('All wallets (balances reset to 0)'),
                    _buildBulletPoint('All facilities (will be re-seeded automatically)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // What's preserved
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.successGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.successGreen,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Users will be preserved (all accounts kept)',
                        style: TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Reset Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showResetDataDialog(),
                  icon: const Icon(Icons.delete_outline, size: 22),
                  label: const Text(
                    'Reset Data (Keep Users)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningAmber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A3D32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, color: AppTheme.warningAmber, size: 28),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'Reset All Data?',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Text(
          'This action cannot be undone. All data except user accounts will be permanently deleted. Are you sure you want to continue?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningAmber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            child: const Text(
              'Yes, Reset Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetData() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Color(0xFF1A3D32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            SizedBox(height: 20),
            Text(
              'Resetting data...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );

    try {
      final seedService = SeedService();
      
      // Clear all data except users
      await seedService.clearAllExceptUsers();
      
      // Re-seed facilities and other data
      await seedService.seedAll();

      // Invalidate providers to refresh stats
      ref.invalidate(adminUserCountsProvider);
      ref.invalidate(adminRevenueStatsProvider);
      ref.invalidate(adminBookingCountsProvider);
      ref.invalidate(adminTournamentStatsProvider);
      ref.invalidate(adminTodayActivityProvider);

      if (!mounted) return;
      
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '✅ Data reset complete! All data cleared except users. Facilities re-seeded.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorRed,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}