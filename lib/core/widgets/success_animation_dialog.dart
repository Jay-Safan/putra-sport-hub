import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable success animation dialog
/// Displays an animated checkmark with optional message
class SuccessAnimationDialog extends StatefulWidget {
  final String? message;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const SuccessAnimationDialog({
    super.key,
    this.message,
    this.subtitle,
    this.icon = Icons.check_circle,
    this.color = AppTheme.primaryGreen,
  });

  /// Show success animation dialog
  /// Returns a Future that completes when the dialog is dismissed
  static Future<void> show(
    BuildContext context, {
    String? message,
    String? subtitle,
    IconData icon = Icons.check_circle,
    Color? color,
    Duration delay = const Duration(milliseconds: 2000),
  }) async {
    // Show dialog with auto-dismiss and tap-to-dismiss
    // Use rootNavigator to ensure dialog stays visible even if screen is popped
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: true, // Allow tapping outside to dismiss
      useRootNavigator: true, // Use root navigator so dialog persists if screen is popped
      builder: (dialogContext) {
        // Auto-dismiss after delay
        Future.delayed(delay, () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext, rootNavigator: true).pop();
          }
        });
        
        return PopScope(
          canPop: true, // Allow back button to dismiss
          child: GestureDetector(
            onTap: () {
              // Allow tapping dialog to dismiss
              Navigator.of(dialogContext, rootNavigator: true).pop();
            },
            child: SuccessAnimationDialog(
              message: message,
              subtitle: subtitle,
              icon: icon,
              color: color ?? AppTheme.primaryGreen,
            ),
          ),
        );
      },
    );
  }

  @override
  State<SuccessAnimationDialog> createState() => _SuccessAnimationDialogState();
}

class _SuccessAnimationDialogState extends State<SuccessAnimationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(40),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.08),
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
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated icon
                  ScaleTransition(
                    scale: _iconScaleAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            widget.color,
                            widget.color.withValues(alpha: 0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      widget.message!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
