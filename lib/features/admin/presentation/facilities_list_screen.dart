import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../features/booking/data/models/facility_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/seed_service.dart';

/// Facilities management screen for admin
class FacilitiesListScreen extends ConsumerStatefulWidget {
  const FacilitiesListScreen({super.key});

  @override
  ConsumerState<FacilitiesListScreen> createState() => _FacilitiesListScreenState();
}

class _FacilitiesListScreenState extends ConsumerState<FacilitiesListScreen> {
  bool _isReseeding = false;
  SportType? _selectedSport; // null = All Sports

  Future<void> _reseedFacilities() async {
    setState(() => _isReseeding = true);

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
              'Re-seeding facilities...',
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
      // Clear old facilities first, then seed new ones
      await seedService.seedFacilities(clearFirst: true);

      // Invalidate provider to refresh the list
      ref.invalidate(facilitiesProvider);

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
                  '✅ Facilities re-seeded successfully! Updated with new facilities and pricing.',
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
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isReseeding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final facilitiesAsync = ref.watch(facilitiesProvider);

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
          'Facilities Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isReseeding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryGreen,
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.white, size: 18),
            ),
            onPressed: _isReseeding ? null : _reseedFacilities,
            tooltip: 'Re-seed Facilities',
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
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Sport Filter Bar
              _buildSportFilterBar(),
              
              // Facilities List
              Expanded(
                child: facilitiesAsync.when(
                  data: (facilities) {
                    // Filter facilities by selected sport
                    final filteredFacilities = _selectedSport == null
                        ? facilities
                        : facilities.where((f) => f.sport == _selectedSport).toList();
                    
                    return filteredFacilities.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
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
                                      Icons.sports_soccer_outlined,
                                      size: 48,
                                      color: Colors.white.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _selectedSport == null
                                        ? 'No Facilities Found 🏟️'
                                        : 'No ${_selectedSport!.displayName} Facilities Found',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedSport == null
                                        ? 'No facilities are available. Use the "Re-seed Facilities" button to populate facilities.'
                                        : 'No ${_selectedSport!.displayName.toLowerCase()} facilities available. Try selecting a different sport filter or re-seed facilities.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: filteredFacilities.length,
                            itemBuilder: (context, index) {
                              final facility = filteredFacilities[index];
                              return _buildFacilityCard(facility);
                            },
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
                          'Error loading facilities',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSportFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // All Sports filter
            _buildFilterChip(
              label: 'All Sports',
              icon: Icons.filter_list_rounded,
              isSelected: _selectedSport == null,
              color: Colors.white,
              onTap: () {
                setState(() => _selectedSport = null);
              },
            ),
            const SizedBox(width: 12),
            // Football filter
            _buildFilterChip(
              label: 'Football',
              icon: Icons.sports_soccer_rounded,
              isSelected: _selectedSport == SportType.football,
              color: AppTheme.footballOrange,
              onTap: () {
                setState(() => _selectedSport = SportType.football);
              },
            ),
            const SizedBox(width: 12),
            // Futsal filter
            _buildFilterChip(
              label: 'Futsal',
              icon: Icons.sports_soccer_rounded,
              isSelected: _selectedSport == SportType.futsal,
              color: AppTheme.futsalBlue,
              onTap: () {
                setState(() => _selectedSport = SportType.futsal);
              },
            ),
            const SizedBox(width: 12),
            // Badminton filter
            _buildFilterChip(
              label: 'Badminton',
              icon: Icons.sports_tennis_rounded,
              isSelected: _selectedSport == SportType.badminton,
              color: AppTheme.badmintonPurple,
              onTap: () {
                setState(() => _selectedSport = SportType.badminton);
              },
            ),
            const SizedBox(width: 12),
            // Tennis filter
            _buildFilterChip(
              label: 'Tennis',
              icon: Icons.sports_tennis_rounded,
              isSelected: _selectedSport == SportType.tennis,
              color: AppTheme.tennisGreen,
              onTap: () {
                setState(() => _selectedSport = SportType.tennis);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    // For "All Sports", use a light neutral color
    final chipColor = label == 'All Sports' 
        ? Colors.white.withValues(alpha: 0.15)
        : color.withValues(alpha: 0.25); // Lighter, more glassy color
    
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        chipColor.withValues(alpha: 0.4), // Very light glassy color
                        chipColor.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    )
                  : null,
              color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? chipColor.withValues(alpha: 0.5) // Lighter border
                    : Colors.white.withValues(alpha: 0.2),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: chipColor.withValues(alpha: 0.2), // Lighter shadow
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected 
                      ? (label == 'All Sports' ? Colors.white : color.withValues(alpha: 0.9))
                      : color.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    shadows: isSelected
                        ? [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityCard(FacilityModel facility) {
    final sportColor = _getSportColor(facility.sport);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sportColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getSportIcon(facility.sport),
                        color: sportColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        facility.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: facility.isActive
                            ? AppTheme.successGreen.withValues(alpha: 0.2)
                            : AppTheme.errorRed.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        facility.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: facility.isActive ? AppTheme.successGreen : AppTheme.errorRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: sportColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        facility.sport.displayName,
                        style: TextStyle(
                          color: sportColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        facility.type.displayName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Student: RM ${facility.priceStudent.toStringAsFixed(2)}${facility.type == FacilityType.session ? '/session' : '/hr'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Public: RM ${facility.pricePublic.toStringAsFixed(2)}${facility.type == FacilityType.session ? '/session' : '/hr'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
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
    );
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
}