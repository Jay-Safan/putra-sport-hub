import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../../../core/constants/app_constants.dart';
import '../../../../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../../../../core/widgets/sport_icon.dart';
import '../../../../../../../../../../providers/providers.dart';
import '../../data/models/tournament_model.dart';
import '../widgets/tournament_bracket_widget.dart';
import '../../../../features/auth/data/models/user_model.dart';

/// Tournament Detail Screen - Enhanced with modern glassmorphic design
/// Now with TabBar: Info, Teams, Bracket
class TournamentDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final tournamentAsync = ref.watch(tournamentByIdProvider(widget.tournamentId));
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Tournament Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        bottom: tournamentAsync.when(
          data: (tournament) {
            if (tournament == null) return null;
            return TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryGreen,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Info'),
                Tab(text: 'Teams'),
                Tab(text: 'Bracket'),
              ],
            );
          },
          loading: () => null,
          error: (_, __) => null,
        ),
        actions: [
          // Go Home button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              onPressed: () => context.go('/home'),
              tooltip: 'Go Home',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
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
            IgnorePointer(
              child: _buildBackgroundOrbs(),
            ),
            tournamentAsync.when(
              data: (tournament) {
                if (tournament == null) {
                  return Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppTheme.errorRed,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tournament not found',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => context.go('/home'),
                                icon: const Icon(Icons.home),
                                label: const Text('Go Home'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
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

                final isOrganizer =
                    user != null && tournament.isOrganizer(user.uid);
                final isParticipating =
                    user != null && tournament.isUserParticipating(user.uid);
                final canJoin =
                    user != null &&
                    tournament.isRegistrationOpen &&
                    !isParticipating &&
                    !isOrganizer;
                final canUpdateMatches = _canUpdateMatches(user, tournament, ref);

                return SafeArea(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Info
                      _buildInfoTab(context, ref, tournament, isOrganizer, isParticipating, canJoin),
                      // Tab 2: Teams
                      _buildTeamsTab(context, ref, tournament),
                      // Tab 3: Bracket
                      _buildBracketTab(context, ref, tournament, canUpdateMatches),
                    ],
                  ),
                );
              },
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  ),
              error:
                  (error, stack) => Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppTheme.errorRed,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Error loading tournament',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                error.toString(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => context.go('/home'),
                                icon: const Icon(Icons.home),
                                label: const Text('Go Home'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
          top: -100,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.upmRed.withValues(alpha: 0.15),
                  AppTheme.upmRed.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentGold.withValues(alpha: 0.1),
                  AppTheme.accentGold.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeader(TournamentModel tournament) {
    final progressPercent = (tournament.currentTeams / tournament.maxTeams).clamp(0.0, 1.0);
    final sportColor = _getSportColor(tournament.sport);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                sportColor.withValues(alpha: 0.3),
                sportColor.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: sportColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              // Large Sport Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      sportColor,
                      sportColor.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: sportColor.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: SportIcon(
                  sport: tournament.sport,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              
              // Countdown Timer (if registration open)
              if (tournament.isRegistrationOpen)
                _buildCountdownTimer(tournament.registrationDeadline),
              
              if (tournament.isRegistrationOpen)
                const SizedBox(height: 20),
              
              // Team Slots Progress
              _buildSlotsProgressBar(tournament, progressPercent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownTimer(DateTime deadline) {
    return _CountdownTimerWidget(deadline: deadline);
  }

  Widget _buildSlotsProgressBar(TournamentModel tournament, double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Team Slots',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${tournament.currentTeams}/${tournament.maxTeams}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? AppTheme.errorRed : AppTheme.primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tournament.remainingSlots > 0
            ? '${tournament.remainingSlots} slot${tournament.remainingSlots > 1 ? 's' : ''} remaining'
            : 'Tournament is full',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTitleSection(TournamentModel tournament) {
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
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(tournament.status).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getStatusColor(tournament.status).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            tournament.status.displayName,
                            style: TextStyle(
                              color: _getStatusColor(tournament.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (tournament.description != null &&
                  tournament.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  tournament.description!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfoChips(TournamentModel tournament) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          _buildInfoChip(
            icon: Icons.calendar_today,
            label: 'Start',
            value: DateFormat('MMM d').format(tournament.startDate),
            color: AppTheme.accentGold,
          ),
          const SizedBox(width: 12),
          _buildInfoChip(
            icon: Icons.access_time,
            label: 'Time',
            value: DateFormat('h:mm a').format(tournament.startDate),
            color: AppTheme.successGreen,
          ),
          const SizedBox(width: 12),
          _buildInfoChip(
            icon: Icons.location_on,
            label: 'Venue',
            value: tournament.venue,
            color: AppTheme.futsalBlue,
            isLong: true,
          ),
          const SizedBox(width: 12),
          _buildInfoChip(
            icon: Icons.format_list_numbered,
            label: 'Format',
            value: tournament.format.displayName,
            color: AppTheme.badmintonPurple,
          ),
          const SizedBox(width: 12),
          _buildInfoChip(
            icon: tournament.entryFee != null && tournament.entryFee! > 0 
              ? Icons.payment 
              : Icons.free_breakfast,
            label: 'Entry',
            value: tournament.entryFee != null && tournament.entryFee! > 0
              ? 'RM ${tournament.entryFee!.toStringAsFixed(0)}'
              : 'Free',
            color: tournament.entryFee != null && tournament.entryFee! > 0
              ? AppTheme.accentGold
              : AppTheme.successGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLong = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(minWidth: isLong ? 140 : 100),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.25),
                color.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationDeadlineCard(TournamentModel tournament) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.warningAmber.withValues(alpha: 0.15),
                AppTheme.warningAmber.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_busy,
                  color: AppTheme.warningAmber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registration Deadline',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(tournament.registrationDeadline),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsOnlyCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGreenLight.withValues(alpha: 0.15),
                AppTheme.primaryGreenLight.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryGreenLight.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreenLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppTheme.primaryGreenLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Students Only',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Exclusively for UPM students',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildEnhancedTeamsSection(TournamentModel tournament) {
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
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
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
                          AppTheme.futsalBlue,
                          AppTheme.futsalBlue.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registered Teams',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tournament.teams.isEmpty
                            ? 'Be the first team!'
                            : '${tournament.teams.length} of ${tournament.maxTeams} teams',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Team count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tournament.isFull 
                        ? AppTheme.errorRed.withValues(alpha: 0.2)
                        : AppTheme.successGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: tournament.isFull 
                          ? AppTheme.errorRed
                          : AppTheme.successGreen,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${tournament.currentTeams}/${tournament.maxTeams}',
                      style: TextStyle(
                        color: tournament.isFull 
                          ? AppTheme.errorRed 
                          : AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (tournament.teams.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No teams registered yet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...tournament.teams.asMap().entries.map((entry) {
                  final index = entry.key;
                  final team = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < tournament.teams.length - 1 ? 12 : 0,
                    ),
                    child: _buildEnhancedTeamCard(team, index + 1),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTeamCard(dynamic team, int position) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              // Position badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.primaryGreen,
                      AppTheme.primaryGreenLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '#$position',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Team avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentGold,
                      AppTheme.accentGold.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    team.teamName.isNotEmpty
                      ? team.teamName[0].toUpperCase()
                      : 'T',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Team info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.teamName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          team.captainName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.group,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${team.totalMembers}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Payment status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: team.paidEntryFee
                    ? AppTheme.successGreen.withValues(alpha: 0.2)
                    : AppTheme.warningAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: team.paidEntryFee
                      ? AppTheme.successGreen
                      : AppTheme.warningAmber,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      team.paidEntryFee ? Icons.check_circle : Icons.pending,
                      color: team.paidEntryFee
                        ? AppTheme.successGreen
                        : AppTheme.warningAmber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      team.paidEntryFee ? 'Paid' : 'Pending',
                      style: TextStyle(
                        color: team.paidEntryFee
                          ? AppTheme.successGreen
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
        ),
      ),
    );
  }
  

  Widget _buildEnhancedActionButtons(
    BuildContext context,
    WidgetRef ref,
    TournamentModel tournament,
    bool isOrganizer,
    bool isParticipating,
    bool canJoin,
  ) {
    if (isOrganizer) {
      return Column(
        children: [
          // Primary action - Share
          _buildEnhancedActionButton(
            context,
            icon: Icons.share,
            label: 'Share Tournament',
            subtitle: 'Get more teams to join',
            onPressed: () => context.push('/tournament/${tournament.id}/share'),
            color: AppTheme.primaryGreen,
            isPrimary: true,
          ),
          const SizedBox(height: 12),
          
          // Secondary actions row
          Row(
            children: [
              Expanded(
                child: _buildEnhancedActionButton(
                  context,
                  icon: Icons.settings,
                  label: 'Manage',
                  onPressed: () => _showManageTournamentDialog(context, ref, tournament),
                  color: AppTheme.futsalBlue,
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 12),
              if (tournament.status != TournamentStatus.completed &&
                  tournament.status != TournamentStatus.cancelled)
                Expanded(
                  child: _buildEnhancedActionButton(
                    context,
                    icon: Icons.cancel,
                    label: 'Cancel',
                    onPressed: () => _showCancelConfirmation(context, ref, tournament),
                    color: AppTheme.errorRed,
                    isPrimary: false,
                  ),
                ),
            ],
          ),
        ],
      );
    }
    
    if (canJoin) {
      return Column(
        children: [
          _buildEnhancedActionButton(
            context,
            icon: Icons.add_circle,
            label: 'Join Tournament',
            subtitle: tournament.entryFee != null && tournament.entryFee! > 0
              ? 'Pay RM ${tournament.entryFee!.toStringAsFixed(0)} entry fee'
              : 'Free to join',
            onPressed: () => context.push('/tournament/${tournament.id}/join'),
            color: AppTheme.primaryGreen,
            isPrimary: true,
          ),
          const SizedBox(height: 12),
          _buildJoinInfoRow(tournament),
        ],
      );
    }
    
    if (isParticipating) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.successGreen.withValues(alpha: 0.2),
                  AppTheme.successGreen.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You\'re Registered!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Check back for updates',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (!tournament.isRegistrationOpen) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Registration Closed',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildEnhancedActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onPressed,
    required Color color,
    required bool isPrimary,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(subtitle != null ? 20 : 18),
              decoration: BoxDecoration(
                gradient: isPrimary
                  ? LinearGradient(
                      colors: [color, color.withValues(alpha: 0.8)],
                    )
                  : null,
                color: isPrimary ? null : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPrimary 
                    ? color.withValues(alpha: 0.3)
                    : color.withValues(alpha: 0.4),
                  width: isPrimary ? 0 : 1.5,
                ),
                boxShadow: isPrimary ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ] : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isPrimary ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinInfoRow(TournamentModel tournament) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Registration closes ${_formatDateTime(tournament.registrationDeadline)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }

  Color _getStatusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.registrationOpen:
        return AppTheme.successGreen;
      case TournamentStatus.registrationClosed:
        return AppTheme.warningAmber;
      case TournamentStatus.inProgress:
        return AppTheme.primaryGreen;
      case TournamentStatus.completed:
        return AppTheme.accentGold;
      case TournamentStatus.cancelled:
        return AppTheme.errorRed;
    }
  }

  Color _getSportColor(SportType sport) {
    return AppTheme.getSportColorFromType(sport);
  }


  void _showManageTournamentDialog(
    BuildContext context,
    WidgetRef ref,
    TournamentModel tournament,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A3D32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Manage Tournament',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // View Participants and Edit Tournament - hidden for demo (coming in v1.1)
                if (tournament.status != TournamentStatus.completed &&
                    tournament.status != TournamentStatus.cancelled)
                  ListTile(
                    leading: const Icon(
                      Icons.cancel_outlined,
                      color: AppTheme.errorRed,
                    ),
                    title: const Text(
                      'Cancel Tournament',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showCancelConfirmation(context, ref, tournament);
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
    );
  }

  void _showCancelConfirmation(
    BuildContext context,
    WidgetRef ref,
    TournamentModel tournament,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A3D32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.errorRed,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cancel Tournament?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to cancel "${tournament.title}"?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This will:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCancelReasonItem(
                  'Mark the tournament as cancelled',
                  Icons.block,
                ),
                if (tournament.currentTeams > 0)
                  _buildCancelReasonItem(
                    'Notify ${tournament.currentTeams} registered team${tournament.currentTeams > 1 ? 's' : ''}',
                    Icons.people_outline,
                  ),
                _buildCancelReasonItem(
                  'Remove it from active tournament listings',
                  Icons.visibility_off,
                ),
                const SizedBox(height: 12),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    color: AppTheme.errorRed.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Keep Tournament',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _handleCancelTournament(context, ref, tournament);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel Tournament'),
              ),
            ],
          ),
    );
  }

  Widget _buildCancelReasonItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelTournament(
    BuildContext context,
    WidgetRef ref,
    TournamentModel tournament,
  ) async {
    // Show loading overlay
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryGreen),
                      SizedBox(height: 16),
                      Text(
                        'Cancelling tournament...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );

    try {
      final tournamentService = ref.read(tournamentServiceProvider);
      final result = await tournamentService.cancelTournament(
        tournamentId: tournament.id,
        reason: 'Cancelled by organizer',
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (result.success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Tournament cancelled successfully')),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            context.pop(); // Go back to previous screen
          }
        });
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.errorMessage ?? 'Failed to cancel tournament',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: ${e.toString()}')),
            ],
          ),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB BUILDER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tab 1: Info Tab - Tournament details and actions
  Widget _buildInfoTab(
    BuildContext context,
    WidgetRef ref,
    TournamentModel tournament,
    bool isOrganizer,
    bool isParticipating,
    bool canJoin,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // 1. Hero Header with Countdown & Progress
          _buildHeroHeader(tournament),
          const SizedBox(height: 24),

          // 2. Compact Title Section
          _buildCompactTitleSection(tournament),
          const SizedBox(height: 20),

          // 3. Quick Info Chips (Horizontal Scroll)
          _buildQuickInfoChips(tournament),
          const SizedBox(height: 24),

          // 4. Registration Deadline Card (if open)
          if (tournament.isRegistrationOpen)
            _buildRegistrationDeadlineCard(tournament),
          if (tournament.isRegistrationOpen)
            const SizedBox(height: 20),

          // 4.5. Students Only Info Card
          _buildStudentsOnlyCard(),
          const SizedBox(height: 20),

          // 5. Action Buttons (Enhanced)
          _buildEnhancedActionButtons(
            context,
            ref,
            tournament,
            isOrganizer,
            isParticipating,
            canJoin,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  /// Tab 2: Teams Tab - Registered teams list
  Widget _buildTeamsTab(
    BuildContext context,
    WidgetRef ref,
    TournamentModel tournament,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildEnhancedTeamsSection(tournament),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  /// Tab 3: Bracket Tab - Tournament bracket view
  Widget _buildBracketTab(
    BuildContext context,
    WidgetRef ref,
    TournamentModel tournament,
    bool canUpdate,
  ) {
    return TournamentBracketWidget(
      tournament: tournament,
      canUpdate: canUpdate,
    );
  }

  /// Check if user can update match results (referee permission)
  /// Simplified: Any verified referee can update matches for tournaments with referee jobs
  bool _canUpdateMatches(UserModel? user, TournamentModel tournament, WidgetRef ref) {
    if (user == null) return false;
    
    // Only verified referees can update matches
    if (!user.isVerifiedReferee) return false;

    // Check if tournament has referee jobs
    if (tournament.refereeJobIds.isEmpty) return false;

    // For now, any verified referee can update matches
    // In production, you might want to check if user is specifically assigned
    // For simplicity, we allow any verified referee to update matches
    return true;
  }
}

/// Countdown timer widget that properly manages Timer lifecycle
class _CountdownTimerWidget extends StatefulWidget {
  final DateTime deadline;

  const _CountdownTimerWidget({required this.deadline});

  @override
  State<_CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<_CountdownTimerWidget> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final difference = widget.deadline.difference(_now);
    
    if (difference.isNegative) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_off, color: AppTheme.errorRed, size: 18),
            SizedBox(width: 8),
            Text(
              'Registration Closed',
              style: TextStyle(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }
    
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warningAmber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, color: AppTheme.warningAmber, size: 18),
          const SizedBox(width: 8),
          Text(
            days > 0 
              ? '$days d ${hours}h left'
              : hours > 0
                ? '$hours h ${minutes}m left'
                : '$minutes m left',
            style: const TextStyle(
              color: AppTheme.warningAmber,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
