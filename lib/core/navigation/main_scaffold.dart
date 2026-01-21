import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_theme.dart';
/// Main scaffold with bottom navigation
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  List<_NavItem> _buildNavItems(UserModel? user, WidgetRef ref) {
    // Get active mode from provider
    final mode = ref.watch(activeUserModeProvider);
    final items = <_NavItem>[];

    // ADMIN USERS: Show admin-specific navigation only
    // Admins don't book or play - they only manage the system
    if (user?.role == UserRole.admin) {
      // Admin Dashboard as main screen
      items.add(
        _NavItem(
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings,
          label: 'Admin',
          route: '/admin',
        ),
      );
      // AI Chat for admin support
      items.add(
        _NavItem(
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          label: 'AI Help',
          route: '/chat',
        ),
      );
    }
    // REFEREE MODE: Referee-specific navigation
    else if (mode == UserMode.referee && user?.isVerifiedReferee == true) {
      // Always show Home first
      items.add(
        _NavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Home',
          route: '/home',
        ),
      );
      // REFEREE MODE: Referee jobs
      items.add(
        _NavItem(
          icon: Icons.sports_soccer_outlined,
          activeIcon: Icons.sports_soccer,
          label: 'SukanGig',
          route: '/referee',
        ),
      );
      // AI Chat for referees too
      items.add(
        _NavItem(
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          label: 'AI Help',
          route: '/chat',
        ),
      );
    }
    // STUDENT MODE: Full features (bookings, tournaments, AI)
    else if (user?.isStudent == true) {
      // Always show Home first
      items.add(
        _NavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Home',
          route: '/home',
        ),
      );
      // Student features: Bookings, Tournaments, AI Chat
      items.add(
        _NavItem(
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today,
          label: 'Bookings',
          route: '/bookings',
        ),
      );
      items.add(
        _NavItem(
          icon: Icons.emoji_events_outlined,
          activeIcon: Icons.emoji_events,
          label: 'Tournaments',
          route: '/tournaments',
        ),
      );
      // AI Chatbot as a main feature
      items.add(
        _NavItem(
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          label: 'AI Help',
          route: '/chat',
        ),
      );
    }
    // PUBLIC USER MODE: Basic features only (bookings, no tournaments)
    else {
      // Always show Home first
      items.add(
        _NavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Home',
          route: '/home',
        ),
      );
      // Public users: Only Bookings, AI Chat (NO tournaments)
      items.add(
        _NavItem(
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today,
          label: 'Bookings',
          route: '/bookings',
        ),
      );
      // AI Chatbot for support
      items.add(
        _NavItem(
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          label: 'AI Help',
          route: '/chat',
        ),
      );
    }

    // Always show Profile last
    items.add(
      _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
        route: '/profile',
      ),
    );

    return items;
  }

  int _getIndexForRoute(String route, List<_NavItem> navItems) {
    for (int i = 0; i < navItems.length; i++) {
      if (route == navItems[i].route) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final navItems = _buildNavItems(user, ref);
    
    // Get current route to highlight correct tab
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final currentIndex = _getIndexForRoute(currentLocation, navItems);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Main content - first in stack so it's behind nav bar
          // Must be first to receive pointer events properly
          child,
          // Custom transparent navigation bar as overlay - only intercepts touches in its area
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: navItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final isSelected = index == currentIndex;
                          
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (index < navItems.length) {
                                  context.go(navItems[index].route);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: isSelected
                                            ? LinearGradient(
                                                colors: [
                                                  AppTheme.accentGold.withValues(alpha: 0.2),
                                                  AppTheme.accentGold.withValues(alpha: 0.1),
                                                ],
                                              )
                                            : null,
                                      ),
                                      child: Icon(
                                        isSelected ? item.activeIcon : item.icon,
                                        size: 24,
                                        color: isSelected
                                            ? AppTheme.accentGold
                                            : Colors.white.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: isSelected ? 11 : 10,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        letterSpacing: isSelected ? 0.2 : 0,
                                        color: isSelected
                                            ? AppTheme.accentGold
                                            : Colors.white.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

