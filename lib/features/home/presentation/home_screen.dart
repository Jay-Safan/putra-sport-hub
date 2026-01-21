import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/sport_icon.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/minimalist_loaders.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/offline_indicator.dart';
import '../../../providers/providers.dart';
import '../../../services/weather_service.dart';
import '../../../features/auth/data/models/user_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _allowPointerEvents = false;

  @override
  void initState() {
    super.initState();
    // Delay pointer events until after transition completes (400ms + small buffer)
    // This prevents mouse tracker errors during login-to-home navigation transition
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
    final user = ref.watch(currentUserProvider).valueOrNull;
    final wallet = ref.watch(walletProvider);
    final weather = ref.watch(currentWeatherProvider);
    final activeMode = ref.watch(activeUserModeProvider);
    
    // Redirect admins to admin dashboard
    if (user?.role == UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/admin');
        }
      });
      // Return empty scaffold while redirecting
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }
    
    // Adapt home screen based on active mode
    final isRefereeMode = activeMode == UserMode.referee && user?.isVerifiedReferee == true;

    return Scaffold(
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: IgnorePointer(
              ignoring: !_allowPointerEvents,
              child: Stack(
                children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A1F1A), // Deep dark green
                  Color(0xFF132E25), // Dark teal
                  Color(0xFF1A3D32), // Forest dark
                  Color(0xFF0D1F1A), // Almost black green
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          // Background orbs - non-interactive decorative layer
          IgnorePointer(
            child: _buildBackgroundOrbs(),
          ),
          // Scrollable content - interactive layer
          SafeArea(
            child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header with greeting - Hero entrance
                  SliverToBoxAdapter(
                    child: _buildHeader(context, ref, user)
                        .animate()
                        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                        .slideY(begin: -0.1, end: 0, duration: 500.ms),
                  ),

                  // Weather Widget Pill - Fade in with delay
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildWeatherPill(weather)
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 100.ms, curve: Curves.easeOut)
                          .slideY(begin: 0.1, end: 0, duration: 500.ms),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // SukanPay Wallet Card - Show in all modes
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildWalletCard(context, wallet, user)
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 200.ms, curve: Curves.easeOut)
                          .slideY(begin: 0.15, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // Referee Stats Section - Only in referee mode
                  if (isRefereeMode && user != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildRefereeStatsSection(context, ref, user)
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 300.ms)
                            .slideY(begin: 0.1, end: 0, duration: 500.ms),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],

                  // Enhanced Book Facility Section Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildBookFacilityHeader(context, isRefereeMode)
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 350.ms, curve: Curves.easeOut)
                          .slideX(begin: -0.05, end: 0, duration: 500.ms),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Sport Cards Horizontal Scroll - Only show in non-referee mode
                  if (!isRefereeMode) ...[
                    SliverToBoxAdapter(
                      child: _buildHorizontalSportCards(context)
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 400.ms, curve: Curves.easeOut),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],

                  // Tournament Hub Separator (for STUDENTS only)
                  if (!isRefereeMode && user?.isStudent == true)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildTournamentHubSeparator(context)
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 500.ms, curve: Curves.easeOut)
                            .slideX(begin: -0.05, end: 0, duration: 500.ms),
                      ),
                    ),

                  if (!isRefereeMode && user?.isStudent == true) const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Create Tournament Hero Card (for STUDENTS only) - Premium full-width design
                  if (!isRefereeMode && user?.isStudent == true)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildCreateTournamentHeroCard(context)
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 550.ms, curve: Curves.easeOut)
                            .slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.easeOutCubic)
                            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 600.ms),
                      ),
                    ),

                  if (!isRefereeMode && user?.isStudent == true) const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Quick Actions (mode-aware) - Updated with Join Booking
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildQuickActions(context, ref, user, isRefereeMode)
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 600.ms, curve: Curves.easeOut)
                          .slideY(begin: 0.1, end: 0, duration: 500.ms),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 150)),
                ],
              ),
            ),
                ],
              ),
            ),
            ),
          ],
        ),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        // Top-right green orb - Breathing animation
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
                  AppTheme.primaryGreen.withValues(alpha: 0.3),
                  AppTheme.primaryGreen.withValues(alpha: 0.0),
                ],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 4000.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(duration: 1000.ms),
        ),
        // Bottom-left red orb - Breathing animation
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
                  AppTheme.upmRed.withValues(alpha: 0.2),
                  AppTheme.upmRed.withValues(alpha: 0.0),
                ],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 5000.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(duration: 1200.ms, delay: 200.ms),
        ),
        // Center gold accent - Breathing animation
        Positioned(
          top: 300,
          right: 50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentGold.withValues(alpha: 0.15),
                  AppTheme.accentGold.withValues(alpha: 0.0),
                ],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.25, 1.25),
                duration: 3500.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(duration: 1000.ms, delay: 400.ms),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, UserModel? user) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar with glow
          AvatarWidget.fromUser(
            user: user,
            radius: 24,
            showGlow: true,
            onTap: () => context.go('/profile'),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.displayName ?? 'Welcome',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Notification bell with glassmorphism
          _buildNotificationButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final userId = user?.uid ?? '';
    
    if (userId.isEmpty) {
      return _buildGlassIconButtonAnimated(
        Icons.notifications_outlined,
        onTap: () {},
      );
    }
    
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider(userId));
    
    return unreadCountAsync.when(
      data: (count) => _buildGlassIconButtonAnimated(
        Icons.notifications_outlined,
        onTap: () => context.push('/notifications'),
        badge: count > 0 ? count : null,
      ),
      loading: () => _buildGlassIconButtonAnimated(
        Icons.notifications_outlined,
        onTap: () => context.push('/notifications'),
      ),
      error: (_, __) => _buildGlassIconButtonAnimated(
        Icons.notifications_outlined,
        onTap: () => context.push('/notifications'),
      ),
    );
  }

  Widget _buildWeatherPill(AsyncValue<WeatherResult> weather) {
    return weather.when(
      data: (w) {
        final temp = w.temperature;
        final desc = w.description;
        final weatherIcon = _getWeatherIcon(desc);
        return ProgressiveLoader(
          isLoading: false,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Weather icon with glow (dynamic based on conditions)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: weatherIcon.color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        weatherIcon.icon,
                        color: weatherIcon.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Text(
                          temp != null ? '${temp.round()}°C' : '28°C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          desc.isNotEmpty
                              ? _capitalizeFirst(desc)
                              : 'Partly Cloudy',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // UPM Location indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.primaryGreenLight,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'UPM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
      },
      loading: () => const ShimmerWeatherPill(),
      error: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: const Text(
              '28°C • Good for sports!',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, AsyncValue wallet, user) {
    return wallet.when(
      data: (w) {
        return ProgressiveLoader(
          isLoading: false,
          child: GestureDetector(
          onTap: () => context.push('/wallet'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.accentGold,
                                    Color(0xFFFFE082),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentGold.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Color(0xFF5D4037),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SukanPay',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  user?.isStudent == true
                                      ? 'Student Wallet'
                                      : 'Sports Wallet',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'RM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(w?.balance ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildWalletAction(
                        context,
                        Icons.add_circle_outline,
                        'Top Up',
                        () => context.push('/wallet/topup'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildWalletAction(
                        context,
                        Icons.history_outlined,
                        'History',
                        () => context.push('/wallet'),
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
      },
      loading: () => const ShimmerWalletCard(),
      error: (_, __) => GestureDetector(
        onTap: () => context.push('/wallet'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.accentGold,
                                  Color(0xFFFFE082),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: Color(0xFF5D4037),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SukanPay',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                user?.isStudent == true
                                    ? 'Student Wallet'
                                    : 'Sports Wallet',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Available Balance',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'RM 0.00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildWalletAction(
                          context,
                          Icons.add_circle_outline,
                          'Top Up',
                          () => context.push('/wallet/topup'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildWalletAction(
                          context,
                          Icons.history_outlined,
                          'History',
                          () => context.push('/wallet'),
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

  Widget _buildWalletAction(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryGreenLight,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
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
    );
  }

  Widget _buildHorizontalSportCards(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final footballFacilities = ref.watch(facilitiesBySportProvider(SportType.football));
        final futsalFacilities = ref.watch(facilitiesBySportProvider(SportType.futsal));
        final badmintonFacilities = ref.watch(facilitiesBySportProvider(SportType.badminton));
        final tennisFacilities = ref.watch(facilitiesBySportProvider(SportType.tennis));
        
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 380;
        final horizontalPadding = isSmallScreen ? 16.0 : 20.0;
        final cardGap = isSmallScreen ? 12.0 : 14.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              // Top row: Football and Futsal (2 columns)
              Row(
                children: [
                  Expanded(
                    child: footballFacilities.when(
                      data: (facilities) => _buildCompactSportCard(
                        context,
                        sport: 'Football',
                        sportCode: SportType.football.code,
                        facilityCount: facilities.length,
                        subtitle: facilities.isNotEmpty ? '${facilities.length} Fields' : '6 Fields',
                        price: facilities.isNotEmpty 
                            ? 'From RM${facilities.first.priceStudent.toStringAsFixed(0)}'
                            : 'From RM10',
                        gradient: AppTheme.footballGradient,
                        sportType: SportType.football,
                      ),
                      loading: () => _buildSportCardShimmer(context),
                      error: (_, __) => _buildCompactSportCard(
                        context,
                        sport: 'Football',
                        sportCode: SportType.football.code,
                        facilityCount: 6,
                        subtitle: '6 Fields',
                        price: 'From RM10',
                        gradient: AppTheme.footballGradient,
                        sportType: SportType.football,
                      ),
                    ),
                  ),
                  SizedBox(width: cardGap),
                  Expanded(
                    child: futsalFacilities.when(
                      data: (facilities) => _buildCompactSportCard(
                        context,
                        sport: 'Futsal',
                        sportCode: SportType.futsal.code,
                        facilityCount: facilities.length,
                        subtitle: facilities.isNotEmpty ? '${facilities.length} Courts' : '4 Courts',
                        price: facilities.isNotEmpty 
                            ? 'RM${facilities.first.priceStudent.toStringAsFixed(0)}/session'
                            : 'RM5/session',
                        gradient: AppTheme.futsalGradient,
                        sportType: SportType.futsal,
                      ),
                      loading: () => _buildSportCardShimmer(context),
                      error: (_, __) => _buildCompactSportCard(
                        context,
                        sport: 'Futsal',
                        sportCode: SportType.futsal.code,
                        facilityCount: 4,
                        subtitle: '4 Courts',
                        price: 'RM5/session',
                        gradient: AppTheme.futsalGradient,
                        sportType: SportType.futsal,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: cardGap),
              // Bottom row: Badminton and Tennis (2 columns)
              Row(
                children: [
                  Expanded(
                    child: badmintonFacilities.when(
                      data: (facilities) => _buildCompactSportCard(
                        context,
                        sport: 'Badminton',
                        sportCode: SportType.badminton.code,
                        facilityCount: facilities.length,
                        subtitle: facilities.isNotEmpty 
                            ? '${facilities.isNotEmpty && facilities.first.hasSubUnits ? facilities.first.subUnits.length : 8} Courts'
                            : '8 Courts',
                        price: facilities.isNotEmpty 
                            ? 'RM${facilities.first.priceStudent.toStringAsFixed(0)}/hr'
                            : 'RM3/hr',
                        gradient: AppTheme.badmintonGradient,
                        sportType: SportType.badminton,
                      ),
                      loading: () => _buildSportCardShimmer(context),
                      error: (_, __) => _buildCompactSportCard(
                        context,
                        sport: 'Badminton',
                        sportCode: SportType.badminton.code,
                        facilityCount: 1,
                        subtitle: '8 Courts',
                        price: 'RM3/hr',
                        gradient: AppTheme.badmintonGradient,
                        sportType: SportType.badminton,
                      ),
                    ),
                  ),
                  SizedBox(width: cardGap),
                  Expanded(
                    child: tennisFacilities.when(
                      data: (facilities) => _buildCompactSportCard(
                        context,
                        sport: 'Tennis',
                        sportCode: SportType.tennis.code,
                        facilityCount: facilities.length,
                        subtitle: facilities.isNotEmpty 
                            ? '${facilities.isNotEmpty && facilities.first.hasSubUnits ? facilities.first.subUnits.length : 14} Courts'
                            : '14 Courts',
                        price: facilities.isNotEmpty 
                            ? 'RM${facilities.first.priceStudent.toStringAsFixed(0)}/hr'
                            : 'RM5/hr',
                        gradient: AppTheme.tennisGradient,
                        sportType: SportType.tennis,
                      ),
                      loading: () => _buildSportCardShimmer(context),
                      error: (_, __) => _buildCompactSportCard(
                        context,
                        sport: 'Tennis',
                        sportCode: SportType.tennis.code,
                        facilityCount: 1,
                        subtitle: '14 Courts',
                        price: 'RM5/hr',
                        gradient: AppTheme.tennisGradient,
                        sportType: SportType.tennis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSportCardShimmer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final cardHeight = isSmallScreen ? 150.0 : 160.0;
    
    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      ),
    );
  }

  Widget _buildCompactSportCard(
    BuildContext context, {
    required String sport,
    required String sportCode,
    required int facilityCount,
    required String subtitle,
    required String price,
    required LinearGradient gradient,
    required SportType sportType,
    bool isFullWidth = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: _buildCompactCardContent(
        context,
        sport: sport,
        sportCode: sportCode,
        facilityCount: facilityCount,
        subtitle: subtitle,
        price: price,
        gradient: gradient,
        sportType: sportType,
        isFullWidth: isFullWidth,
      ),
    );
  }
  
  Widget _buildCompactCardContent(
    BuildContext context, {
    required String sport,
    required String sportCode,
    required int facilityCount,
    required String subtitle,
    required String price,
    required LinearGradient gradient,
    required SportType sportType,
    bool isFullWidth = false,
  }) {
    const textColor = Colors.white;
    final primaryColor = gradient.colors.first;
    
    // Responsive sizing based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    
    // Responsive dimensions (consistent across all cards)
    final cardHeight = isSmallScreen ? 165.0 : 170.0; // Increased to prevent overflow
    final cardPadding = isSmallScreen ? 16.0 : 18.0;
    final iconSize = isSmallScreen ? 54.0 : 58.0; // Consistent icon container size
    final iconInnerSize = isSmallScreen ? 28.0 : 30.0; // Consistent inner icon size
    
    // Responsive font sizes
    final sportNameSize = isSmallScreen ? 20.0 : 22.0;
    final subtitleSize = isSmallScreen ? 11.0 : 12.0;
    final priceSize = isSmallScreen ? 12.0 : 13.0;
    final buttonTextSize = isSmallScreen ? 11.0 : 12.0;
    final availabilityTextSize = isSmallScreen ? 9.0 : 10.0;

    return GestureDetector(
      onTap: () => context.push('/booking/sport/$sportCode'),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.0),
                        gradient.colors.last.withValues(alpha: 0.08),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Glassmorphic overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.12),
                            Colors.white.withValues(alpha: 0.03),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Decorative circle (smaller for compact)
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Sport icon (responsive size - centered and balanced)
              Positioned(
                right: cardPadding,
                top: cardPadding,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.25),
                            Colors.white.withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: SportIconFromCode(
                          sportCode: sportCode,
                          color: textColor,
                          size: iconInnerSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Content section (compact layout with responsive sizing)
              Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top section - Sport name and facility info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sport,
                          style: TextStyle(
                            color: textColor,
                            fontSize: sportNameSize,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1.1,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 5 : 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.85),
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 8),
                        // Availability indicator (simplified - always show as available)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 7 : 8,
                            vertical: isSmallScreen ? 3 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: isSmallScreen ? 5 : 6,
                                height: isSmallScreen ? 5 : 6,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent.withValues(alpha: 0.6),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 5 : 6),
                              Text(
                                'Available',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: availabilityTextSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Bottom section - Price and Book Now button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price
                        Flexible(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 9 : 11,
                              vertical: isSmallScreen ? 5 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              price,
                              style: TextStyle(
                                color: textColor,
                                fontSize: priceSize,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        
                        SizedBox(width: isSmallScreen ? 8 : 10),
                        
                        // Book Now button (fixed overflow with Flexible)
                        Flexible(
                          flex: 3,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => context.push('/booking/sport/$sportCode'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 10 : 12,
                                  vertical: isSmallScreen ? 8 : 9,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.3),
                                      Colors.white.withValues(alpha: 0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Book Now',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: buttonTextSize,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 4 : 5),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: textColor,
                                      size: isSmallScreen ? 12 : 13,
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
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
    bool isRefereeMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRefereeMode ? 'Referee Actions' : 'Quick Actions',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        // Different actions based on mode
        if (isRefereeMode) ...[
          // REFEREE MODE: Show referee-focused actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.work_outline,
                  label: 'Available Jobs',
                  color: AppTheme.upmRed,
                  onTap: () => context.go('/referee'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.account_balance_wallet,
                  label: 'Earnings',
                  color: AppTheme.accentGold,
                  onTap: () => context.push('/wallet'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'My Jobs',
                  color: AppTheme.primaryGreen,
                  onTap: () => context.go('/referee'),
                ),
              ),
            ],
          ),
        ] else ...[
          // STUDENT MODE: Show student-focused actions
          // First row: My Bookings (always), Tournaments (students only)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.history,
                    label: 'My Bookings',
                    color: AppTheme.futsalBlue,
                    onTap: () => context.go('/bookings'),
                  ),
                ),
                // Tournaments - Only for students, not public users
                if (user?.isStudent == true) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.emoji_events_outlined,
                      label: 'Tournaments',
                      color: AppTheme.upmRed,
                      onTap: () => context.go('/tournaments'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Second row: Join Tournament, Referee Mode (if available), MyMerit
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Join Tournament - For students (join by code or QR)
                if (user?.isStudent == true) ...[
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.login_rounded,
                      label: 'Join Tournament',
                      color: AppTheme.primaryGreen,
                      onTap: () => context.push('/tournaments/join-by-code'),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                // Become a Referee - For students without badges
                if (user?.isStudent == true && !(user?.isVerifiedReferee ?? false)) ...[
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.gavel_rounded,
                      label: 'Become Referee',
                      color: AppTheme.upmRed,
                      onTap: () => context.push('/referee/apply'),
                      badge: 'New',
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                // MyMerit - Only for students
                if (user?.canEarnMerit == true) ...[
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.stars,
                      label: 'MyMerit',
                      color: AppTheme.accentGold,
                      onTap: () => context.go('/merit'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return AnimatedPressableButton(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else
                  const SizedBox(height: 18), // Spacer to match badge height
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButtonAnimated(IconData icon,
      {VoidCallback? onTap, int? badge}) {
    return AnimatedPressableButton(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
          ),
          if (badge != null && badge > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                padding: badge > 9 
                    ? const EdgeInsets.symmetric(horizontal: 4) 
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: AppTheme.upmRed,
                  shape: badge > 9 ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: badge > 9 ? BorderRadius.circular(9) : null,
                ),
                child: Center(
                  child: Text(
                    badge > 99 ? '99+' : badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Enhanced Book Facility Section Header
  Widget _buildBookFacilityHeader(BuildContext context, bool isRefereeMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.02),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGreen.withValues(alpha: 0.25),
                      AppTheme.primaryGreen.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isRefereeMode ? Icons.gavel_rounded : Icons.sports_soccer_rounded,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRefereeMode ? 'SukanGig Dashboard' : 'Book Facility',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRefereeMode 
                          ? 'Referee marketplace for sports officiating'
                          : 'Select a sport to continue',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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

  /// Enhanced Tournament Hub Separator Section
  Widget _buildTournamentHubSeparator(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.accentGold.withValues(alpha: 0.12),
                AppTheme.accentGold.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.03),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentGold.withValues(alpha: 0.25),
                      AppTheme.accentGold.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppTheme.accentGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tournament Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create competitive matches and invite teams',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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

  /// Premium hero card for Create Tournament - Full width, prominent design
  Widget _buildCreateTournamentHeroCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/tournament/create'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.accentGold.withValues(alpha: 0.3),
                  AppTheme.accentGold.withValues(alpha: 0.15),
                  AppTheme.accentGold.withValues(alpha: 0.08),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Tournament',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Organize competitive matches for your sport',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Build referee stats section for home page (referee mode only)
  Widget _buildRefereeStatsSection(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    final upcomingJobsAsync = ref.watch(upcomingRefereeJobsProvider);
    final allJobsAsync = ref.watch(userRefereeJobsProvider);
    
    return upcomingJobsAsync.when(
      data: (upcomingJobs) => allJobsAsync.when(
        data: (allJobs) {
          // Calculate stats
          final completedJobs = allJobs.where((j) => j.status == JobStatus.completed || j.status == JobStatus.paid).length;
          final totalEarnings = allJobs
              .where((j) => j.status == JobStatus.paid)
              .fold(0.0, (sum, job) => sum + job.earnings);
          
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.upmRed.withValues(alpha: 0.15),
                      AppTheme.upmRed.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.upmRed.withValues(alpha: 0.3),
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
                            color: AppTheme.upmRed.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            color: AppTheme.upmRed,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Referee Stats',
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
                          child: _buildRefereeStatItem(
                            'Upcoming',
                            '${upcomingJobs.length}',
                            Icons.calendar_today,
                            AppTheme.primaryGreen,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        Expanded(
                          child: _buildRefereeStatItem(
                            'Completed',
                            '$completedJobs',
                            Icons.check_circle,
                            AppTheme.successGreen,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        Expanded(
                          child: _buildRefereeStatItem(
                            'Earnings',
                            'RM ${totalEarnings.toStringAsFixed(0)}',
                            Icons.attach_money,
                            AppTheme.accentGold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.upmRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.upmRed),
              ),
            ),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.upmRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.upmRed),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRefereeStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
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
        ),
      ],
    );
  }

  /// Get weather icon and color based on weather description
  ({IconData icon, Color color}) _getWeatherIcon(String description) {
    final desc = description.toLowerCase();
    
    // Thunderstorm
    if (desc.contains('thunderstorm') || desc.contains('storm')) {
      return (
        icon: Icons.thunderstorm_rounded,
        color: Colors.purple,
      );
    }
    
    // Rain
    if (desc.contains('rain') || desc.contains('drizzle') || desc.contains('shower')) {
      return (
        icon: Icons.grain_rounded,
        color: Colors.blue,
      );
    }
    
    // Snow
    if (desc.contains('snow') || desc.contains('sleet')) {
      return (
        icon: Icons.ac_unit_rounded,
        color: Colors.lightBlue,
      );
    }
    
    // Fog/Mist/Haze
    if (desc.contains('fog') || desc.contains('mist') || desc.contains('haze')) {
      return (
        icon: Icons.blur_on_rounded,
        color: Colors.grey,
      );
    }
    
    // Cloudy
    if (desc.contains('cloud') || desc.contains('overcast')) {
      return (
        icon: Icons.cloud_rounded,
        color: Colors.grey.shade400,
      );
    }
    
    // Partly cloudy (few clouds)
    if (desc.contains('few') || desc.contains('scattered')) {
      return (
        icon: Icons.wb_cloudy_rounded,
        color: Colors.grey.shade300,
      );
    }
    
    // Clear/Sunny
    if (desc.contains('clear') || desc.contains('sunny') || desc.contains('fair')) {
      return (
        icon: Icons.wb_sunny_rounded,
        color: Colors.amber,
      );
    }
    
    // Default (unknown/unavailable)
    return (
      icon: Icons.wb_twilight_rounded,
      color: Colors.orange,
    );
  }
}
