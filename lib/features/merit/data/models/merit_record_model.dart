import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';

/// Merit record model for MyMerit academic integration
/// Reference: UPM/KK/TAD/GP08 (Garis Panduan Pengiraan Merit)
/// 
/// GP08 Codes:
/// - B1: Player participation (+2 points)
/// - B2: Official/Referee service (+3 points, Leadership)
/// - B3: Tournament organizer (+5 points)
/// 
/// Cap: Maximum 15 points per semester
class MeritRecordModel {
  final String id;
  final String oderId;
  final String userId;
  final String userEmail;
  final String userName;
  final String? matricNo;
  final MeritCategory category;
  final MeritActivityType activityType;
  final SportType sport;
  final String activityDescription;
  final int points;
  final String gp08Code; // B1, B2, or B3 (v5.0 spec)
  final String? referenceId; // Booking ID or Job ID
  final DateTime activityDate;
  final bool isVerified;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? semester;
  final String? academicYear;
  final DateTime createdAt;

  const MeritRecordModel({
    required this.id,
    required this.oderId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.matricNo,
    required this.category,
    required this.activityType,
    required this.sport,
    required this.activityDescription,
    required this.points,
    required this.gp08Code,
    this.referenceId,
    required this.activityDate,
    this.isVerified = false,
    this.verifiedBy,
    this.verifiedAt,
    this.semester,
    this.academicYear,
    required this.createdAt,
  });

  /// Generate activity description based on type
  static String generateDescription(
      MeritActivityType type, SportType sport, String facilityName) {
    switch (type) {
      case MeritActivityType.playerParticipation:
        return 'Participated in ${sport.displayName} at $facilityName';
      case MeritActivityType.refereeService:
        return 'Served as ${sport.displayName} referee at $facilityName';
      case MeritActivityType.sukolOrganizer:
        return 'Organized SUKOL ${sport.displayName} tournament';
      case MeritActivityType.sukolParticipant:
        return 'Participated in SUKOL ${sport.displayName} tournament';
    }
  }

  /// Get points based on activity type (GP08 rules)
  static int getPointsForActivity(MeritActivityType type) {
    switch (type) {
      case MeritActivityType.playerParticipation:
        return AppConstants.meritPointsPlayer; // B1: +2
      case MeritActivityType.refereeService:
        return AppConstants.meritPointsReferee; // B2: +3
      case MeritActivityType.sukolOrganizer:
        return AppConstants.meritPointsOrganizer; // B3: +5
      case MeritActivityType.sukolParticipant:
        return AppConstants.meritPointsPlayer; // B1: +2
    }
  }

  /// Get GP08 code based on activity type
  static String getGp08Code(MeritActivityType type) {
    switch (type) {
      case MeritActivityType.playerParticipation:
      case MeritActivityType.sukolParticipant:
        return AppConstants.meritCodePlayer; // B1
      case MeritActivityType.refereeService:
        return AppConstants.meritCodeReferee; // B2
      case MeritActivityType.sukolOrganizer:
        return AppConstants.meritCodeOrganizer; // B3
    }
  }

  /// Factory constructor from Firestore (v5.0 schema: merit_logs)
  factory MeritRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final activityType = MeritActivityType.fromCode(data['activityType'] ?? data['activity_name'] ?? 'PLAYER');
    return MeritRecordModel(
      id: doc.id,
      oderId: data['oderId'] ?? data['log_id'] ?? '',
      userId: data['userId'] ?? data['user_id'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? data['activity_name'] ?? '',
      matricNo: data['matricNo'],
      category: MeritCategory.fromCode(data['category'] ?? 'SPORTS'),
      activityType: activityType,
      sport: SportType.fromCode(data['sport'] ?? 'FUTSAL'),
      activityDescription: data['activityDescription'] ?? data['activity_name'] ?? '',
      points: data['points'] ?? 0,
      gp08Code: data['gp08_code'] ?? data['gp08Code'] ?? getGp08Code(activityType),
      referenceId: data['referenceId'],
      activityDate: (data['activityDate'] as Timestamp?)?.toDate() ?? 
                    (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: data['isVerified'] ?? false,
      verifiedBy: data['verifiedBy'],
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      semester: data['semester'],
      academicYear: data['academicYear'],
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document (v5.0 schema: merit_logs)
  Map<String, dynamic> toFirestore() {
    return {
      'log_id': oderId,
      'user_id': userId,
      'userEmail': userEmail,
      'activity_name': activityDescription,
      'matricNo': matricNo,
      'category': category.code,
      'activityType': activityType.code,
      'sport': sport.code,
      'activityDescription': activityDescription,
      'points': points,
      'gp08_code': gp08Code, // v5.0: B1, B2, or B3
      'referenceId': referenceId,
      'activityDate': Timestamp.fromDate(activityDate),
      'timestamp': Timestamp.fromDate(activityDate), // v5.0 field name
      'isVerified': isVerified,
      'verifiedBy': verifiedBy,
      'verifiedAt':
          verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'semester': semester,
      'academicYear': academicYear,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create merit record for player participation (GP08 Code: B1)
  factory MeritRecordModel.forPlayer({
    required String oderId,
    required String oderId2,
    required String oderId3,
    required String userId,
    required String userEmail,
    required String userName,
    String? matricNo,
    required SportType sport,
    required String facilityName,
    required String bookingId,
    required DateTime activityDate,
  }) {
    return MeritRecordModel(
      id: '',
      oderId: oderId3,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      matricNo: matricNo,
      category: MeritCategory.sports,
      activityType: MeritActivityType.playerParticipation,
      sport: sport,
      activityDescription: generateDescription(
        MeritActivityType.playerParticipation,
        sport,
        facilityName,
      ),
      points: getPointsForActivity(MeritActivityType.playerParticipation),
      gp08Code: AppConstants.meritCodePlayer, // B1
      referenceId: bookingId,
      activityDate: activityDate,
      createdAt: DateTime.now(),
    );
  }

  /// Create merit record for referee service (GP08 Code: B2 - Leadership)
  factory MeritRecordModel.forReferee({
    required String oderId,
    required String oderId2,
    required String oderId3,
    required String userId,
    required String userEmail,
    required String userName,
    String? matricNo,
    required SportType sport,
    required String facilityName,
    required String jobId,
    required DateTime activityDate,
  }) {
    return MeritRecordModel(
      id: '',
      oderId: oderId3,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      matricNo: matricNo,
      category: MeritCategory.leadership, // B2 counts as leadership
      activityType: MeritActivityType.refereeService,
      sport: sport,
      activityDescription: generateDescription(
        MeritActivityType.refereeService,
        sport,
        facilityName,
      ),
      points: getPointsForActivity(MeritActivityType.refereeService),
      gp08Code: AppConstants.meritCodeReferee, // B2
      referenceId: jobId,
      activityDate: activityDate,
      createdAt: DateTime.now(),
    );
  }

  MeritRecordModel copyWith({
    bool? isVerified,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? semester,
    String? academicYear,
    String? gp08Code,
  }) {
    return MeritRecordModel(
      id: id,
      oderId: oderId,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      matricNo: matricNo,
      category: category,
      activityType: activityType,
      sport: sport,
      activityDescription: activityDescription,
      points: points,
      gp08Code: gp08Code ?? this.gp08Code,
      referenceId: referenceId,
      activityDate: activityDate,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      semester: semester ?? this.semester,
      academicYear: academicYear ?? this.academicYear,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'MeritRecordModel(id: $id, type: ${activityType.displayName}, points: $points)';
  }
}

/// Merit categories based on UPM GP08
enum MeritCategory {
  sports('SPORTS', 'Sports & Recreation'),
  leadership('LEADERSHIP', 'Leadership & Service'),
  community('COMMUNITY', 'Community Service'),
  academic('ACADEMIC', 'Academic Excellence');

  final String code;
  final String displayName;
  const MeritCategory(this.code, this.displayName);

  static MeritCategory fromCode(String code) {
    return MeritCategory.values.firstWhere(
      (e) => e.code == code,
      orElse: () => MeritCategory.sports,
    );
  }
}

/// Merit activity types
enum MeritActivityType {
  playerParticipation('PLAYER', 'Player Participation'),
  refereeService('REFEREE', 'Referee Service'),
  sukolOrganizer('SUKOL_ORG', 'SUKOL Organizer'),
  sukolParticipant('SUKOL_PART', 'SUKOL Participant');

  final String code;
  final String displayName;
  const MeritActivityType(this.code, this.displayName);

  static MeritActivityType fromCode(String code) {
    return MeritActivityType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => MeritActivityType.playerParticipation,
    );
  }
}

