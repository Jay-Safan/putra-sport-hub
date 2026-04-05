import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../core/widgets/modern_loader.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/booking/presentation/shared/facility_list_screen.dart';
import '../../features/booking/presentation/shared/booking_flow_screen.dart';
import '../../features/booking/presentation/shared/bookings_screen.dart';
import '../../features/booking/presentation/shared/booking_detail_screen.dart';
import '../../features/booking/presentation/shared/booking_success_screen.dart';
import '../../features/payment/presentation/wallet_screen.dart';
import '../../features/payment/presentation/top_up_screen.dart';
import '../../features/referee/presentation/referee_dashboard_screen.dart';
import '../../features/referee/presentation/referee_application_screen.dart';
import '../../features/merit/presentation/merit_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/tournament/presentation/shared/tournament_list_screen.dart';
import '../../features/tournament/presentation/shared/tournament_detail_screen.dart';
import '../../features/tournament/presentation/student/create_tournament_screen.dart';
import '../../core/permissions/role_guards.dart';
import '../../core/permissions/access_control.dart' show RouteGuard;
import '../../features/tournament/presentation/shared/join_tournament_screen.dart';
import '../../features/tournament/presentation/shared/share_tournament_screen.dart';
import '../../features/tournament/presentation/shared/join_tournament_by_code_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/users_list_screen.dart';
import '../../features/admin/presentation/bookings_list_screen.dart';
import '../../features/admin/presentation/tournaments_list_screen.dart';
import '../../features/admin/presentation/facilities_list_screen.dart';
import '../../features/admin/presentation/referees_list_screen.dart';
import '../../features/admin/presentation/transactions_list_screen.dart';
import '../../features/admin/presentation/analytics_screen.dart';
import '../../features/ai/presentation/chatbot_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/help_support_screen.dart';
import '../../features/profile/presentation/about_screen.dart';
import '../../features/profile/presentation/terms_conditions_screen.dart';
import '../../features/profile/presentation/privacy_policy_screen.dart';
import '../../features/profile/presentation/send_feedback_screen.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import 'app_navigation.dart';
import 'main_scaffold.dart';

/// Router provider - centralized route configuration
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUser = ref.watch(currentUserProvider);
  final isUpdatingProfile = ref.watch(isUpdatingProfileProvider);

  // Determine initial location - only use /splash on first app load
  // For subsequent rebuilds, try to preserve current location if possible
  String initialLocation = '/splash';

  // If profile is being updated, try to stay on /profile
  if (isUpdatingProfile) {
    initialLocation = '/profile';
  }

  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      // CRITICAL: FIRST CHECK - If profile is being updated, NEVER redirect - stay where you are
      // This must be the absolute first check to prevent any navigation interference
      // This prevents any navigation during profile picture upload/removal
      if (isUpdatingProfile) {
        debugPrint('🛡️ Router redirect blocked - profile update in progress');
        return null; // Block ALL redirects during profile update
      }

      final isAuthRoute =
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/forgot-password');

      final currentLocation = state.matchedLocation;

      // Splash screen handles its own navigation timing - don't redirect from it
      if (currentLocation == '/splash') {
        return null; // Let splash screen navigate itself
      }

      // If auth state is still loading, handle appropriately
      if (authState.isLoading) {
        // If on auth route and auth is loading, allow staying there
        if (isAuthRoute) {
          return null;
        }
        // If not on auth route and auth is loading, go to splash (only on initial load)
        if (currentLocation == '/' || currentLocation.isEmpty) {
          return '/splash';
        }
        // Already on some route - wait for auth to resolve
        return null;
      }

      // Auth state resolved - check if user exists FIRST
      // This MUST be checked before valid routes to handle sign out properly
      final hasFirebaseAuth = authState.valueOrNull != null;

      // CRITICAL: If no Firebase Auth user, redirect to login (unless already on auth route)
      // This handles sign out from any screen - must be checked BEFORE valid routes
      if (!hasFirebaseAuth) {
        if (!isAuthRoute) {
          // User not logged in and not on auth route - redirect to login
          // This ensures sign out from profile/home/etc. always goes to login
          debugPrint(
            '🔄 User not logged in - redirecting to /login from $currentLocation',
          );
          return '/login';
        }
        // Already on auth route - stay there
        return null;
      }

      // User IS logged in - now check valid routes to prevent unnecessary redirects
      // List of all valid routes that should NEVER be interrupted by redirects when logged in
      final validRoutes = [
        '/profile', // Most critical - user might be uploading/removing profile picture
        '/home',
        '/bookings',
        '/referee',
        '/admin',
        '/merit',
        '/tournaments',
        '/chat',
      ];

      final isOnValidRoute =
          validRoutes.contains(currentLocation) ||
          currentLocation.startsWith('/booking/') ||
          currentLocation.startsWith('/tournament/') ||
          currentLocation.startsWith('/wallet') ||
          currentLocation.startsWith('/notifications');

      // Never redirect away from valid routes when user is logged in
      if (isOnValidRoute) {
        debugPrint(
          '🛡️ Router redirect blocked - on valid route: $currentLocation',
        );
        return null; // Stay where you are - no redirects allowed
      }

      // Never redirect TO splash if already on a route (only allow splash on initial app load)
      // This prevents splash from interrupting any user activity
      if (currentLocation != '/splash' &&
          currentLocation != '/' &&
          currentLocation.isNotEmpty) {
        // Already on a route - don't redirect to splash
        return null;
      }

      // Not on splash - handle other routes
      final userDoc = currentUser.valueOrNull;
      final isLoggedIn = hasFirebaseAuth && userDoc != null;

      // If currentUser is still loading, don't redirect yet - wait for it to complete
      // This prevents redirecting to /login during the transition period after login
      // IMPORTANT: Never redirect from profile screen, even during loading states
      if (currentUser.isLoading && hasFirebaseAuth) {
        // User is authenticated but Firestore document is still loading
        // If on login/register page and authenticated, allow staying there briefly
        // Otherwise, if trying to access protected route, let it wait
        if (isAuthRoute) {
          // On auth route but authenticated - stay here briefly until user doc loads
          // Router will redirect to /home once currentUser loads
          return null;
        }
        // On protected route and user doc is loading - allow access (will redirect if needed)
        // BUT: Never redirect from profile screen
        if (state.matchedLocation == '/profile') {
          return null; // Stay on profile screen during loading
        }
        return null;
      }

      // If Firebase Auth exists but no Firestore document (after loading completes), redirect to login
      // This handles the case where user was cleared from Firestore but Auth still has them
      // BUT: Don't redirect if we're already on the login page (to avoid clearing error messages)
      if (hasFirebaseAuth &&
          !currentUser.isLoading &&
          currentUser.hasValue &&
          userDoc == null &&
          !isAuthRoute) {
        // User exists in Firebase Auth but not in Firestore - sign out and redirect to login
        // Use Future.microtask to avoid calling signOut during build
        // Only sign out if not already on login page (prevents refresh during login attempts)
        if (state.matchedLocation != '/login') {
          Future.microtask(() async {
            await ref.read(authServiceProvider).signOut();
          });
          return '/login';
        } else {
          // Already on login page - sign out without redirect to prevent refresh
          Future.microtask(() async {
            await ref.read(authServiceProvider).signOut();
          });
          // Return null to prevent redirect
          return null;
        }
      }

      // CRITICAL: Never redirect from profile screen - prevents navigation during profile picture upload/removal
      // This ensures users stay on profile screen even if provider states change
      // This is checked again here as a final safety net
      if (currentLocation == '/profile') {
        return null; // Always stay on profile screen - never redirect away
      }

      // Also check valid routes again as final safety check
      if (isOnValidRoute) {
        return null; // Never redirect from valid routes
      }

      // If not logged in and trying to access protected route
      // BUT: Never redirect from profile screen (might be updating/removing profile picture)
      if (!isLoggedIn &&
          !isAuthRoute &&
          currentLocation != '/profile' &&
          !isOnValidRoute) {
        return '/login';
      }

      // If logged in and on auth route (login/register), redirect based on role
      if (isLoggedIn && isAuthRoute) {
        // userDoc cannot be null when isLoggedIn is true
        // Admins should go directly to admin dashboard
        if (userDoc.role == UserRole.admin) {
          return '/admin';
        }
        // Other users go to home
        return '/home';
      }

      // Check if admin is trying to access home or other regular routes
      if (isLoggedIn && userDoc.role == UserRole.admin) {
        // If admin is on home or other non-admin routes, redirect to admin
        if (state.matchedLocation == '/home' ||
            state.matchedLocation.startsWith('/bookings') ||
            state.matchedLocation.startsWith('/referee') ||
            state.matchedLocation.startsWith('/tournament')) {
          return '/admin';
        }
      }

      return null;
    },
    routes: [
      // ═══════════════════════════════════════════════════════════════════
      // SPLASH SCREEN (Initial loading)
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/splash',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SplashLoader(
                message: null, // No message - cleaner look
                minimumDisplayDuration: Duration(milliseconds: 500),
              ),
            ),
      ),
      // ═══════════════════════════════════════════════════════════════════
      // AUTH ROUTES (No bottom nav, simple stack)
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/login',
        pageBuilder:
            (context, state) => TabPageTransition(
              key: state.pageKey,
              child: const LoginScreen(),
            ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const RegisterScreen(),
            ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const ForgotPasswordScreen(),
            ),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // MAIN HUB (Bottom nav tabs - use go() for these)
      // ═══════════════════════════════════════════════════════════════════
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            redirect: (context, state) {
              final user = ref.read(currentUserProvider).valueOrNull;
              // Admins should never access home - redirect to admin dashboard
              if (RoleGuards.isAdmin(user)) {
                return '/admin';
              }
              return null;
            },
            pageBuilder:
                (context, state) => TabPageTransition(
                  key: state.pageKey,
                  child: const HomeScreen(),
                ),
          ),
          GoRoute(
            path: '/bookings',
            redirect: (context, state) {
              final user = ref.read(currentUserProvider).valueOrNull;
              final mode = ref.read(activeUserModeProvider);
              // Admins don't need booking features - redirect to admin dashboard
              if (RoleGuards.isAdmin(user)) {
                return '/admin';
              }
              // Referees in referee mode cannot access bookings - redirect to referee dashboard
              if (mode == UserMode.referee && user?.isVerifiedReferee == true) {
                return '/referee';
              }
              return null;
            },
            pageBuilder:
                (context, state) => TabPageTransition(
                  key: state.pageKey,
                  child: const BookingsScreen(),
                ),
          ),
          GoRoute(
            path: '/referee',
            pageBuilder:
                (context, state) => TabPageTransition(
                  key: state.pageKey,
                  child: const RefereeDashboardScreen(),
                ),
          ),
          GoRoute(
            path: '/admin',
            pageBuilder:
                (context, state) => TabPageTransition(
                  key: state.pageKey,
                  child: const AdminDashboardScreen(),
                ),
          ),
          GoRoute(
            path: '/merit',
            pageBuilder:
                (context, state) => TabPageTransition(
                  key: state.pageKey,
                  child: const MeritScreen(),
                ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder:
                (context, state) => TabPageTransition(
                  key: state.pageKey,
                  child: const ProfileScreen(),
                ),
          ),
          GoRoute(
            path: '/tournaments',
            redirect: (context, state) {
              final user = ref.read(currentUserProvider).valueOrNull;
              // Only students can access tournaments
              return RouteGuard.checkAccess(
                user,
                RoleGuards.canAccessStudentFeatures,
                redirectTo: '/home',
              );
            },
            pageBuilder:
                (context, state) => TabPageTransition(
                  key: state.pageKey,
                  child: const TournamentListScreen(),
                ),
          ),
          GoRoute(
            path: '/chat',
            pageBuilder:
                (context, state) => TabPageTransition(
                  key: state.pageKey,
                  child: const ChatbotScreen(),
                ),
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════════
      // BOOKING FLOW (Slide-in from right)
      // Flow: Home → Sport → Facility → Time/Options → Payment → Success
      // Only for students and public users - admins cannot book
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/booking/sport/:sportCode',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider).valueOrNull;
          final mode = ref.read(activeUserModeProvider);
          // Admins don't book - redirect to admin dashboard
          if (RoleGuards.isAdmin(user)) {
            return '/admin';
          }
          // Referees in referee mode cannot book - redirect to referee dashboard
          if (mode == UserMode.referee && user?.isVerifiedReferee == true) {
            return '/referee';
          }
          return null;
        },
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: FacilityListScreen(
                sportCode: state.pathParameters['sportCode']!,
              ),
            ),
      ),
      GoRoute(
        path: '/booking/facility/:facilityId',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider).valueOrNull;
          final mode = ref.read(activeUserModeProvider);
          // Admins don't book - redirect to admin dashboard
          if (RoleGuards.isAdmin(user)) {
            return '/admin';
          }
          // Referees in referee mode cannot book - redirect to referee dashboard
          if (mode == UserMode.referee && user?.isVerifiedReferee == true) {
            return '/referee';
          }
          return null;
        },
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: BookingFlowScreen(
                facilityId: state.pathParameters['facilityId']!,
              ),
            ),
      ),
      GoRoute(
        path: '/booking/:bookingId',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider).valueOrNull;
          final mode = ref.read(activeUserModeProvider);
          // Admins can view booking details (for management purposes)
          // Regular users and referees have restrictions
          if (!RoleGuards.isAdmin(user)) {
            // Referees in referee mode cannot access booking details - redirect to referee dashboard
            if (mode == UserMode.referee && user?.isVerifiedReferee == true) {
              return '/referee';
            }
          }
          return null;
        },
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: BookingDetailScreen(
                bookingId: state.pathParameters['bookingId']!,
              ),
            ),
      ),
      GoRoute(
        path: '/booking/success/:bookingId',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider).valueOrNull;
          final mode = ref.read(activeUserModeProvider);
          // Referees in referee mode shouldn't see booking success
          if (mode == UserMode.referee && user?.isVerifiedReferee == true) {
            return '/referee';
          }
          return null;
        },
        pageBuilder:
            (context, state) => ModalPageTransition(
              key: state.pageKey,
              child: BookingSuccessScreen(
                bookingId: state.pathParameters['bookingId']!,
              ),
            ),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // NOTIFICATIONS (Standalone route, accessible from anywhere)
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/notifications',
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const NotificationsScreen(),
            ),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // ADMIN MANAGEMENT (Standalone routes for admin list screens)
      // All admin routes are protected by role guards
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/admin/users',
        redirect:
            (context, state) => RouteGuard.checkAccess(
              ref.read(currentUserProvider).valueOrNull,
              RoleGuards.canManageUsers,
              redirectTo: '/admin',
            ),
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const UsersListScreen(),
            ),
      ),
      GoRoute(
        path: '/admin/bookings',
        redirect:
            (context, state) => RouteGuard.checkAccess(
              ref.read(currentUserProvider).valueOrNull,
              RoleGuards.canManageBookings,
              redirectTo: '/admin',
            ),
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const BookingsListScreen(),
            ),
      ),
      GoRoute(
        path: '/admin/tournaments',
        redirect:
            (context, state) => RouteGuard.checkAccess(
              ref.read(currentUserProvider).valueOrNull,
              RoleGuards.canManageTournaments,
              redirectTo: '/admin',
            ),
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const TournamentsListScreen(),
            ),
      ),
      GoRoute(
        path: '/admin/facilities',
        redirect:
            (context, state) => RouteGuard.checkAccess(
              ref.read(currentUserProvider).valueOrNull,
              RoleGuards.canManageFacilities,
              redirectTo: '/admin',
            ),
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const FacilitiesListScreen(),
            ),
      ),
      GoRoute(
        path: '/admin/referees',
        redirect:
            (context, state) => RouteGuard.checkAccess(
              ref.read(currentUserProvider).valueOrNull,
              RoleGuards.canManageReferees,
              redirectTo: '/admin',
            ),
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const RefereesListScreen(),
            ),
      ),
      GoRoute(
        path: '/admin/transactions',
        redirect:
            (context, state) => RouteGuard.checkAccess(
              ref.read(currentUserProvider).valueOrNull,
              RoleGuards.canViewAllTransactions,
              redirectTo: '/admin',
            ),
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const TransactionsListScreen(),
            ),
      ),
      GoRoute(
        path: '/admin/analytics',
        redirect:
            (context, state) => RouteGuard.checkAccess(
              ref.read(currentUserProvider).valueOrNull,
              RoleGuards.canManageUsers, // Use admin check
              redirectTo: '/admin',
            ),
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const AnalyticsScreen(),
            ),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // PROFILE/SETTINGS (Standalone routes)
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/help-support',
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const HelpSupportScreen(),
            ),
      ),
      GoRoute(
        path: '/about',
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const AboutScreen(),
            ),
      ),
      GoRoute(
        path: '/terms-conditions',
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const TermsConditionsScreen(),
            ),
      ),
      GoRoute(
        path: '/privacy-policy',
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const PrivacyPolicyScreen(),
            ),
      ),
      GoRoute(
        path: '/send-feedback',
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const SendFeedbackScreen(),
            ),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // TOURNAMENT FLOW (Tournament Hub & Management)
      // Note: /tournaments is in ShellRoute above for bottom nav
      // Only accessible to STUDENTS, not public users or admins
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/tournament/create',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider).valueOrNull;
          // Only students can create tournaments
          return RouteGuard.checkAccess(
            user,
            RoleGuards.canCreateTournament,
            redirectTo: '/home',
          );
        },
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const CreateTournamentScreen(),
            ),
      ),
      GoRoute(
        path: '/tournament/:tournamentId',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider).valueOrNull;
          // Admins can view tournament details (for management purposes)
          // Otherwise, only students can view tournament details
          if (!RoleGuards.isAdmin(user)) {
            return RouteGuard.checkAccess(
              user,
              RoleGuards.canAccessStudentFeatures,
              redirectTo: '/home',
            );
          }
          return null;
        },
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: TournamentDetailScreen(
                tournamentId: state.pathParameters['tournamentId']!,
              ),
            ),
      ),
      GoRoute(
        path: '/tournament/:tournamentId/join',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider).valueOrNull;
          // Only students can join tournaments
          return RouteGuard.checkAccess(
            user,
            RoleGuards.canJoinTournaments,
            redirectTo: '/home',
          );
        },
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: JoinTournamentScreen(
                tournamentId: state.pathParameters['tournamentId']!,
              ),
            ),
      ),
      GoRoute(
        path: '/tournament/:tournamentId/share',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider).valueOrNull;
          // Only students can share tournaments
          if (user?.isStudent != true) {
            return '/home';
          }
          return null;
        },
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: ShareTournamentScreen(
                tournamentId: state.pathParameters['tournamentId']!,
              ),
            ),
      ),
      GoRoute(
        path: '/tournaments/join-by-code',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider).valueOrNull;
          // Only students can join tournaments
          return RouteGuard.checkAccess(
            user,
            RoleGuards.canJoinTournaments,
            redirectTo: '/home',
          );
        },
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const JoinTournamentByCodeScreen(),
            ),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // REFEREE FLOW (Slide-in from right)
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/referee/apply',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider).valueOrNull;
          // Only students can apply to become referees
          return RouteGuard.checkAccess(
            user,
            RoleGuards.canApplyAsReferee,
            redirectTo: '/home',
          );
        },
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const RefereeApplicationScreen(),
            ),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // WALLET FLOW (Modal slide-up, use push())
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/wallet',
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const WalletScreen(),
            ),
      ),
      GoRoute(
        path: '/wallet/topup',
        pageBuilder:
            (context, state) => FlowPageTransition(
              key: state.pageKey,
              child: const TopUpScreen(),
            ),
      ),
    ],
  );
});
