import '../../features/auth/data/models/user_model.dart';
import '../constants/app_constants.dart';

/// Role-based access control guards for PutraSportHub
/// Provides centralized permission checks for different user roles
class RoleGuards {
  RoleGuards._(); // Prevent instantiation

  // ═══════════════════════════════════════════════════════════════════════════
  // BASIC ROLE CHECKS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if user is an admin
  static bool isAdmin(UserModel? user) {
    return user?.role == UserRole.admin;
  }

  /// Check if user is a student
  static bool isStudent(UserModel? user) {
    return user?.isStudent == true || user?.role == UserRole.admin;
  }

  /// Check if user is a public user (non-student)
  static bool isPublicUser(UserModel? user) {
    return user != null && !isStudent(user) && !isAdmin(user);
  }

  /// Check if user is a verified referee
  static bool isVerifiedReferee(UserModel? user) {
    return user?.isVerifiedReferee == true;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FEATURE ACCESS CHECKS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if user can access student-only features
  /// Admins have access to all student features
  static bool canAccessStudentFeatures(UserModel? user) {
    return isStudent(user);
  }

  /// Check if user can create tournaments
  /// Students and admins can create tournaments
  static bool canCreateTournament(UserModel? user) {
    return isStudent(user);
  }

  /// Check if user can apply to be a referee
  /// Only students (not admins) can apply
  static bool canApplyAsReferee(UserModel? user) {
    if (user == null) return false;
    return user.isStudent && !isAdmin(user);
  }

  /// Check if user can earn merit points
  /// Only students (not admins) earn merit points
  static bool canEarnMerit(UserModel? user) {
    if (user == null) return false;
    return user.isStudent && !isAdmin(user);
  }

  /// Check if user can referee a specific sport
  static bool canRefereeSport(UserModel? user, SportType sport) {
    if (user == null) return false;
    return user.isCertifiedFor(sport);
  }

  /// Check if user can access referee marketplace (SukanGig)
  static bool canAccessRefereeMarketplace(UserModel? user) {
    return isVerifiedReferee(user);
  }

  /// Check if user can access admin dashboard
  static bool canAccessAdmin(UserModel? user) {
    return isAdmin(user);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOKING PERMISSIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if user gets student pricing
  static bool getsStudentPricing(UserModel? user) {
    return isStudent(user);
  }

  /// Check if user can create bookings
  /// Referees in referee mode cannot book - they can only referee matches
  /// Only students and public users can book facilities
  static bool canCreateBookings(UserModel? user) {
    if (user == null) return false;
    // Referees should only referee, not book facilities
    // Students and public users can book
    // Note: Student referees can still book when in student mode (not referee mode)
    return !isVerifiedReferee(user) || isStudent(user);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOURNAMENT PERMISSIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if user can create tournaments
  static bool canCreateTournaments(UserModel? user) {
    return canCreateTournament(user);
  }

  /// Check if user can join tournaments
  /// All authenticated users can join public tournaments
  static bool canJoinTournaments(UserModel? user) {
    return user != null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN PERMISSIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if user can manage users
  static bool canManageUsers(UserModel? user) {
    return isAdmin(user);
  }

  /// Check if user can manage bookings
  static bool canManageBookings(UserModel? user) {
    return isAdmin(user);
  }

  /// Check if user can manage tournaments
  static bool canManageTournaments(UserModel? user) {
    return isAdmin(user);
  }

  /// Check if user can manage facilities
  static bool canManageFacilities(UserModel? user) {
    return isAdmin(user);
  }

  /// Check if user can manage referees
  static bool canManageReferees(UserModel? user) {
    return isAdmin(user);
  }

  /// Check if user can view all transactions
  static bool canViewAllTransactions(UserModel? user) {
    return isAdmin(user);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY CHECKS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get user's effective role for feature access
  /// Returns the role that determines feature access
  static String getEffectiveRole(UserModel? user) {
    if (user == null) return 'NONE';
    if (isAdmin(user)) return 'ADMIN';
    if (isVerifiedReferee(user) && isStudent(user)) return 'STUDENT_REFEREE';
    if (isStudent(user)) return 'STUDENT';
    return 'PUBLIC';
  }

  /// Check if user has at least one of the required roles
  static bool hasAnyRole(UserModel? user, List<UserRole> roles) {
    if (user == null) return false;
    return roles.contains(user.role);
  }

  /// Check if user has all required capabilities
  static bool hasAllCapabilities(
    UserModel? user,
    List<bool Function(UserModel?)> checks,
  ) {
    if (user == null) return false;
    return checks.every((check) => check(user));
  }
}
