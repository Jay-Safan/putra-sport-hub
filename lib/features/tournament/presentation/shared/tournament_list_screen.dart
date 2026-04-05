import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../../../../../core/constants/app_constants.dart';
import '../../../../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../../../../core/widgets/sport_icon.dart';
import '../../../../../../../../../../core/widgets/shimmer_loading.dart';
import '../../../../../../../../../../core/widgets/animations.dart';
import '../../../../../../../../../../core/utils/error_handler.dart';
import '../../../../../../../../../../providers/providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/tournament_model.dart';

/// Tournament Hub - Discovery screen for browsing tournaments with tabs
class TournamentListScreen extends ConsumerStatefulWidget {
  const TournamentListScreen({super.key});

  @override
  ConsumerState<TournamentListScreen> createState() =>
      _TournamentListScreenState();
}

class _TournamentListScreenState extends ConsumerState<TournamentListScreen> {
  int _selectedTab = 0; // 0: Discover, 1: My Active, 2: History
  SportType? _selectedSportFilter; // null = "All Sports"
  String?
  _selectedRoleFilter; // null = "All", "organizer" = Organizing, "participant" = Participating

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tournament Hub',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (user?.isStudent == true) ...[
            // Join Tournament button - Premium minimalist chip style
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: InkWell(
                onTap: () => context.push('/tournaments/join-by-code'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.futsalBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.futsalBlue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.login_rounded,
                        color: AppTheme.futsalBlue,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Join',
                        style: TextStyle(
                          color: AppTheme.futsalBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryGreen.withValues(alpha: 0.3),
                        AppTheme.primaryGreen.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                onPressed: () => context.push('/tournament/create'),
                tooltip: 'Create Tournament',
              ),
            ),
          ],
        ],
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
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background orbs - ignore pointer events
            IgnorePointer(child: _buildBackgroundOrbs()),
            SafeArea(
              top: true,
              child: Column(
                children: [
                  // Custom tab buttons (fixed at top)
                  Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTabButton(
                                label: 'Discover',
                                icon: Icons.explore,
                                index: 0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTabButton(
                                label: 'My Active',
                                icon: Icons.event_available,
                                index: 1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTabButton(
                                label: 'History',
                                icon: Icons.history,
                                index: 2,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(
                        duration: 500.ms,
                        delay: 100.ms,
                        curve: Curves.easeOut,
                      )
                      .slideY(begin: 0.05, end: 0, duration: 500.ms),
                  // Sticky Sport Filter Bar with CustomScrollView
                  Expanded(child: _buildTabContentWithSlivers(user)),
                ],
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
                      AppTheme.accentGold.withValues(alpha: 0.25),
                      AppTheme.accentGold.withValues(alpha: 0.0),
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
          bottom: 100,
          left: -80,
          child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryGreen.withValues(alpha: 0.15),
                      AppTheme.primaryGreen.withValues(alpha: 0.0),
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
      ],
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required int index,
  }) {
    final isSelected = _selectedTab == index;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedTab = index),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                gradient:
                    isSelected
                        ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryGreen.withValues(alpha: 0.4),
                            AppTheme.primaryGreen.withValues(alpha: 0.3),
                          ],
                        )
                        : LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0.04),
                          ],
                        ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isSelected
                          ? AppTheme.primaryGreen.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.15),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                        : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color:
                        isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color:
                          isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSportFilterChips({
    required SportType? selectedSportFilter,
    required ValueChanged<SportType?> onSportFilterChanged,
    required VoidCallback onClearFilter,
  }) {
    final hasActiveFilter = selectedSportFilter != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // "All Sports" filter chip (text-only, no icon)
                  _buildTextOnlyFilterChip(
                    label: 'All Sports',
                    isSelected: selectedSportFilter == null,
                    onTap: () => onSportFilterChanged(null),
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  // Football filter chip
                  _buildIconFirstFilterChip(
                    label: 'Football',
                    sportType: SportType.football,
                    isSelected: selectedSportFilter == SportType.football,
                    onTap: () => onSportFilterChanged(SportType.football),
                    color: AppTheme.footballOrange,
                  ),
                  const SizedBox(width: 8),
                  // Futsal filter chip
                  _buildIconFirstFilterChip(
                    label: 'Futsal',
                    sportType: SportType.futsal,
                    isSelected: selectedSportFilter == SportType.futsal,
                    onTap: () => onSportFilterChanged(SportType.futsal),
                    color: AppTheme.futsalBlue,
                  ),
                  const SizedBox(width: 8),
                  // Badminton filter chip
                  _buildIconFirstFilterChip(
                    label: 'Badminton',
                    sportType: SportType.badminton,
                    isSelected: selectedSportFilter == SportType.badminton,
                    onTap: () => onSportFilterChanged(SportType.badminton),
                    color: AppTheme.badmintonPurple,
                  ),
                  const SizedBox(width: 8),
                  // Tennis filter chip
                  _buildIconFirstFilterChip(
                    label: 'Tennis',
                    sportType: SportType.tennis,
                    isSelected: selectedSportFilter == SportType.tennis,
                    onTap: () => onSportFilterChanged(SportType.tennis),
                    color: AppTheme.tennisGreen,
                  ),
                ],
              ),
            ),
          ),
          // Clear filter button (only shown when filter is active)
          if (hasActiveFilter) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClearFilter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.close,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Clear',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Icon-first filter chip - shows icon only by default, label appears when selected
  Widget _buildIconFirstFilterChip({
    required String label,
    IconData? icon,
    SportType? sportType,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    // Get sport icon if sportType is provided
    Widget? iconWidget;
    if (sportType != null) {
      iconWidget = SportIcon(
        sport: sportType,
        size: isSelected ? 18 : 16,
        color: isSelected ? color : Colors.white.withValues(alpha: 0.7),
      );
    } else if (icon != null) {
      iconWidget = Icon(
        icon,
        color: isSelected ? color : Colors.white.withValues(alpha: 0.7),
        size: isSelected ? 18 : 16,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: isSelected ? 10 : 8,
        ),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.25),
                      color.withValues(alpha: 0.15),
                    ],
                  )
                  : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.03),
                    ],
                  ),
          borderRadius: BorderRadius.circular(isSelected ? 12 : 20),
          border: Border.all(
            color:
                isSelected
                    ? color.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon - always visible
            if (iconWidget != null) iconWidget,
            // Label - only shown when selected (smooth fade-in)
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Text-only filter chip (no icon) - used for "All Sports"
  Widget _buildTextOnlyFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 14,
          vertical: isSelected ? 10 : 8,
        ),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.25),
                      color.withValues(alpha: 0.15),
                    ],
                  )
                  : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.03),
                    ],
                  ),
          borderRadius: BorderRadius.circular(isSelected ? 12 : 20),
          border: Border.all(
            color:
                isSelected
                    ? color.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  /// Build tab content with CustomScrollView and Slivers
  Widget _buildTabContentWithSlivers(UserModel? user) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh all tournament providers
        ref.invalidate(publicTournamentsProvider);
        ref.invalidate(userTournamentsProvider);
      },
      color: AppTheme.primaryGreen,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Sticky filter header
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyFilterHeaderDelegate(
              selectedSportFilter: _selectedSportFilter,
              onSportFilterChanged: (sport) {
                setState(() {
                  _selectedSportFilter = sport;
                });
              },
              onClearFilter: () {
                setState(() {
                  _selectedSportFilter = null;
                });
              },
              buildFilterChips: _buildSportFilterChips,
            ),
          ),
          // Tournament content based on selected tab
          ..._buildTabSlivers(user),
        ],
      ),
    );
  }

  /// Build slivers for the selected tab
  List<Widget> _buildTabSlivers(UserModel? user) {
    switch (_selectedTab) {
      case 0:
        return _buildDiscoverTabSlivers();
      case 1:
        return _buildMyActiveTabSlivers(user);
      case 2:
        return _buildHistoryTabSlivers(user);
      default:
        return _buildDiscoverTabSlivers();
    }
  }

  /// Build Discover tab slivers
  List<Widget> _buildDiscoverTabSlivers() {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final tournamentsAsync = ref.watch(publicTournamentsProvider);

    return tournamentsAsync.when(
      data: (allTournaments) {
        debugPrint('📊 Discover Tab Filtering');
        debugPrint('   Total tournaments: ${allTournaments.length}');

        var openTournaments =
            allTournaments.where((t) {
              if (_isTournamentPast(t)) return false;
              if (!t.isRegistrationOpen) return false;
              if (user != null && t.isOrganizer(user.uid)) return false;
              return true;
            }).toList();

        debugPrint('   After filters: ${openTournaments.length}');
        if (user != null) {
          debugPrint('   User ID: ${user.uid}');
        }

        openTournaments = _applySportFilter(openTournaments);

        if (openTournaments.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: true,
              child: _buildEmptyState(
                icon: Icons.explore_outlined,
                title:
                    _selectedSportFilter == null
                        ? 'No Tournaments Available'
                        : 'No ${_selectedSportFilter!.displayName} Tournaments',
                message:
                    user == null
                        ? 'Sign in to discover and join tournaments!'
                        : _selectedSportFilter == null
                        ? 'No tournaments are currently open for registration.\n\nCreate your own tournament to get started!'
                        : 'No ${_selectedSportFilter!.displayName.toLowerCase()} tournaments are currently open for registration.',
                showCreateButton: user?.isStudent ?? false,
              ),
            ),
          ];
        }

        // Show tournament list when tournaments exist
        return [_buildTournamentListSlivers(openTournaments, user: user)];
      },
      loading:
          () => [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const ShimmerTournamentCard(),
                  childCount: 3,
                ),
              ),
            ),
          ],
      error:
          (error, stack) => [
            SliverFillRemaining(
              hasScrollBody: true,
              child: _buildErrorState(
                ErrorHandler.getUserFriendlyErrorMessage(
                  error,
                  context: 'tournament',
                  defaultMessage:
                      'Unable to load tournaments. Please try again.',
                ),
              ),
            ),
          ],
    );
  }

  /// Build My Active tab slivers
  List<Widget> _buildMyActiveTabSlivers(UserModel? user) {
    if (user == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: true,
          child: _buildEmptyState(
            icon: Icons.person_outline,
            title: 'Sign In Required',
            message: 'Please sign in to view your tournaments.',
          ),
        ),
      ];
    }

    final tournamentsAsync = ref.watch(userTournamentsProvider);

    return tournamentsAsync.when(
      data: (userTournaments) {
        var activeTournaments =
            userTournaments.where((t) => !_isTournamentPast(t)).toList();

        // Apply role filter
        activeTournaments = _applyRoleFilter(activeTournaments, user.uid);

        // Apply sport filter
        final myTournaments = _applySportFilter(activeTournaments);

        // Always show filter chips, even when empty
        if (myTournaments.isEmpty) {
          return [
            // Keep filter chips visible for user flow
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _buildRoleFilterChips(),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: _buildEmptyState(
                icon: Icons.event_available_outlined,
                title: _getEmptyStateTitle(),
                message: _getEmptyStateMessage(),
                showCreateButton: user.isStudent,
              ),
            ),
          ];
        }

        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildRoleFilterChips(),
            ),
          ),
          _buildTournamentListSlivers(myTournaments, user: user),
        ];
      },
      loading:
          () => [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: ShimmerCard(height: 200, borderRadius: 20),
                  ),
                  childCount: 3,
                ),
              ),
            ),
          ],
      error:
          (error, stack) => [
            SliverFillRemaining(
              hasScrollBody: true,
              child: _buildErrorState(
                ErrorHandler.getUserFriendlyErrorMessage(
                  error,
                  context: 'tournament',
                  defaultMessage:
                      'Unable to load tournaments. Please try again.',
                ),
              ),
            ),
          ],
    );
  }

  /// Build History tab slivers - Only shows "My Past" tournaments (organized or participated)
  List<Widget> _buildHistoryTabSlivers(UserModel? user) {
    if (user == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: true,
          child: _buildEmptyState(
            icon: Icons.person_outline,
            title: 'Sign In Required',
            message: 'Please sign in to view your past tournaments.',
          ),
        ),
      ];
    }

    final tournamentsAsync = ref.watch(userTournamentsProvider);

    return tournamentsAsync.when(
      data: (userTournaments) {
        var myPastTournaments =
            userTournaments.where((t) => _isTournamentPast(t)).toList();
        myPastTournaments = _applySportFilter(myPastTournaments);
        myPastTournaments.sort((a, b) {
          final aDate = a.endDate ?? a.startDate;
          final bDate = b.endDate ?? b.startDate;
          return bDate.compareTo(aDate);
        });

        if (myPastTournaments.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: true,
              child: _buildEmptyState(
                icon: Icons.history_outlined,
                title:
                    _selectedSportFilter == null
                        ? 'No Past Tournaments'
                        : 'No Past ${_selectedSportFilter!.displayName} Tournaments',
                message:
                    _selectedSportFilter == null
                        ? 'You haven\'t participated in any past tournaments yet.'
                        : 'You haven\'t participated in any past ${_selectedSportFilter!.displayName.toLowerCase()} tournaments.',
              ),
            ),
          ];
        }

        return [_buildTournamentListSlivers(myPastTournaments, user: user)];
      },
      loading:
          () => [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const ShimmerTournamentCard(),
                  childCount: 3,
                ),
              ),
            ),
          ],
      error:
          (error, stack) => [
            SliverFillRemaining(
              hasScrollBody: true,
              child: _buildErrorState(
                ErrorHandler.getUserFriendlyErrorMessage(
                  error,
                  context: 'tournament',
                  defaultMessage:
                      'Unable to load tournaments. Please try again.',
                ),
              ),
            ),
          ],
    );
  }

  /// Apply sport filter to tournaments
  List<TournamentModel> _applySportFilter(List<TournamentModel> tournaments) {
    if (_selectedSportFilter == null) {
      return tournaments; // "All Sports" - return all
    }
    return tournaments.where((t) => t.sport == _selectedSportFilter).toList();
  }

  /// Apply role filter to tournaments (organizer or participant)
  List<TournamentModel> _applyRoleFilter(
    List<TournamentModel> tournaments,
    String userId,
  ) {
    if (_selectedRoleFilter == null) {
      return tournaments; // "All" - return all
    }

    if (_selectedRoleFilter == 'organizer') {
      return tournaments.where((t) => t.isOrganizer(userId)).toList();
    }

    if (_selectedRoleFilter == 'participant') {
      return tournaments.where((t) {
        try {
          return t.isUserParticipating(userId) && !t.isOrganizer(userId);
        } catch (e) {
          debugPrint(
            '⚠️ Error checking participation for tournament ${t.id}: $e',
          );
          return false; // Skip tournaments with data issues
        }
      }).toList();
    }

    return tournaments;
  }

  /// Get human-readable label for current role filter
  String _getRoleFilterLabel() {
    switch (_selectedRoleFilter) {
      case 'organizer':
        return 'Organizing';
      case 'participant':
        return 'Participating';
      default:
        return 'All';
    }
  }

  /// Get empty state title based on current filters
  String _getEmptyStateTitle() {
    if (_selectedRoleFilter != null) {
      return 'No ${_getRoleFilterLabel()} Tournaments';
    }

    if (_selectedSportFilter == null) {
      return 'No Active Tournaments';
    }

    return 'No Active ${_selectedSportFilter!.displayName} Tournaments';
  }

  /// Get empty state message based on current filters
  String _getEmptyStateMessage() {
    if (_selectedRoleFilter != null) {
      return 'You don\'t have any active tournaments where you\'re ${_getRoleFilterLabel().toLowerCase()}.\n\nTry changing the filter or create a new tournament!';
    }

    if (_selectedSportFilter == null) {
      return 'You don\'t have any active tournaments. Create one to get started!';
    }

    return 'You don\'t have any active ${_selectedSportFilter!.displayName.toLowerCase()} tournaments.';
  }

  /// Build role filter chips for My Active tab
  Widget _buildRoleFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "All" filter chip (text-only)
          _buildTextOnlyFilterChip(
            label: 'All',
            isSelected: _selectedRoleFilter == null,
            onTap: () => setState(() => _selectedRoleFilter = null),
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 8),
          // "Organizing" filter chip (icon-first)
          _buildIconFirstFilterChip(
            label: 'Organizing',
            icon: Icons.star,
            sportType: null,
            isSelected: _selectedRoleFilter == 'organizer',
            onTap: () => setState(() => _selectedRoleFilter = 'organizer'),
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(width: 8),
          // "Participating" filter chip (icon-first)
          _buildIconFirstFilterChip(
            label: 'Participating',
            icon: Icons.person,
            sportType: null,
            isSelected: _selectedRoleFilter == 'participant',
            onTap: () => setState(() => _selectedRoleFilter = 'participant'),
            color: AppTheme.futsalBlue,
          ),
        ],
      ),
    );
  }

  /// Check if a tournament is finished/past
  /// A tournament is considered past if:
  /// 1. Status is completed or cancelled
  /// 2. Has endDate and it's passed
  /// 3. No endDate but startDate has passed and tournament is not in registration phase
  bool _isTournamentPast(TournamentModel tournament) {
    final now = DateTime.now();

    // Explicitly completed or cancelled
    if (tournament.status == TournamentStatus.completed ||
        tournament.status == TournamentStatus.cancelled) {
      return true;
    }

    // Has endDate and it's passed
    if (tournament.endDate != null && tournament.endDate!.isBefore(now)) {
      return true;
    }

    // No endDate - check if startDate has passed
    // A tournament is considered past if:
    // - StartDate has passed AND
    // - Status is not registrationOpen (either registrationClosed, inProgress, or completed)
    if (tournament.endDate == null) {
      if (tournament.startDate.isBefore(now)) {
        // Tournament has started (or passed)
        // Consider it past if it's not open for registration
        if (tournament.status != TournamentStatus.registrationOpen) {
          // For tournaments that are inProgress or registrationClosed,
          // give them a grace period (24 hours) after startDate
          // This handles single-day tournaments that finish on the same day
          final hoursSinceStart = now.difference(tournament.startDate).inHours;

          if (tournament.status == TournamentStatus.inProgress ||
              tournament.status == TournamentStatus.registrationClosed) {
            // If more than 24 hours passed since start, likely finished
            return hoursSinceStart > 24;
          }

          // For any other non-open status, consider it past
          return true;
        }
      }
    }

    return false;
  }

  // Legacy tab methods removed - using Sliver versions instead

  /// Build sliver list from tournaments
  Widget _buildTournamentListSlivers(
    List<TournamentModel> tournaments, {
    UserModel? user,
  }) {
    if (tournaments.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final tournament = tournaments[index];
          final currentUser = user ?? ref.read(currentUserProvider).valueOrNull;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildTournamentCard(
                  context,
                  tournament,
                  currentUser: currentUser,
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
                ),
          );
        }, childCount: tournaments.length),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    bool showCreateButton = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.4),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms, curve: Curves.easeOut)
                .slideY(begin: 0.1, end: 0, duration: 500.ms),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
              duration: 500.ms,
              delay: 300.ms,
              curve: Curves.easeOut,
            ),
            if (showCreateButton) ...[
              const SizedBox(height: 24),
              AnimatedPressableButton(
                    onTap: () => context.push('/tournament/create'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.accentGold, Color(0xFFFFE082)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Color(0xFF1A3D32), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Create Tournament',
                            style: TextStyle(
                              color: Color(0xFF1A3D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(
                    duration: 500.ms,
                    delay: 400.ms,
                    curve: Curves.easeOut,
                  )
                  .slideY(begin: 0.1, end: 0, duration: 500.ms),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Tournaments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentCard(
    BuildContext context,
    TournamentModel tournament, {
    UserModel? currentUser,
  }) {
    // Determine user's role in this tournament
    String? userRole;
    Color? roleColor;
    if (currentUser != null) {
      if (tournament.isOrganizer(currentUser.uid)) {
        userRole = 'Organizer';
        roleColor = AppTheme.primaryGreen;
      } else if (tournament.isUserParticipating(currentUser.uid)) {
        userRole = 'Player';
        roleColor = AppTheme.futsalBlue;
      } else if (tournament.isUserReferee(currentUser.uid)) {
        userRole = 'Referee';
        roleColor = AppTheme.warningAmber;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () => context.push('/tournament/${tournament.id}'),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getSportColor(tournament.sport),
                                _getSportColor(
                                  tournament.sport,
                                ).withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SportIcon(
                            sport: tournament.sport,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tournament.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getSportColor(
                                        tournament.sport,
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tournament.sport.displayName,
                                      style: TextStyle(
                                        color: _getSportColor(tournament.sport),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // Role badge (Organizer/Participant)
                                  if (userRole != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: roleColor!.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            userRole == 'Organizer'
                                                ? Icons.star
                                                : userRole == 'Player'
                                                ? Icons.groups
                                                : Icons.sports_outlined,
                                            color: roleColor,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            userRole,
                                            style: TextStyle(
                                              color: roleColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (tournament.isRegistrationOpen &&
                                      userRole == null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successGreen.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Open',
                                        style: TextStyle(
                                          color: AppTheme.successGreen,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  // Closing Soon badge
                                  if (tournament.isRegistrationOpen &&
                                      userRole == null) ...[
                                    Builder(
                                      builder: (context) {
                                        final hoursUntilDeadline =
                                            tournament.registrationDeadline
                                                .difference(DateTime.now())
                                                .inHours;

                                        if (hoursUntilDeadline < 24 &&
                                            hoursUntilDeadline > 0) {
                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.warningAmber
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.schedule,
                                                      color:
                                                          AppTheme.warningAmber,
                                                      size: 10,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Closing Soon',
                                                      style: TextStyle(
                                                        color:
                                                            AppTheme
                                                                .warningAmber,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                  // Full badge
                                  if (tournament.isFull &&
                                      userRole == null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.errorRed.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Full',
                                        style: TextStyle(
                                          color: AppTheme.errorRed,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                    if (tournament.description != null &&
                        tournament.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        tournament.description!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.people_outlined,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${tournament.currentTeams}/${tournament.maxTeams} teams',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _formatDate(tournament.startDate),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tournament.venue,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tournament.entryFee != null &&
                            tournament.entryFee! > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'RM ${tournament.entryFee!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppTheme.accentGold,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Free',
                              style: TextStyle(
                                color: AppTheme.successGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getSportColor(SportType sport) {
    return AppTheme.getSportColorFromType(sport);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tournamentDay = DateTime(date.year, date.month, date.day);

    if (tournamentDay == today) {
      return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (tournamentDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Sticky filter header delegate for CustomScrollView
class _StickyFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final SportType? selectedSportFilter;
  final ValueChanged<SportType?> onSportFilterChanged;
  final VoidCallback onClearFilter;
  final Widget Function({
    required SportType? selectedSportFilter,
    required ValueChanged<SportType?> onSportFilterChanged,
    required VoidCallback onClearFilter,
  })
  buildFilterChips;

  _StickyFilterHeaderDelegate({
    required this.selectedSportFilter,
    required this.onSportFilterChanged,
    required this.onClearFilter,
    required this.buildFilterChips,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A1F1A).withValues(alpha: 0.98),
            const Color(0xFF0A1F1A).withValues(alpha: 0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: buildFilterChips(
        selectedSportFilter: selectedSportFilter,
        onSportFilterChanged: onSportFilterChanged,
        onClearFilter: onClearFilter,
      ),
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(_StickyFilterHeaderDelegate oldDelegate) {
    return oldDelegate.selectedSportFilter != selectedSportFilter;
  }
}
