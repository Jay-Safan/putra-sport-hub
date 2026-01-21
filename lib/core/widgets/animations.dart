import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PutraSportHub Premium Animation System
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// A unified animation library for creating smooth, premium micro-interactions
/// throughout the app. Ensures consistency and reduces code duplication.
///
/// Usage:
///   - Import: import 'package:putra_sport_hub/core/widgets/animations.dart';
///   - Apply: MyWidget().fadeInSlide() or MyWidget().heroEntrance()
///
/// Animation Philosophy:
///   - Subtle > Dramatic (don't distract from content)
///   - Fast > Slow (200-600ms is the sweet spot)
///   - Ease curves for natural feel
///   - Stagger for visual hierarchy
/// ═══════════════════════════════════════════════════════════════════════════

/// Standard animation durations for consistency
class AnimationDurations {
  static const Duration ultraFast = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration slower = Duration(milliseconds: 800);
  
  /// Stagger delay between list items
  static const Duration staggerDelay = Duration(milliseconds: 50);
  
  /// Delay between form fields
  static const Duration fieldDelay = Duration(milliseconds: 100);
}

/// Standard animation curves
class AnimationCurves {
  /// Default ease out for most animations
  static const Curve standard = Curves.easeOutCubic;
  
  /// For entrance animations
  static const Curve entrance = Curves.easeOutQuart;
  
  /// For exit animations  
  static const Curve exit = Curves.easeInCubic;
  
  /// For bouncy/playful effects
  static const Curve bounce = Curves.elasticOut;
  
  /// For smooth deceleration
  static const Curve decelerate = Curves.decelerate;
  
  /// For springy feel
  static const Curve spring = Curves.easeOutBack;
}

/// Extension methods for easy animation application
extension PremiumAnimations on Widget {
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ENTRANCE ANIMATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Standard fade in with subtle slide up
  /// Perfect for: Cards, content blocks, form fields
  Widget fadeInSlide({
    Duration? delay,
    Duration duration = const Duration(milliseconds: 400),
    double beginOffset = 0.05,
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: AnimationCurves.standard)
        .slideY(
          begin: beginOffset, 
          end: 0, 
          duration: duration, 
          curve: AnimationCurves.standard,
        );
  }
  
  /// Hero entrance with scale + fade
  /// Perfect for: Logos, headers, important elements
  Widget heroEntrance({
    Duration? delay,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: AnimationCurves.entrance)
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: duration,
          curve: AnimationCurves.entrance,
        );
  }
  
  /// Slide in from left
  /// Perfect for: Navigation items, list items
  Widget slideInLeft({
    Duration? delay,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: AnimationCurves.standard)
        .slideX(
          begin: -0.1, 
          end: 0, 
          duration: duration, 
          curve: AnimationCurves.standard,
        );
  }
  
  /// Slide in from right
  /// Perfect for: Action buttons, secondary content
  Widget slideInRight({
    Duration? delay,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: AnimationCurves.standard)
        .slideX(
          begin: 0.1, 
          end: 0, 
          duration: duration, 
          curve: AnimationCurves.standard,
        );
  }
  
  /// Pop in with scale
  /// Perfect for: Buttons, chips, badges, icons
  Widget popIn({
    Duration? delay,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: AnimationCurves.standard)
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          duration: duration,
          curve: AnimationCurves.spring,
        );
  }
  
  /// Gentle blur reveal
  /// Perfect for: Background elements, images
  Widget blurReveal({
    Duration? delay,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: AnimationCurves.standard)
        .blur(
          begin: const Offset(10, 10),
          end: const Offset(0, 0),
          duration: duration,
          curve: AnimationCurves.standard,
        );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // LIST ANIMATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Staggered list item animation
  /// Perfect for: List items, grid items
  Widget staggeredItem({
    required int index,
    Duration baseDelay = Duration.zero,
    Duration staggerDelay = const Duration(milliseconds: 50),
  }) {
    final totalDelay = baseDelay + (staggerDelay * index);
    return animate(delay: totalDelay)
        .fadeIn(
          duration: AnimationDurations.normal, 
          curve: AnimationCurves.standard,
        )
        .slideY(
          begin: 0.08, 
          end: 0, 
          duration: AnimationDurations.normal, 
          curve: AnimationCurves.standard,
        );
  }
  
  /// Cascade effect for sequential items
  /// Perfect for: Form fields, menu items
  Widget cascadeIn({
    required int index,
    Duration baseDelay = const Duration(milliseconds: 200),
  }) {
    final delay = baseDelay + (AnimationDurations.fieldDelay * index);
    return fadeInSlide(delay: delay);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MICRO-INTERACTIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Button press effect (scale down on press)
  Widget pressScale({
    double pressedScale = 0.96,
    Duration duration = const Duration(milliseconds: 100),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.0),
      duration: duration,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: child,
      ),
      child: this,
    );
  }
  
  /// Shimmer effect (for loading states or attention)
  Widget shimmerEffect({
    Duration duration = const Duration(milliseconds: 1500),
    Color color = Colors.white,
  }) {
    return animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: duration,
          color: color.withValues(alpha: 0.3),
        );
  }
  
  /// Pulse effect (subtle breathing animation)
  Widget pulse({
    Duration duration = const Duration(milliseconds: 1200),
    double minScale = 0.98,
    double maxScale = 1.02,
  }) {
    return animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: Offset(minScale, minScale),
          end: Offset(maxScale, maxScale),
          duration: duration,
          curve: Curves.easeInOut,
        );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE TRANSITIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Full page entrance animation
  /// Perfect for: Screen content wrapper
  Widget pageEntrance({Duration? delay}) {
    return animate(delay: delay)
        .fadeIn(duration: AnimationDurations.normal, curve: AnimationCurves.entrance);
  }
  
  /// Card entrance with elevation feel
  /// Perfect for: Modal cards, bottom sheets
  Widget cardEntrance({Duration? delay}) {
    return animate(delay: delay)
        .fadeIn(duration: AnimationDurations.normal, curve: AnimationCurves.standard)
        .slideY(
          begin: 0.1, 
          end: 0, 
          duration: AnimationDurations.normal, 
          curve: AnimationCurves.standard,
        )
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: AnimationDurations.normal,
          curve: AnimationCurves.standard,
        );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// ANIMATED WIDGETS
/// ═══════════════════════════════════════════════════════════════════════════

/// Animated icon that scales on tap
class AnimatedPressableIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback? onTap;
  
  const AnimatedPressableIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color = Colors.white,
    this.onTap,
  });

  @override
  State<AnimatedPressableIcon> createState() => _AnimatedPressableIconState();
}

class _AnimatedPressableIconState extends State<AnimatedPressableIcon> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0,
        duration: AnimationDurations.ultraFast,
        curve: AnimationCurves.standard,
        child: Icon(
          widget.icon,
          size: widget.size,
          color: widget.color,
        ),
      ),
    );
  }
}

/// Animated button with press feedback
class AnimatedPressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration duration;
  final String? semanticLabel;
  final String? semanticHint;
  final bool? semanticButton;
  
  const AnimatedPressableButton({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 100),
    this.semanticLabel,
    this.semanticHint,
    this.semanticButton,
  });

  @override
  State<AnimatedPressableButton> createState() => _AnimatedPressableButtonState();
}

class _AnimatedPressableButtonState extends State<AnimatedPressableButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Widget button = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: AnimationCurves.standard,
        child: widget.child,
      ),
    );

    // Wrap with Semantics if labels are provided
    if (widget.semanticLabel != null || widget.semanticHint != null) {
      return Semantics(
        label: widget.semanticLabel,
        hint: widget.semanticHint,
        button: widget.semanticButton ?? true,
        enabled: widget.onTap != null,
        child: button,
      );
    }

    return button;
  }
}

/// Staggered column that animates children sequentially
class StaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final Duration baseDelay;
  final Duration staggerDelay;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  
  const StaggeredColumn({
    super.key,
    required this.children,
    this.baseDelay = Duration.zero,
    this.staggerDelay = const Duration(milliseconds: 80),
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.asMap().entries.map((entry) {
        return entry.value.staggeredItem(
          index: entry.key,
          baseDelay: baseDelay,
          staggerDelay: staggerDelay,
        );
      }).toList(),
    );
  }
}

/// Animated fade transition for page routes
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation.drive(
                CurveTween(curve: AnimationCurves.standard),
              ),
              child: child,
            );
          },
          transitionDuration: AnimationDurations.normal,
          reverseTransitionDuration: AnimationDurations.fast,
        );
}

/// Slide up page route (for modals, details)
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlideUpPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: AnimationCurves.standard,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: AnimationDurations.normal,
          reverseTransitionDuration: AnimationDurations.fast,
        );
}
