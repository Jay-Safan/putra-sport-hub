import 'package:flutter/material.dart';

/// Minimalist 3-dot loader (Wise-style)
/// Clean, subtle animation for buttons and inline loading
class MinimalDotLoader extends StatefulWidget {
  final Color? color;
  final double size;
  final Duration duration;

  const MinimalDotLoader({
    super.key,
    this.color,
    this.size = 8.0,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<MinimalDotLoader> createState() => _MinimalDotLoaderState();
}

class _MinimalDotLoaderState extends State<MinimalDotLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Colors.white;

    return SizedBox(
      width: widget.size * 5, // Space for 3 dots with gaps
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final animationValue = ((_controller.value + delay) % 1.0);
              final opacity = animationValue < 0.5
                  ? animationValue * 2
                  : 2 - (animationValue * 2);
              final scale = 0.5 + (opacity * 0.5);

              return Container(
                margin: EdgeInsets.symmetric(horizontal: widget.size * 0.3),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity.clamp(0.3, 1.0),
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Minimal inline spinner for buttons
/// Smaller, cleaner version of CircularProgressIndicator
class InlineLoader extends StatelessWidget {
  final Color? color;
  final double size;
  final double strokeWidth;

  const InlineLoader({
    super.key,
    this.color,
    this.size = 18.0,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    final loaderColor = color ?? Colors.white;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(loaderColor),
      ),
    );
  }
}

/// Progressive loader wrapper
/// Wraps content and provides smooth fade-in transition when data loads
class ProgressiveLoader extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Duration fadeDuration;
  final Curve fadeCurve;

  const ProgressiveLoader({
    super.key,
    required this.child,
    required this.isLoading,
    this.fadeDuration = const Duration(milliseconds: 300),
    this.fadeCurve = Curves.easeOutCubic,
  });

  @override
  State<ProgressiveLoader> createState() => _ProgressiveLoaderState();
}

class _ProgressiveLoaderState extends State<ProgressiveLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.fadeDuration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.fadeCurve,
    );

    if (!widget.isLoading) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ProgressiveLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && oldWidget.isLoading) {
      _controller.forward();
    } else if (widget.isLoading && !oldWidget.isLoading) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}

