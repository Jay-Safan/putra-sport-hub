import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/sport_icon.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/utils/error_handler.dart';
import '../../../providers/providers.dart';
import '../../../services/badge_service.dart';
import '../data/models/referee_job_model.dart';

/// SukanGig - Referee Marketplace Dashboard
/// A gig-economy style marketplace for sports officiating jobs
class RefereeDashboardScreen extends ConsumerStatefulWidget {
  const RefereeDashboardScreen({super.key});

  @override
  ConsumerState<RefereeDashboardScreen> createState() =>
      _RefereeDashboardScreenState();
}

enum JobTypeFilter { all, tournament, practice }

class _RefereeDashboardScreenState extends ConsumerState<RefereeDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _acceptingJobId; // Track which job is being accepted
  JobTypeFilter _selectedJobTypeFilter = JobTypeFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isStudentWithoutBadges =
        user?.isStudent == true && !(user?.isVerifiedReferee ?? false);

    return Scaffold(
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
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background orbs - ignore pointer events
            IgnorePointer(child: _buildBackgroundOrbs()),
            SafeArea(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildHeader(context, user)
                              .animate()
                              .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                              .slideY(begin: -0.1, end: 0, duration: 500.ms),
                          // Show "Become a Referee" banner for students without badges
                          if (isStudentWithoutBadges) ...[
                            _buildBecomeRefereeBanner(context)
                                .animate()
                                .fadeIn(
                                  duration: 500.ms,
                                  delay: 100.ms,
                                  curve: Curves.easeOut,
                                )
                                .slideY(begin: 0.1, end: 0, duration: 500.ms),
                            const SizedBox(height: 16),
                          ],
                          const SizedBox(height: 12),
                          _buildStatsBar(user)
                              .animate()
                              .fadeIn(
                                duration: 600.ms,
                                delay: 200.ms,
                                curve: Curves.easeOut,
                              )
                              .slideY(
                                begin: 0.1,
                                end: 0,
                                duration: 600.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true, // Tab bar stays visible when scrolling
                      delegate: _TabBarDelegate(
                        child: _buildTabBar()
                            .animate()
                            .fadeIn(
                              duration: 500.ms,
                              delay: 300.ms,
                              curve: Curves.easeOut,
                            )
                            .slideY(begin: 0.05, end: 0, duration: 500.ms),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAvailableJobsTab(user),
                    _buildMyJobsTab(user),
                    _buildHistoryTab(user),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryGreen.withValues(alpha: 0.25),
                      AppTheme.primaryGreen.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 4000.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(duration: 1000.ms),
        ),
        Positioned(
          bottom: 150,
          left: -80,
          child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.upmRed.withValues(alpha: 0.15),
                      AppTheme.upmRed.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 5000.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(duration: 1200.ms, delay: 200.ms),
        ),
        // Earnings accent orb
        Positioned(
          top: 200,
          right: 30,
          child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryGreen.withValues(alpha: 0.2),
                      AppTheme.primaryGreen.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 3500.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(duration: 1000.ms, delay: 400.ms),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    final badgeService = ref.read(badgeServiceProvider);
    final userBadges =
        user != null ? badgeService.getUserBadges(user) : <BadgeInfo>[];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Sport icon instead of back button (this is a main tab)
              _buildGlassIconButton(Icons.sports),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'SukanGig',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.upmRed, Color(0xFFE53935)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'REFEREE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Officiate matches, earn rewards',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Badge Display Section
          if (userBadges.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Referee Badges (${userBadges.length})',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        userBadges
                            .map(
                              (badge) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryGreen.withValues(
                                        alpha: 0.3,
                                      ),
                                      AppTheme.primaryGreen.withValues(
                                        alpha: 0.1,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.primaryGreen.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      badge.icon,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      badge.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.withValues(alpha: 0.8),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Referee Badges',
                          style: TextStyle(
                            color: Colors.orange.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Contact admin to get certified for sports',
                          style: TextStyle(
                            color: Colors.orange.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGlassIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(user) {
    final userJobs = ref.watch(userRefereeJobsProvider);
    final rating = ref.watch(refereeRatingProvider(user?.uid ?? ''));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.monetization_on,
                  value:
                      'RM${AppConstants.refereeEarningsPractice.toInt()}/${AppConstants.refereeEarningsTournament.toInt()}',
                  label: 'Practice/Tournament',
                  color: AppTheme.primaryGreen,
                  isHighlighted: true,
                ),
                _buildStatDivider(),
                userJobs.when(
                  data: (jobs) {
                    final completed =
                        jobs
                            .where((j) => j.status == JobStatus.completed)
                            .length;
                    return _buildStatItem(
                      icon: Icons.check_circle,
                      value: completed.toString(),
                      label: 'Completed',
                      color: AppTheme.accentGold,
                    );
                  },
                  loading:
                      () => _buildStatItem(
                        icon: Icons.check_circle,
                        value: '-',
                        label: 'Completed',
                        color: AppTheme.accentGold,
                      ),
                  error:
                      (_, __) => _buildStatItem(
                        icon: Icons.check_circle,
                        value: '0',
                        label: 'Completed',
                        color: AppTheme.accentGold,
                      ),
                ),
                _buildStatDivider(),
                rating.when(
                  data:
                      (r) => _buildStatItem(
                        icon: Icons.star,
                        value: r?.toStringAsFixed(1) ?? 'N/A',
                        label: 'Rating',
                        color: Colors.amber,
                      ),
                  loading:
                      () => _buildStatItem(
                        icon: Icons.star,
                        value: '-',
                        label: 'Rating',
                        color: Colors.amber,
                      ),
                  error:
                      (_, __) => _buildStatItem(
                        icon: Icons.star,
                        value: 'N/A',
                        label: 'Rating',
                        color: Colors.amber,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            boxShadow:
                isHighlighted
                    ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                    : null,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? color : Colors.white,
            fontSize: isHighlighted ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 50,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Available'),
                Tab(text: 'My Jobs'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableJobsTab(user) {
    final availableJobs = ref.watch(availableJobsProvider);
    final userJobs = ref.watch(userRefereeJobsProvider);

    // Get user's certifications to filter jobs
    final userBadges = user?.badges ?? <String>[];

    return availableJobs.when(
      data: (jobs) {
        // Get user's accepted jobs for conflict checking
        final acceptedJobs = userJobs.maybeWhen(
          data:
              (userJobsList) =>
                  userJobsList
                      .where(
                        (j) =>
                            j.status == JobStatus.open ||
                            j.status == JobStatus.assigned,
                      )
                      .toList(),
          orElse: () => <RefereeJobModel>[],
        );

        // Filter jobs based on user's certifications and availability (for counts and display)
        final certifiedJobs =
            jobs.where((job) {
              // Filter out jobs if no certifications
              if (userBadges.isEmpty) return true; // Show all if no badges
              if (!_userCanOfficiate(job.sport, userBadges)) return false;

              // REFINEMENT: Filter out jobs where user is already assigned
              // This eliminates duplication between Available and My Jobs tabs
              // Added safe checking to handle potential data inconsistencies
              try {
                if (user?.uid != null && job.isUserAssigned(user!.uid)) {
                  return false;
                }
              } catch (e) {
                // Log the error but continue processing to avoid breaking the UI
                debugPrint('Error checking user assignment: $e');
              }

              return true;
            }).toList();

        // Apply job type filter for display
        final filteredJobs = _applyJobTypeFilter(certifiedJobs);

        // Always show filter bar at top, then content below
        return Column(
          children: [
            // Filter bar - ALWAYS visible with counts from certified jobs
            _buildJobTypeFilterBar(certifiedJobs),

            // Content area - either jobs list or empty state
            Expanded(
              child:
                  filteredJobs.isEmpty
                      ? RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(availableJobsProvider);
                        },
                        color: AppTheme.primaryGreen,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: _buildEmptyStateContent(
                              icon: Icons.sports,
                              title:
                                  userBadges.isEmpty
                                      ? 'Get Certified First 🏅'
                                      : 'No Available Jobs ⚽',
                              subtitle:
                                  userBadges.isEmpty
                                      ? 'Complete a referee certification course (e.g., QKS2101) to start officiating matches and earning RM 20-40 per game!'
                                      : _selectedJobTypeFilter !=
                                          JobTypeFilter.all
                                      ? 'No ${_selectedJobTypeFilter == JobTypeFilter.tournament ? "tournament" : "practice"} jobs available right now. Try selecting "All Jobs" or check back later!'
                                      : 'No referee jobs available at the moment. New opportunities appear when tournaments are created or bookings request referees. Check back soon!',
                            ),
                          ),
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(availableJobsProvider);
                        },
                        color: AppTheme.primaryGreen,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredJobs.length,
                          itemBuilder: (context, index) {
                            final job = filteredJobs[index];

                            // Check for conflicts with user's accepted jobs
                            final hasConflict = acceptedJobs.any(
                              (acceptedJob) => _hasTimeOverlap(
                                job.startTime,
                                job.endTime,
                                acceptedJob.startTime,
                                acceptedJob.endTime,
                              ),
                            );

                            return _buildJobCard(
                                  job,
                                  user,
                                  isAvailable: true,
                                  hasConflict: hasConflict,
                                )
                                .animate()
                                .fadeIn(
                                  duration: 400.ms,
                                  delay: (index * 50).ms,
                                  curve: Curves.easeOut,
                                )
                                .slideY(
                                  begin: 0.1,
                                  end: 0,
                                  duration: 400.ms,
                                  delay: (index * 50).ms,
                                  curve: Curves.easeOut,
                                );
                          },
                        ),
                      ),
            ),
          ],
        );
      },
      loading: () => _buildLoadingState(),
      error:
          (err, _) => _buildErrorState(
            ErrorHandler.getUserFriendlyErrorMessage(
              err,
              context: 'referee',
              defaultMessage: 'Unable to load referee jobs. Please try again.',
            ),
          ),
    );
  }

  /// Empty state content widget (without Center wrapper for use inside Expanded)
  Widget _buildEmptyStateContent({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 48,
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 20),
            Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms, curve: Curves.easeOut)
                .slideY(begin: 0.1, end: 0, duration: 500.ms),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
              duration: 500.ms,
              delay: 300.ms,
              curve: Curves.easeOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyJobsTab(user) {
    final myJobs = ref.watch(userRefereeJobsProvider);

    return myJobs.when(
      data: (jobs) {
        // REFINEMENT: Enhanced categorization with clearer status handling
        // Only show upcoming/active jobs (not completed or cancelled)
        final upcomingJobs =
            jobs
                .where(
                  (j) =>
                      j.status != JobStatus.completed &&
                      j.status != JobStatus.cancelled &&
                      j.startTime.isAfter(
                        DateTime.now().subtract(const Duration(hours: 2)),
                      ),
                )
                .toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));

        if (upcomingJobs.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userRefereeJobsProvider);
            },
            color: AppTheme.primaryGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: _buildEmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'No Upcoming Jobs 📋',
                  subtitle:
                      'You haven\'t accepted any referee jobs yet. Browse the "Available" tab to find matches that need officiating! Jobs you accept will appear here with clear status indicators.',
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userRefereeJobsProvider);
          },
          color: AppTheme.primaryGreen,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildSectionHeader('Upcoming', upcomingJobs.length),
              const SizedBox(height: 16),
              ...upcomingJobs.asMap().entries.map((entry) {
                final index = entry.key;
                final job = entry.value;
                return _buildJobCard(job, user)
                    .animate()
                    .fadeIn(
                      duration: 400.ms,
                      delay: (index * 50).ms,
                      curve: Curves.easeOut,
                    )
                    .slideY(
                      begin: 0.1,
                      end: 0,
                      duration: 400.ms,
                      delay: (index * 50).ms,
                      curve: Curves.easeOut,
                    );
              }),
            ],
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error:
          (err, _) => _buildErrorState(
            ErrorHandler.getUserFriendlyErrorMessage(
              err,
              context: 'referee',
              defaultMessage: 'Unable to load referee jobs. Please try again.',
            ),
          ),
    );
  }

  Widget _buildHistoryTab(user) {
    final myJobs = ref.watch(userRefereeJobsProvider);

    return myJobs.when(
      data: (jobs) {
        // REFINEMENT: Include cancelled jobs for complete history view
        // Get completed jobs, past jobs, and cancelled jobs
        final pastJobs =
            jobs
                .where(
                  (j) =>
                      j.status == JobStatus.completed ||
                      j.status == JobStatus.paid ||
                      j.status ==
                          JobStatus.cancelled || // Include cancelled jobs
                      j.startTime.isBefore(
                        DateTime.now().subtract(const Duration(hours: 2)),
                      ),
                )
                .toList()
              ..sort(
                (a, b) => b.startTime.compareTo(a.startTime),
              ); // Newest first

        // Calculate total earnings
        final totalEarnings = pastJobs.fold<double>(
          0,
          (total, job) => total + job.earnings,
        );

        // Calculate this month's earnings
        final now = DateTime.now();
        final thisMonthStart = DateTime(now.year, now.month, 1);
        final thisMonthEarnings = pastJobs
            .where((j) => j.startTime.isAfter(thisMonthStart))
            .fold<double>(0, (total, job) => total + job.earnings);

        // Group jobs by month
        final groupedJobs = <String, List<RefereeJobModel>>{};
        for (final job in pastJobs) {
          final monthKey = DateFormat('MMMM yyyy').format(job.startTime);
          groupedJobs.putIfAbsent(monthKey, () => []);
          groupedJobs[monthKey]!.add(job);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userRefereeJobsProvider);
          },
          color: AppTheme.primaryGreen,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Earnings Summary Card
              _buildEarningsSummaryCard(
                    totalEarnings: totalEarnings,
                    thisMonthEarnings: thisMonthEarnings,
                    totalGigs: pastJobs.length,
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                  .slideY(
                    begin: 0.1,
                    end: 0,
                    duration: 600.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 24),

              if (pastJobs.isEmpty)
                RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(userRefereeJobsProvider);
                  },
                  color: AppTheme.primaryGreen,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: _buildEmptyStateContent(
                        icon: Icons.history_outlined,
                        title: 'No Past Gigs 📊',
                        subtitle:
                            'Your completed referee jobs and earnings history will appear here once you complete your first gig!',
                      ),
                    ),
                  ),
                )
              else ...[
                // Past gigs grouped by month
                for (final entry in groupedJobs.entries) ...[
                  _buildMonthHeader(entry.key, entry.value.length),
                  const SizedBox(height: 12),
                  ...entry.value.asMap().entries.map((jobEntry) {
                    final index = jobEntry.key;
                    final job = jobEntry.value;
                    return _buildPastJobCard(job)
                        .animate()
                        .fadeIn(
                          duration: 400.ms,
                          delay: (index * 50).ms,
                          curve: Curves.easeOut,
                        )
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 400.ms,
                          delay: (index * 50).ms,
                          curve: Curves.easeOut,
                        );
                  }),
                  const SizedBox(height: 20),
                ],
              ],
            ],
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error:
          (err, _) => _buildErrorState(
            ErrorHandler.getUserFriendlyErrorMessage(
              err,
              context: 'referee',
              defaultMessage: 'Unable to load referee jobs. Please try again.',
            ),
          ),
    );
  }

  Widget _buildEarningsSummaryCard({
    required double totalEarnings,
    required double thisMonthEarnings,
    required int totalGigs,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen.withValues(alpha: 0.25),
                AppTheme.primaryGreenLight.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppTheme.primaryGreenLight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Earnings Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildEarningStat(
                      label: 'Total Earnings',
                      value: 'RM ${totalEarnings.toStringAsFixed(0)}',
                      icon: Icons.payments_rounded,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: _buildEarningStat(
                      label: 'This Month',
                      value: 'RM ${thisMonthEarnings.toStringAsFixed(0)}',
                      icon: Icons.calendar_today_rounded,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: _buildEarningStat(
                      label: 'Gigs Done',
                      value: totalGigs.toString(),
                      icon: Icons.sports_score_rounded,
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

  Widget _buildEarningStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryGreenLight.withValues(alpha: 0.7),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMonthHeader(String month, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                month,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count gigs',
            style: TextStyle(
              color: AppTheme.primaryGreenLight.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPastJobCard(RefereeJobModel job) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');
    final sportColor = _getSportColor(job.sport);
    final isPaid = job.status == JobStatus.paid;
    final isCompleted = job.status == JobStatus.completed || isPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Sport icon (muted)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: sportColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SportIcon(
                      sport: job.sport,
                      color: sportColor.withValues(alpha: 0.7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Job details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                job.facilityName,
                                style: TextStyle(
                                  color:
                                      job.status == JobStatus.cancelled
                                          ? Colors.white.withValues(alpha: 0.5)
                                          : Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration:
                                      job.status == JobStatus.cancelled
                                          ? TextDecoration.lineThrough
                                          : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Enhanced status/type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    job.status == JobStatus.cancelled
                                        ? Colors.red.withValues(alpha: 0.2)
                                        : _isTournamentJob(job)
                                        ? Colors.amber.withValues(alpha: 0.2)
                                        : Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                job.status == JobStatus.cancelled
                                    ? 'Cancelled'
                                    : _isTournamentJob(job)
                                    ? 'Tournament'
                                    : 'Practice',
                                style: TextStyle(
                                  color:
                                      job.status == JobStatus.cancelled
                                          ? Colors.red.withValues(alpha: 0.9)
                                          : _isTournamentJob(job)
                                          ? Colors.amber.withValues(alpha: 0.9)
                                          : Colors.blue.withValues(alpha: 0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${dateFormat.format(job.startTime)} • ${timeFormat.format(job.startTime)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Earnings & Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Earnings (green)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+RM${job.earnings.toInt()}',
                          style: const TextStyle(
                            color: AppTheme.primaryGreenLight,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Status badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPaid
                                ? Icons.paid_rounded
                                : isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.history_rounded,
                            color:
                                isPaid
                                    ? AppTheme.primaryGreenLight
                                    : isCompleted
                                    ? Colors.green.withValues(alpha: 0.7)
                                    : Colors.white.withValues(alpha: 0.5),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPaid
                                ? 'Paid'
                                : isCompleted
                                ? 'Completed'
                                : 'Past',
                            style: TextStyle(
                              color:
                                  isPaid
                                      ? AppTheme.primaryGreenLight
                                      : isCompleted
                                      ? Colors.green.withValues(alpha: 0.7)
                                      : Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  Widget _buildJobTypeFilterBar(List<RefereeJobModel> jobs) {
    final allCount = jobs.length;
    final tournamentCount = jobs.where((j) => _isTournamentJob(j)).length;
    final practiceCount = jobs.where((j) => _isPracticeJob(j)).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'All Jobs',
              count: allCount,
              isSelected: _selectedJobTypeFilter == JobTypeFilter.all,
              onTap: () {
                setState(() {
                  _selectedJobTypeFilter = JobTypeFilter.all;
                });
              },
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              label: 'Tournament',
              count: tournamentCount,
              isSelected: _selectedJobTypeFilter == JobTypeFilter.tournament,
              onTap: () {
                setState(() {
                  _selectedJobTypeFilter = JobTypeFilter.tournament;
                });
              },
              icon: Icons.emoji_events_rounded,
              earnings: AppConstants.refereeEarningsTournament,
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              label: 'Practice',
              count: practiceCount,
              isSelected: _selectedJobTypeFilter == JobTypeFilter.practice,
              onTap: () {
                setState(() {
                  _selectedJobTypeFilter = JobTypeFilter.practice;
                });
              },
              icon: Icons.sports_soccer_rounded,
              earnings: AppConstants.refereeEarningsPractice,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    double? earnings,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient:
                  isSelected
                      ? LinearGradient(
                        colors: [
                          AppTheme.primaryGreenLight.withValues(alpha: 0.3),
                          AppTheme.primaryGreen.withValues(alpha: 0.2),
                        ],
                      )
                      : null,
              color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isSelected
                        ? AppTheme.primaryGreenLight.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.15),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color:
                        isSelected
                            ? AppTheme.primaryGreenLight
                            : Colors.white.withValues(alpha: 0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color:
                        isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                if (earnings != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(RM ${earnings.toInt()})',
                    style: TextStyle(
                      color:
                          isSelected
                              ? AppTheme.primaryGreenLight
                              : Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppTheme.primaryGreenLight.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color:
                          isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Check if two time periods overlap
  bool _hasTimeOverlap(
    DateTime newStart,
    DateTime newEnd,
    DateTime existingStart,
    DateTime existingEnd,
  ) {
    return newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart);
  }

  Widget _buildJobCard(
    RefereeJobModel job,
    user, {
    bool isAvailable = false,
    bool hasConflict = false,
  }) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');
    final sportColor = _getSportColor(job.sport);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  hasConflict
                      ? Colors.amber.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.12),
                  hasConflict
                      ? Colors.amber.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    hasConflict
                        ? Colors.amber.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                // Header with sport badge and status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        sportColor.withValues(alpha: 0.3),
                        sportColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: sportColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SportIcon(
                          sport: job.sport,
                          color: sportColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.sport.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              job.roleDescription,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Earnings badge - prominently displayed in UPM Green
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryGreen,
                              AppTheme.primaryGreenLight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'RM${job.earnings.toInt()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Job details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Date & Time
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.calendar_today,
                            dateFormat.format(job.matchDate),
                          ),
                          const SizedBox(width: 14),
                          _buildInfoChip(
                            Icons.access_time,
                            '${timeFormat.format(job.startTime)} - ${timeFormat.format(job.endTime)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Venue
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoChip(
                              Icons.location_on,
                              job.location.isNotEmpty
                                  ? job.location
                                  : job.facilityName,
                              isFullWidth: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Organizer & Slots
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                AvatarWidget(
                                  photoUrl:
                                      null, // Organizer photo not stored in job model
                                  displayName:
                                      job.organizerName.isNotEmpty
                                          ? job.organizerName
                                          : 'Organizer',
                                  radius: 14,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Organizer',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        job.organizerName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // REFINEMENT: Enhanced multi-referee assignment messaging
                          if (isAvailable && job.needsReferees)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    job.isPartiallyAssigned
                                        ? AppTheme.primaryGreen.withValues(
                                          alpha: 0.15,
                                        )
                                        : AppTheme.warningAmber.withValues(
                                          alpha: 0.2,
                                        ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      job.isPartiallyAssigned
                                          ? AppTheme.primaryGreen.withValues(
                                            alpha: 0.3,
                                          )
                                          : AppTheme.warningAmber.withValues(
                                            alpha: 0.5,
                                          ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    job.isPartiallyAssigned
                                        ? Icons.group_add
                                        : Icons.people,
                                    color:
                                        job.isPartiallyAssigned
                                            ? AppTheme.primaryGreen
                                            : AppTheme.warningAmber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    job.isPartiallyAssigned
                                        ? '${job.assignmentProgress} • Join team!'
                                        : '${job.remainingSlots} slot${job.remainingSlots > 1 ? 's' : ''} needed',
                                    style: TextStyle(
                                      color:
                                          job.isPartiallyAssigned
                                              ? AppTheme.primaryGreen
                                              : AppTheme.warningAmber,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // REFINEMENT: Enhanced status display with assignment context
                      if (!isAvailable) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  job.status,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(job.status),
                                    color: _getStatusColor(job.status),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getEnhancedStatusText(job),
                                    style: TextStyle(
                                      color: _getStatusColor(job.status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Assignment progress for multi-referee jobs
                            if (job.refereesRequired > 1) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Team: ${job.assignmentProgress}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],

                      // Add conflict warning if there's a time conflict
                      if (hasConflict && isAvailable) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                color: Colors.amber.shade200,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '⚠️ Time conflict with your accepted job',
                                  style: TextStyle(
                                    color: Colors.amber.shade200,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Accept button for available jobs
                      if (isAvailable) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: _buildAcceptButton(
                            job,
                            user,
                            hasConflict: hasConflict,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String text, {
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton(
    RefereeJobModel job,
    user, {
    bool hasConflict = false,
  }) {
    final isUserCertified =
        user != null && _userCanOfficiate(job.sport, user.badges ?? []);

    // Show conflict warning if there's a time conflict
    if (hasConflict) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_outlined,
              color: Colors.grey.withValues(alpha: 0.6),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Time Conflict',
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (!isUserCertified) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              color: Colors.white.withValues(alpha: 0.5),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Certification Required',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final isAcceptingThisJob = _acceptingJobId == job.id;

    return GestureDetector(
      onTap:
          (_acceptingJobId != null || hasConflict)
              ? null
              : () => _acceptJob(job, user),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isAcceptingThisJob)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else ...[
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Accept Job',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'RM${job.earnings.toInt()}${_isTournamentJob(job) ? '/match' : '/session'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _acceptJob(RefereeJobModel job, user) async {
    if (user == null || _acceptingJobId != null) return;

    setState(() => _acceptingJobId = job.id);

    try {
      final refereeService = ref.read(refereeServiceProvider);
      final result = await refereeService.applyForJob(
        jobId: job.id,
        referee: user,
      );

      if (mounted) {
        setState(() => _acceptingJobId = null);

        if (result.success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Job Accepted!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'You\'ll earn RM${job.earnings.toInt()} after completion',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          // Refresh providers and wait for data to load
          ref.invalidate(availableJobsProvider);
          ref.invalidate(userRefereeJobsProvider);

          // Wait a moment for Firestore to propagate changes, then switch tab
          await Future.delayed(const Duration(milliseconds: 500));

          // Re-check mounted after async operation
          if (mounted) {
            // Switch to "My Jobs" tab
            _tabController.animateTo(1);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Failed to accept job'),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _acceptingJobId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 48,
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 16),
            Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms, curve: Curves.easeOut)
                .slideY(begin: 0.1, end: 0, duration: 500.ms),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ).animate().fadeIn(
              duration: 500.ms,
              delay: 300.ms,
              curve: Curves.easeOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3, // Show 3 shimmer cards
      itemBuilder:
          (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ShimmerCard(height: 120, borderRadius: 20),
          ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Banner for students without badges to apply to become referees
  Widget _buildBecomeRefereeBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.upmRed.withValues(alpha: 0.2),
                  AppTheme.upmRed.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.upmRed.withValues(alpha: 0.3)),
            ),
            child: InkWell(
              onTap: () => context.go('/referee/apply'),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.upmRed.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.gavel_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Become a Referee',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Apply to earn RM30/match + 3 Merit Points',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.upmRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods
  bool _isTournamentJob(RefereeJobModel job) {
    // Use tolerance-based comparison to handle floating point precision
    return (job.earnings - AppConstants.refereeEarningsTournament).abs() < 0.01;
  }

  bool _isPracticeJob(RefereeJobModel job) {
    // Use tolerance-based comparison to handle floating point precision
    return (job.earnings - AppConstants.refereeEarningsPractice).abs() < 0.01;
  }

  List<RefereeJobModel> _applyJobTypeFilter(List<RefereeJobModel> jobs) {
    switch (_selectedJobTypeFilter) {
      case JobTypeFilter.tournament:
        return jobs.where((job) => _isTournamentJob(job)).toList();
      case JobTypeFilter.practice:
        return jobs.where((job) => _isPracticeJob(job)).toList();
      case JobTypeFilter.all:
        return jobs;
    }
  }

  bool _userCanOfficiate(SportType sport, List<String> badges) {
    final badgeService = ref.read(badgeServiceProvider);
    final user = ref.read(currentUserProvider).valueOrNull;

    if (user == null) return false;

    // Map SportType to sport name for BadgeService
    String sportName;
    switch (sport) {
      case SportType.football:
        sportName = 'football';
        break;
      case SportType.futsal:
        sportName = 'football'; // Futsal uses football badge
        break;
      case SportType.badminton:
        sportName = 'badminton';
        break;
      case SportType.tennis:
        sportName = 'tennis';
        break;
    }

    return badgeService.isCertifiedFor(user, sportName);
  }

  Color _getSportColor(SportType sport) {
    return AppTheme.getSportColorFromType(sport);
  }

  /// Get enhanced status text with additional context
  String _getEnhancedStatusText(RefereeJobModel job) {
    switch (job.status) {
      case JobStatus.open:
        return job.isPartiallyAssigned ? 'Partially assigned' : 'Open';
      case JobStatus.assigned:
        return job.isFullyAssigned ? 'Fully assigned' : 'Your assignment';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.paid:
        return 'Paid';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return AppTheme.warningAmber;
      case JobStatus.assigned:
        return AppTheme.futsalBlue;
      case JobStatus.completed:
        return AppTheme.successGreen;
      case JobStatus.paid:
        return AppTheme.primaryGreen;
      case JobStatus.cancelled:
        return AppTheme.errorRed;
    }
  }

  IconData _getStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return Icons.schedule;
      case JobStatus.assigned:
        return Icons.thumb_up;
      case JobStatus.completed:
        return Icons.check_circle;
      case JobStatus.paid:
        return Icons.payments;
      case JobStatus.cancelled:
        return Icons.cancel;
    }
  }
}

/// Delegate for SliverPersistentHeader to pin the tab bar when scrolling
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _TabBarDelegate({required this.child});

  @override
  double get minExtent => 50;

  @override
  double get maxExtent => 50;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
