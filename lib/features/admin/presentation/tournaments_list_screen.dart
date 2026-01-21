import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../features/tournament/data/models/tournament_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_time_utils.dart';

/// Tournaments management screen for admin
class TournamentsListScreen extends ConsumerStatefulWidget {
  const TournamentsListScreen({super.key});

  @override
  ConsumerState<TournamentsListScreen> createState() => _TournamentsListScreenState();
}

class _TournamentsListScreenState extends ConsumerState<TournamentsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TournamentStatus? _selectedStatusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(adminAllTournamentsProvider);

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
          'Tournaments Management',
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
          child: tournamentsAsync.when(
            data: (tournaments) {
              final filteredTournaments = _filterTournaments(tournaments);
              return Column(
                children: [
                  // Search and filters
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Search bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Search by name or organizer...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear,
                                            color: Colors.white.withValues(alpha: 0.7),
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() => _searchQuery = value);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Status filter chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                label: 'All',
                                isSelected: _selectedStatusFilter == null,
                                onTap: () => setState(() => _selectedStatusFilter = null),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'Registration',
                                isSelected: _selectedStatusFilter == TournamentStatus.registrationOpen,
                                onTap: () => setState(() => _selectedStatusFilter = TournamentStatus.registrationOpen),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'Closed',
                                isSelected: _selectedStatusFilter == TournamentStatus.registrationClosed,
                                onTap: () => setState(() => _selectedStatusFilter = TournamentStatus.registrationClosed),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'In Progress',
                                isSelected: _selectedStatusFilter == TournamentStatus.inProgress,
                                onTap: () => setState(() => _selectedStatusFilter = TournamentStatus.inProgress),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'Completed',
                                isSelected: _selectedStatusFilter == TournamentStatus.completed,
                                onTap: () => setState(() => _selectedStatusFilter = TournamentStatus.completed),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'Cancelled',
                                isSelected: _selectedStatusFilter == TournamentStatus.cancelled,
                                onTap: () => setState(() => _selectedStatusFilter = TournamentStatus.cancelled),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Results count
                        Text(
                          '${filteredTournaments.length} tournament${filteredTournaments.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tournaments list
                  Expanded(
                    child: filteredTournaments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.emoji_events_outlined,
                                  size: 64,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tournaments found',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: filteredTournaments.length,
                            itemBuilder: (context, index) {
                              final tournament = filteredTournaments[index];
                              return _buildTournamentCard(tournament);
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading tournaments',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
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

  List<TournamentModel> _filterTournaments(List<TournamentModel> tournaments) {
    var filtered = tournaments;

    // Filter by status
    if (_selectedStatusFilter != null) {
      filtered = filtered.where((tournament) => tournament.status == _selectedStatusFilter).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((tournament) {
        return tournament.title.toLowerCase().contains(query) ||
            tournament.organizerEmail.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGreen
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentCard(TournamentModel tournament) {
    final statusColor = _getStatusColor(tournament.status);
    final sportColor = _getSportColor(tournament.sport);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: InkWell(
              onTap: () => _showTournamentDetails(tournament),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: sportColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getSportIcon(tournament.sport),
                          color: sportColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tournament.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          tournament.status.displayName,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Date and time
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        DateTimeUtils.formatDate(tournament.startDate),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people_outline, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        '${tournament.teams.length} teams',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Organizer
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          tournament.organizerEmail,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Color _getStatusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.registrationOpen:
        return AppTheme.primaryGreen;
      case TournamentStatus.registrationClosed:
        return AppTheme.warningAmber;
      case TournamentStatus.inProgress:
        return AppTheme.infoBlue;
      case TournamentStatus.completed:
        return AppTheme.successGreen;
      case TournamentStatus.cancelled:
        return AppTheme.errorRed;
    }
  }

  Color _getSportColor(SportType sport) {
    switch (sport) {
      case SportType.football:
        return AppTheme.footballOrange;
      case SportType.futsal:
        return AppTheme.futsalBlue;
      case SportType.badminton:
        return AppTheme.badmintonPurple;
      case SportType.tennis:
        return AppTheme.tennisGreen;
    }
  }

  IconData _getSportIcon(SportType sport) {
    switch (sport) {
      case SportType.football:
        return Icons.sports_soccer_rounded;
      case SportType.futsal:
        return Icons.sports_soccer_rounded;
      case SportType.badminton:
        return Icons.sports_tennis_rounded;
      case SportType.tennis:
        return Icons.sports_tennis_rounded;
    }
  }

  void _showTournamentDetails(TournamentModel tournament) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A3D32),
                    Color(0xFF132E25),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tournament.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(tournament.status).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
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
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        _buildDetailSection(
                          'Sport',
                          tournament.sport.displayName,
                          _getSportIcon(tournament.sport),
                        ),
                        _buildDetailSection(
                          'Start Date',
                          DateTimeUtils.formatDate(tournament.startDate),
                          Icons.calendar_today_outlined,
                        ),
                        _buildDetailSection(
                          'Organizer',
                          tournament.organizerEmail,
                          Icons.person_outline,
                        ),
                        _buildDetailSection(
                          'Teams',
                          '${tournament.teams.length} / ${tournament.maxTeams}',
                          Icons.people_outline,
                        ),
                        const SizedBox(height: 24),
                        // Actions
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              context.push('/tournament/${tournament.id}');
                            },
                            icon: const Icon(Icons.info_outline),
                            label: const Text('View Full Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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