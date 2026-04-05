import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../features/auth/data/models/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'badge_service.g.dart';

@riverpod
BadgeService badgeService(BadgeServiceRef ref) {
  return BadgeService();
}

class BadgeService {
  static const List<String> availableBadges = [
    AppConstants.badgeRefFootball,
    AppConstants.badgeRefFutsal,
    AppConstants.badgeRefBadminton,
    AppConstants.badgeRefTennis,
  ];

  static const Map<String, String> badgeNames = {
    AppConstants.badgeRefFootball: 'Football',
    AppConstants.badgeRefFutsal: 'Futsal',
    AppConstants.badgeRefBadminton: 'Badminton',
    AppConstants.badgeRefTennis: 'Tennis',
  };

  static const Map<String, String> badgeIcons = {
    AppConstants.badgeRefFootball: '⚽',
    AppConstants.badgeRefFutsal: '⚽',
    AppConstants.badgeRefBadminton: '🏸',
    AppConstants.badgeRefTennis: '🎾',
  };

  static const Map<String, String> badgeDescriptions = {
    AppConstants.badgeRefFootball: 'Certified to referee football matches',
    AppConstants.badgeRefFutsal: 'Certified to referee futsal matches',
    AppConstants.badgeRefBadminton: 'Certified to referee badminton matches',
    AppConstants.badgeRefTennis: 'Certified to referee tennis matches',
  };

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if a user is certified for a specific sport
  bool isCertifiedFor(UserModel user, String sport) {
    if (user.badges.isEmpty) return false;

    final sportBadge = _getSportBadge(sport);
    if (sportBadge == null) return false;

    return user.badges.contains(sportBadge);
  }

  /// Get the badge constant for a sport name
  String? _getSportBadge(String sport) {
    switch (sport.toLowerCase()) {
      case 'football':
      case 'soccer':
        return AppConstants.badgeRefFootball;
      case 'futsal':
        return AppConstants.badgeRefFutsal;
      case 'badminton':
        return AppConstants.badgeRefBadminton;
      case 'tennis':
        return AppConstants.badgeRefTennis;
      default:
        return null;
    }
  }

  /// Get user's badges with display information
  List<BadgeInfo> getUserBadges(UserModel user) {
    if (user.badges.isEmpty) {
      return [];
    }

    return user.badges
        .where((badge) => availableBadges.contains(badge))
        .map(
          (badge) => BadgeInfo(
            id: badge,
            name: badgeNames[badge] ?? 'Unknown',
            icon: badgeIcons[badge] ?? '❓',
            description: badgeDescriptions[badge] ?? 'Unknown badge',
          ),
        )
        .toList();
  }

  /// Get all available badges with display information
  List<BadgeInfo> getAllAvailableBadges() {
    return availableBadges
        .map(
          (badge) => BadgeInfo(
            id: badge,
            name: badgeNames[badge] ?? 'Unknown',
            icon: badgeIcons[badge] ?? '❓',
            description: badgeDescriptions[badge] ?? 'Unknown badge',
          ),
        )
        .toList();
  }

  /// Add a badge to a user
  Future<void> addBadgeToUser(String userId, String badgeId) async {
    if (!availableBadges.contains(badgeId)) {
      throw ArgumentError('Invalid badge ID: $badgeId');
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'badges': FieldValue.arrayUnion([badgeId]),
      });
    } catch (e) {
      throw Exception('Failed to add badge: $e');
    }
  }

  /// Remove a badge from a user
  Future<void> removeBadgeFromUser(String userId, String badgeId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'badges': FieldValue.arrayRemove([badgeId]),
      });
    } catch (e) {
      throw Exception('Failed to remove badge: $e');
    }
  }

  /// Set all badges for a user (replaces existing badges)
  Future<void> setBadgesForUser(String userId, List<String> badgeIds) async {
    // Validate all badge IDs
    for (String badgeId in badgeIds) {
      if (!availableBadges.contains(badgeId)) {
        throw ArgumentError('Invalid badge ID: $badgeId');
      }
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'badges': badgeIds,
      });
    } catch (e) {
      throw Exception('Failed to set badges: $e');
    }
  }

  /// Get sports that a user can referee
  List<String> getUserRefereeSports(UserModel user) {
    if (user.badges.isEmpty) {
      return [];
    }

    return user.badges
        .where((badge) => badgeNames.containsKey(badge))
        .map((badge) => badgeNames[badge]!)
        .toList();
  }

  /// Check if a user has any referee badges
  bool hasAnyBadges(UserModel user) {
    return user.badges.isNotEmpty &&
        user.badges.any((badge) => availableBadges.contains(badge));
  }

  /// Get badge count for a user
  int getBadgeCount(UserModel user) {
    if (user.badges.isEmpty) {
      return 0;
    }
    return user.badges.where((badge) => availableBadges.contains(badge)).length;
  }

  /// Get the display name for a badge ID
  String getBadgeName(String badgeId) {
    return badgeNames[badgeId] ?? 'Unknown Badge';
  }

  /// Get the icon for a badge ID
  String getBadgeIcon(String badgeId) {
    return badgeIcons[badgeId] ?? '❓';
  }

  /// Get the description for a badge ID
  String getBadgeDescription(String badgeId) {
    return badgeDescriptions[badgeId] ?? 'Unknown badge';
  }

  /// Check if a badge ID is valid
  bool isValidBadge(String badgeId) {
    return availableBadges.contains(badgeId);
  }
}

class BadgeInfo {
  final String id;
  final String name;
  final String icon;
  final String description;

  const BadgeInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}
