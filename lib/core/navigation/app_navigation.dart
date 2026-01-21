import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation helper for consistent flow management
class AppNavigation {
  /// Navigate to a flow screen (pushes on stack, allows back)
  static void startFlow(BuildContext context, String path) {
    context.push(path);
  }

  /// Complete a flow and return to origin
  static void completeFlow(BuildContext context, {String? returnTo}) {
    if (returnTo != null) {
      context.go(returnTo);
    } else {
      // Pop until we're back at a main tab
      while (context.canPop()) {
        context.pop();
      }
      context.go('/home');
    }
  }

  /// Cancel flow and go back
  static void cancelFlow(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  /// Switch between main tabs (replaces stack)
  static void switchTab(BuildContext context, int index) {
    final routes = ['/home', '/bookings', '/referee', '/merit', '/profile'];
    if (index >= 0 && index < routes.length) {
      context.go(routes[index]);
    }
  }
}

/// Premium slide-in transition for flow screens
/// Used for: Booking flows, detail screens, forms
class FlowPageTransition extends CustomTransitionPage<void> {
  FlowPageTransition({
    required super.child,
    super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Combine slide with fade for premium feel
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.15, 0.0), // Subtle slide, not full screen
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 280),
        );
}

/// Vertical slide transition for modals
/// Used for: Bottom sheets, modal dialogs, success screens
class ModalPageTransition extends CustomTransitionPage<void> {
  ModalPageTransition({
    required super.child,
    super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide up with fade and scale for premium modal feel
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1), // Subtle slide up
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.95,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Pure fade transition with subtle scale for tab switches
/// Used for: Tab navigation, auth-to-home, main route changes
class TabPageTransition extends CustomTransitionPage<void> {
  TabPageTransition({
    required super.child,
    super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Simple fade transition - no scale to avoid pointer event issues during navigation
            // Scale transitions can interfere with hit-testing, especially after login
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 350),
        );
}

/// Scale and fade transition for detail screens
/// Used for: Booking details, tournament details, profile sections
class DetailPageTransition extends CustomTransitionPage<void> {
  DetailPageTransition({
    required super.child,
    super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.92,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack, // Slight overshoot for premium feel
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Shared axis horizontal transition for related screens
/// Used for: Step-by-step flows, onboarding, wizards
class SharedAxisPageTransition extends CustomTransitionPage<void> {
  SharedAxisPageTransition({
    required super.child,
    super.key,
    bool reverse = false,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offsetBegin = reverse 
                ? const Offset(-0.1, 0.0)
                : const Offset(0.1, 0.0);
            
            return SlideTransition(
              position: Tween<Offset>(
                begin: offsetBegin,
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 280),
        );
}