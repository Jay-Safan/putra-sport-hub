import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../../providers/providers.dart' show splashStartTimeProvider, authStateProvider, currentUserProvider, isUpdatingProfileProvider;

/// Modern minimalist loader widget with glassmorphic design
/// Can be used as overlay or full-screen loader
class ModernLoader extends StatefulWidget {
  final String? message;
  final bool fullScreen;
  final Color? backgroundColor;

  const ModernLoader({
    super.key,
    this.message,
    this.fullScreen = false,
    this.backgroundColor,
  });

  @override
  State<ModernLoader> createState() => _ModernLoaderState();
}

class _ModernLoaderState extends State<ModernLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.5,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.3)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.5,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glassmorphic container with animated spinner
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return SizedBox(
                      width: 70,
                      height: 70,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Main rotating circular progress indicator
                          SizedBox(
                            width: 70,
                            height: 70,
                            child: CircularProgressIndicator(
                              value: null, // Indeterminate
                              strokeWidth: 4.5,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryGreen,
                              ),
                              backgroundColor: AppTheme.primaryGreen
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          // Inner rotating accent ring
                          Transform.rotate(
                            angle: _rotationAnimation.value * 2 * math.pi * 1.5,
                            child: const SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                value: 0.3, // Partial progress
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.accentGold,
                                ),
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ),
                          // Center pulsing dot
                          Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    AppTheme.primaryGreen,
                                    AppTheme.primaryGreenLight,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: _fadeAnimation.value * 0.8),
                                    blurRadius: 12 * _fadeAnimation.value,
                                    spreadRadius: 3 * _fadeAnimation.value,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Message text
          if (widget.message != null) ...[
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Text(
                    widget.message!,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );

    if (widget.fullScreen) {
      return Container(
        decoration: BoxDecoration(
          gradient: widget.backgroundColor != null
              ? null
              : const LinearGradient(
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
          color: widget.backgroundColor,
        ),
        child: SafeArea(child: content),
      );
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: content,
      ),
    );
  }
}

/// Loading overlay widget with modern loader
class ModernLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final bool barrierDismissible;

  const ModernLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.barrierDismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: GestureDetector(
              onTap: barrierDismissible ? () {} : null,
              child: ModernLoader(message: message),
            ),
          ),
      ],
    );
  }
}

/// Full-screen loader for splash screens or initial app loading
/// Enhanced with smooth animations and impressive visuals
class SplashLoader extends ConsumerStatefulWidget {
  final String? message;
  final Widget? logo;
  final Duration? minimumDisplayDuration;

  const SplashLoader({
    super.key,
    this.message,
    this.logo,
    this.minimumDisplayDuration = const Duration(milliseconds: 300),
  });

  @override
  ConsumerState<SplashLoader> createState() => _SplashLoaderState();
}

class _SplashLoaderState extends ConsumerState<SplashLoader>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _logoRotation;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;
  DateTime? _startTime;

  /// Navigate to the appropriate screen after splash
  void _navigateToNextScreen() {
    if (!mounted) return;
    
    // CRITICAL: Check if profile is being updated - if so, block all navigation
    // This prevents splash from interfering during profile picture upload/removal
    final isUpdatingProfile = ref.read(isUpdatingProfileProvider);
    if (isUpdatingProfile) {
      debugPrint('⚠️ Splash navigation blocked - profile update in progress - aborting');
      return; // Block all navigation during profile update
    }
    
    // CRITICAL: FIRST CHECK - if we're not on /splash, DO NOTHING
    // This must be the absolute first check to prevent any navigation interference
    // This prevents splash from running during profile picture upload/removal or any other operation
    try {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
        
        // Never navigate if we're not on splash - this prevents interference with any screen
        // Especially important for /profile during photo upload/removal
        if (currentLocation != '/splash') {
          debugPrint('⚠️ Splash navigation blocked - not on /splash route ($currentLocation) - aborting all navigation');
          return; // Exit immediately - don't do anything else
        }
      } else {
        // No router available - don't navigate to be safe
        debugPrint('⚠️ Splash navigation blocked - no router available - aborting');
        return;
      }
    } catch (e) {
      // Any error checking route - don't navigate to be safe
      debugPrint('⚠️ Splash navigation blocked - error checking route: $e - aborting');
      return;
    }
    
    // Only proceed if we're definitely on /splash route
    
    final authState = ref.read(authStateProvider);
    final hasFirebaseAuth = authState.valueOrNull != null;
    
    if (!hasFirebaseAuth) {
      // No user - go to login
      final elapsed = DateTime.now().difference(_startTime!);
      debugPrint('✅ Splash complete - Navigating to /login (not logged in) - Total: ${elapsed.inMilliseconds}ms');
      context.go('/login');
      return;
    }
    
    // Check if Firestore user document exists
    final currentUser = ref.read(currentUserProvider);
    if (currentUser.isLoading) {
      // Still loading - wait a bit more then proceed
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        
        // CRITICAL: Check if profile is being updated - block navigation
        final isUpdatingProfile = ref.read(isUpdatingProfileProvider);
        if (isUpdatingProfile) {
          debugPrint('⚠️ Splash delayed navigation blocked - profile update in progress - aborting');
          return;
        }
        
        // CRITICAL: Check current route before navigating - must still be on /splash
        try {
          final router = GoRouter.maybeOf(context);
          if (router != null) {
            final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
            
            // If we're not on splash anymore, don't navigate (user might be on /profile uploading photo)
            if (currentLocation != '/splash') {
              debugPrint('⚠️ Splash delayed navigation blocked - not on /splash ($currentLocation) - aborting');
              return;
            }
          } else {
            debugPrint('⚠️ Splash delayed navigation blocked - no router - aborting');
            return;
          }
        } catch (e) {
          debugPrint('⚠️ Splash delayed navigation blocked - error: $e - aborting');
          return;
        }
        
        final userDoc = ref.read(currentUserProvider).valueOrNull;
        final elapsed = DateTime.now().difference(_startTime!);
        if (userDoc != null) {
          debugPrint('✅ Splash complete - Navigating to /home (logged in) - Total: ${elapsed.inMilliseconds}ms');
          context.go('/home');
        } else {
          debugPrint('✅ Splash complete - Navigating to /login (no Firestore doc) - Total: ${elapsed.inMilliseconds}ms');
          context.go('/login');
        }
      });
      return;
    }
    
    // User document loaded - check route again before navigating (final safety check)
    try {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
        
        // Final check: must still be on /splash to navigate
        if (currentLocation != '/splash') {
          debugPrint('⚠️ Splash final navigation blocked - not on /splash ($currentLocation) - aborting');
          return;
        }
      } else {
        debugPrint('⚠️ Splash final navigation blocked - no router - aborting');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Splash final navigation blocked - error: $e - aborting');
      return;
    }
    
    final userDoc = currentUser.valueOrNull;
    final elapsed = DateTime.now().difference(_startTime!);
    if (userDoc != null) {
      debugPrint('✅ Splash complete - Navigating to /home (logged in) - Total: ${elapsed.inMilliseconds}ms');
      context.go('/home');
    } else {
      debugPrint('✅ Splash complete - Navigating to /login (no Firestore doc) - Total: ${elapsed.inMilliseconds}ms');
      context.go('/login');
    }
  }

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    
    // CRITICAL: Check route BEFORE doing anything - exit immediately if not on /splash
    // This prevents splash logic from running when app resumes from background
    // or when router rebuilds during profile picture upload/removal
    Future.microtask(() {
      if (!mounted) return;
      
      // First check: Are we actually on /splash? If not, exit immediately
      try {
        final router = GoRouter.maybeOf(context);
        if (router != null) {
          final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
          // If we're not on splash route, abort all splash logic immediately
          // This prevents interference with profile screen during photo upload/removal
          if (currentLocation != '/splash') {
            debugPrint('ℹ️ SplashLoader mounted but not on /splash ($currentLocation) - aborting all splash logic');
            return; // Don't set timers, don't schedule navigation, just exit
          }
        } else {
          debugPrint('ℹ️ SplashLoader mounted but no router - aborting splash logic');
          return;
        }
      } catch (e) {
        debugPrint('ℹ️ SplashLoader can\'t check route - aborting: $e');
        return;
      }
      
      // Only proceed if we're definitely on /splash route
      // Set splash start time immediately (don't wait for frame)
      final currentTime = ref.read(splashStartTimeProvider);
      if (currentTime == null) {
        ref.read(splashStartTimeProvider.notifier).state = _startTime;
        debugPrint('🔄 Splash screen start time set: $_startTime');
      }
      
      // Navigate after minimum display duration
      // This is faster and more reliable than relying on router redirects
      final minDuration = widget.minimumDisplayDuration ?? const Duration(milliseconds: 250);
      Future.delayed(minDuration, () {
        if (mounted) {
          _navigateToNextScreen();
        }
      });
    });

    // Logo animation - faster for quick app opener
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOut,
      ),
    );

    _logoRotation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOut,
      ),
    );

    // Text animation - faster fade and slide
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    // Start animations in sequence - faster
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _textController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background with particles
          _buildAnimatedBackground(),
          
          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo with glow
                  if (widget.logo != null) ...[
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: RotationTransition(
                          turns: _logoRotation,
                          child: widget.logo!,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                ] else ...[
                  // Simplified app opener logo
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.accentGold,
                              AppTheme.primaryGreenLight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentGold.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_soccer,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                    
                  // App name - clean and bold
                  FadeTransition(
                    opacity: _textFade,
                    child: AnimatedBuilder(
                      animation: _textSlide,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Text(
                            'PutraSportHub',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],

                // Simple clean loader - more visible
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryGreen,
                    ),
                    backgroundColor: Colors.white24,
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

  Widget _buildAnimatedBackground() {
    return Container(
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
    );
  }
}

