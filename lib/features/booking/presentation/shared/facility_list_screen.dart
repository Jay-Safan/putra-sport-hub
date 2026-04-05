import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../../../core/constants/app_constants.dart';
import '../../../../../../../../../core/widgets/sport_icon.dart';
import '../../../../../../../../../core/widgets/shimmer_loading.dart';
import '../../../../../../../../../providers/providers.dart';
import '../../data/models/facility_model.dart';

class FacilityListScreen extends ConsumerWidget {
  final String sportCode;

  const FacilityListScreen({super.key, required this.sportCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sport = SportType.fromCode(sportCode);
    final facilitiesAsync = ref.watch(facilitiesBySportProvider(sport));
    final isStudent = ref.watch(isStudentProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _buildBackButton(context),
        title: Text(
          sport.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
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
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundOrbs(sportCode),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  // Hero Header
                  SliverToBoxAdapter(child: _buildHeroHeader(context, sport)),

                  // Sport Info Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSportInfo(context, sportCode),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Price Tier Badge
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildPriceTierBadge(isStudent),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Facilities List
                  facilitiesAsync.when(
                    data: (facilities) {
                      if (facilities.isEmpty) {
                        return SliverFillRemaining(
                          child: _buildEmptyState(sport),
                        );
                      }

                      // For Football: Show Stadium UPM first, then other fields
                      if (sport == SportType.football) {
                        final stadiumFacilities =
                            facilities
                                .where((f) => f.id.contains('stadium'))
                                .toList();
                        final otherFacilities =
                            facilities
                                .where((f) => !f.id.contains('stadium'))
                                .toList();

                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              // Stadium UPM first
                              ...stadiumFacilities.map(
                                (facility) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildFacilityCard(
                                    context,
                                    facility,
                                    isStudent,
                                  ),
                                ),
                              ),
                              // Other fields below
                              ...otherFacilities.map(
                                (facility) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildFacilityCard(
                                    context,
                                    facility,
                                    isStudent,
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        );
                      }

                      // For other sports: Show all facilities normally
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final facility = facilities[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildFacilityCard(
                                context,
                                facility,
                                isStudent,
                              ),
                            );
                          }, childCount: facilities.length),
                        ),
                      );
                    },
                    loading:
                        () => SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: ShimmerSportCard(),
                              ),
                              childCount: 3, // Show 3 shimmer cards
                            ),
                          ),
                        ),
                    error:
                        (e, _) => SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'Error: $e',
                              style: const TextStyle(color: AppTheme.errorRed),
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

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundOrbs(String sportCode) {
    final sportColor = AppTheme.getSportColor(sportCode);
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  sportColor.withValues(alpha: 0.3),
                  sportColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
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
                  AppTheme.primaryGreen.withValues(alpha: 0.2),
                  AppTheme.primaryGreen.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context, SportType sport) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: ClipRRect(
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
                  AppTheme.getSportColor(sport.code).withValues(alpha: 0.3),
                  AppTheme.getSportColor(sport.code).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.getSportColor(
                          sport.code,
                        ).withValues(alpha: 0.3),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: SportIconFromCode(
                    sportCode: sport.code,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sport.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose your facility',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
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
    );
  }

  Widget _buildPriceTierBadge(bool isStudent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                isStudent
                    ? AppTheme.successGreen.withValues(alpha: 0.15)
                    : AppTheme.warningAmber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isStudent
                      ? AppTheme.successGreen.withValues(alpha: 0.3)
                      : AppTheme.warningAmber.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isStudent
                          ? AppTheme.successGreen
                          : AppTheme.warningAmber)
                      .withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isStudent ? Icons.verified : Icons.info_outline,
                  color:
                      isStudent ? AppTheme.successGreen : AppTheme.warningAmber,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStudent
                          ? 'Student prices applied! You\'re getting subsidized rates.'
                          : 'Public rate - Full price',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isStudent) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Sign in with @student.upm.edu.my for student discounts',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
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
    );
  }

  Widget _buildFacilityCard(
    BuildContext context,
    FacilityModel facility,
    bool isStudent,
  ) {
    final sportColor = AppTheme.getSportColor(facility.sport.code);
    final priceLabel = facility.getPriceLabel(isStudent);

    return GestureDetector(
      onTap: () => context.push('/booking/facility/${facility.id}'),
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFacilityHero(facility, sportColor, priceLabel),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildTag(
                            facility.isIndoor ? 'Indoor' : 'Outdoor',
                            facility.isIndoor
                                ? AppTheme.infoBlue
                                : AppTheme.warningAmber,
                          ),
                          const SizedBox(width: 8),
                          _buildTag(facility.type.displayName, sportColor),
                          if (facility.hasSubUnits) ...[
                            const SizedBox(width: 8),
                            _buildTag(
                              '${facility.subUnits.length} courts',
                              AppTheme.primaryGreenLight,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (facility.description.isNotEmpty)
                        Text(
                          facility.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              priceLabel,
                              style: const TextStyle(
                                color: AppTheme.primaryGreenLight,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryGreen,
                                  AppTheme.primaryGreenLight,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGreen.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap:
                                    () => context.push(
                                      '/booking/facility/${facility.id}',
                                    ),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Book Now',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFacilityHero(
    FacilityModel facility,
    Color sportColor,
    String priceLabel,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: _buildFacilityImage(facility, sportColor),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SportIconFromCode(
                          sportCode: facility.sport.code,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          facility.type.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      priceLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facility.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildTag(
                        facility.isIndoor ? 'Indoor' : 'Outdoor',
                        facility.isIndoor
                            ? AppTheme.infoBlue
                            : AppTheme.warningAmber,
                      ),
                      const SizedBox(width: 8),
                      if (facility.hasSubUnits)
                        _buildTag(
                          '${facility.subUnits.length} courts',
                          AppTheme.primaryGreenLight,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityImage(FacilityModel facility, Color sportColor) {
    final url = facility.imageAssetPath;

    if (url != null && url.isNotEmpty) {
      return Image.asset(url, fit: BoxFit.cover);
    }

    return _buildImagePlaceholder(facility, sportColor);
  }

  Widget _buildImagePlaceholder(FacilityModel facility, Color sportColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            sportColor.withValues(alpha: 0.35),
            AppTheme.primaryGreen.withValues(alpha: 0.25),
            Colors.black.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: SportIconFromCode(
            sportCode: facility.sport.code,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(SportType sport) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'No Facilities Available',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no ${sport.displayName} facilities available at the moment.',
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

  Widget _buildSportInfo(BuildContext context, String sportCode) {
    String title;
    String description;
    List<String> features;

    switch (sportCode) {
      case 'FOOTBALL':
        title = 'Football at UPM';
        description =
            'Book Stadium UPM for major matches or training fields (Padang A-E) near residential colleges.';
        features = [
          '2-hour sessions with natural grass',
          'FIFA-standard Stadium + 5 training fields',
          'Professional floodlighting for evening play',
        ];
        break;
      case 'FUTSAL':
        title = 'Futsal Court';
        description =
            'Play at KMR outdoor futsal court with concrete surface and floodlights.';
        features = [
          '2-hour sessions per booking',
          'Outdoor court with concrete surface',
          'Popular for inter-college tournaments',
        ];
        break;
      case 'BADMINTON':
        title = 'Badminton Courts';
        description =
            'Play at Dewan Serbaguna with 8 professional courts, air-conditioned facility.';
        features = [
          'Hourly bookings available',
          'BWF-standard lighting & wooden flooring',
          'Air-conditioned multi-purpose hall',
        ];
        break;
      case 'TENNIS':
        title = 'Tennis Courts';
        description =
            'Play at UPM Tennis Complex with 14 ITF-standard hard courts and parking.';
        features = [
          'Hourly bookings (max 2 hours)',
          'Acrylic surface with professional lighting',
          'Evening play available with floodlights',
        ];
        break;
      default:
        return const SizedBox();
    }

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
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ...features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.getSportColor(
                            sportCode,
                          ).withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: AppTheme.getSportColor(sportCode),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
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
            ],
          ),
        ),
      ),
    );
  }
}
