import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/data/models/user_model.dart';
import '../core/constants/app_constants.dart';
import 'service_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AUTH PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Firebase auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Current user model provider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user != null) {
        return ref.watch(authServiceProvider).userModelStream(user.uid);
      }
      return Stream.value(null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Check if current user is student
final isStudentProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.isStudent ?? false;
});

/// User role provider
final userRoleProvider = Provider<UserRole>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role ?? UserRole.public;
});

/// Flag to track if profile picture is being updated/removed
/// This prevents router redirects and splash navigation during profile operations
final isUpdatingProfileProvider = StateProvider<bool>((ref) => false);

/// Last login error message (persists across route changes)
final lastLoginErrorProvider = StateProvider<String?>((ref) => null);

// ═══════════════════════════════════════════════════════════════════════════
// USER MODE PROVIDER (Student Mode vs Referee Mode)
// ═══════════════════════════════════════════════════════════════════════════

/// Active user mode (Student or Referee)
/// Defaults to Student Mode or user's preferred mode from Firebase
/// Referee Mode only available if user has referee badges
/// This allows users to switch between different app experiences based on their role
final activeUserModeProvider = StateProvider<UserMode>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;

  // Check if user has a preferred mode saved in Firebase
  if (user?.preferredMode != null) {
    try {
      final preferredMode = UserMode.fromCode(user!.preferredMode!);
      // Only return preferred mode if user can actually use it
      if (preferredMode == UserMode.referee && user.isVerifiedReferee) {
        return preferredMode;
      } else if (preferredMode == UserMode.student) {
        return preferredMode;
      }
    } catch (e) {
      // Invalid mode, fall through to default
    }
  }

  // Default to Student Mode
  // If user has referee badges, they can switch to Referee Mode via Profile
  return UserMode.student;
});

/// Check if user can switch to referee mode (must have referee badges)
final canSwitchToRefereeModeProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.isVerifiedReferee ?? false;
});
