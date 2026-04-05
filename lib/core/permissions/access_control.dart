import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../features/auth/data/models/user_model.dart';
import 'role_guards.dart';

/// Access control widget that conditionally shows content based on user role
class RoleBasedAccess extends ConsumerWidget {
  final Widget child;
  final bool Function(UserModel?) check;
  final Widget? fallback;

  const RoleBasedAccess({
    super.key,
    required this.child,
    required this.check,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    if (check(user)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }

  /// Show content only for students
  factory RoleBasedAccess.studentOnly({
    required Widget child,
    Widget? fallback,
  }) {
    return RoleBasedAccess(
      check: RoleGuards.canAccessStudentFeatures,
      fallback: fallback,
      child: child,
    );
  }

  /// Show content only for verified referees
  factory RoleBasedAccess.refereeOnly({
    required Widget child,
    Widget? fallback,
  }) {
    return RoleBasedAccess(
      check: RoleGuards.isVerifiedReferee,
      fallback: fallback,
      child: child,
    );
  }

  /// Show content only for admins
  factory RoleBasedAccess.adminOnly({required Widget child, Widget? fallback}) {
    return RoleBasedAccess(
      check: RoleGuards.canAccessAdmin,
      fallback: fallback,
      child: child,
    );
  }

  /// Show content for students who can create tournaments
  factory RoleBasedAccess.tournamentCreatorOnly({
    required Widget child,
    Widget? fallback,
  }) {
    return RoleBasedAccess(
      check: RoleGuards.canCreateTournament,
      fallback: fallback,
      child: child,
    );
  }
}

/// Route guard helper for redirects
class RouteGuard {
  /// Check if route is accessible and return redirect path if not
  /// Returns null if accessible, or redirect path if not
  static String? checkAccess(
    UserModel? user,
    bool Function(UserModel?) check, {
    String? redirectTo = '/home',
  }) {
    if (check(user)) {
      return null; // Access granted
    }
    return redirectTo; // Access denied, redirect
  }
}
