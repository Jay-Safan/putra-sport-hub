import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';

/// User model representing all user types in PutraSportHub
/// Schema aligned with v5.0 spec - uses `badges` array for referee verification
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final String? matricNo;
  final UserRole role;
  final bool isStudent;
  final List<String> badges; // e.g., ['VERIFIED_REF_FOOTBALL']
  final double walletBalance;
  final int totalMeritPoints;
  final String? preferredMode; // 'STUDENT' or 'REFEREE' - User's preferred mode (optional Firebase persistence)
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.matricNo,
    required this.role,
    required this.isStudent,
      this.badges = const [],
      this.walletBalance = 0.0,
      this.totalMeritPoints = 0,
      this.preferredMode,
      required this.createdAt,
      this.lastLoginAt,
      this.isActive = true,
  });

  /// Check if user has student privileges
  bool get hasStudentPrivileges => isStudent || role == UserRole.admin;

  /// Check if user can earn merit points
  bool get canEarnMerit => isStudent;

  /// Check if user can apply to be a referee
  bool get canApplyAsReferee => isStudent;

  /// Check if user is a verified referee for any sport
  bool get isVerifiedReferee => badges.any((b) => b.startsWith('VERIFIED_REF_'));

  /// Check if user is certified for a specific sport (using badge system)
  bool isCertifiedFor(SportType sport) {
    switch (sport) {
      case SportType.football:
        return badges.contains(AppConstants.badgeRefFootball);
      case SportType.futsal:
        return badges.contains(AppConstants.badgeRefFutsal);
      case SportType.badminton:
        return badges.contains(AppConstants.badgeRefBadminton);
      case SportType.tennis:
        return badges.contains(AppConstants.badgeRefTennis);
    }
  }

  /// Get the list of sports this user can referee
  List<SportType> get certifiedSports {
    final sports = <SportType>[];
    if (badges.contains(AppConstants.badgeRefFootball)) sports.add(SportType.football);
    if (badges.contains(AppConstants.badgeRefFutsal)) sports.add(SportType.futsal);
    if (badges.contains(AppConstants.badgeRefBadminton)) sports.add(SportType.badminton);
    if (badges.contains(AppConstants.badgeRefTennis)) sports.add(SportType.tennis);
    return sports;
  }

  /// Get price rate type for this user
  String get priceType => isStudent ? 'Student' : 'Public';

  /// Factory constructor from Firebase Auth + Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['full_name'] ?? data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      phoneNumber: data['phoneNumber'],
      matricNo: data['matric_no'] ?? data['matricNo'],
      role: UserRole.fromCode(data['role'] ?? 'PUBLIC'),
      isStudent: data['isStudent'] ?? false,
      badges: List<String>.from(data['badges'] ?? []),
      walletBalance: (data['wallet_balance'] ?? data['walletBalance'] ?? 0).toDouble(),
      totalMeritPoints: data['merit_points_total'] ?? data['totalMeritPoints'] ?? 0,
      preferredMode: data['preferredMode'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convert to Firestore document (v5.0 schema)
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'full_name': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'matric_no': matricNo,
      'role': role.code,
      'isStudent': isStudent,
      'badges': badges,
      'wallet_balance': walletBalance,
      'merit_points_total': totalMeritPoints,
      'preferredMode': preferredMode,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
    };
  }

  /// Create new user from email
  factory UserModel.create({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) {
    final isStudentEmail =
        email.toLowerCase().endsWith(AppConstants.studentEmailDomain);

    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      role: isStudentEmail ? UserRole.student : UserRole.public,
      isStudent: isStudentEmail,
      createdAt: DateTime.now(),
    );
  }

  /// Copy with method for updates
  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? matricNo,
    UserRole? role,
    List<String>? badges,
    double? walletBalance,
    int? totalMeritPoints,
    String? preferredMode,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      matricNo: matricNo ?? this.matricNo,
      role: role ?? this.role,
      isStudent: isStudent,
      badges: badges ?? this.badges,
      walletBalance: walletBalance ?? this.walletBalance,
      totalMeritPoints: totalMeritPoints ?? this.totalMeritPoints,
      preferredMode: preferredMode ?? this.preferredMode,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, role: ${role.displayName})';
  }
}

