import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';

/// Referee job model for SukanGig marketplace
class RefereeJobModel {
  final String id;
  final String bookingId;
  final String facilityId;
  final String facilityName;
  final SportType sport;
  final DateTime matchDate;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final double earnings;
  final int refereesRequired;
  final List<AssignedReferee> assignedReferees;
  final JobStatus status;
  final String organizerUserId;
  final String organizerName;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RefereeJobModel({
    required this.id,
    required this.bookingId,
    required this.facilityId,
    required this.facilityName,
    required this.sport,
    required this.matchDate,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.earnings,
    required this.refereesRequired,
    this.assignedReferees = const [],
    required this.status,
    required this.organizerUserId,
    required this.organizerName,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get job role description based on sport
  String get roleDescription {
    switch (sport) {
      case SportType.football:
        return 'Referee Crew (1 Main + 2 Linesmen)';
      case SportType.futsal:
        return 'Solo Referee';
      case SportType.badminton:
        return 'Umpire';
      case SportType.tennis:
        return 'Chair Umpire';
    }
  }

  /// Check if job still needs referees
  bool get needsReferees => assignedReferees.length < refereesRequired;

  /// Get remaining slots
  int get remainingSlots => refereesRequired - assignedReferees.length;

  /// Check if specific user is assigned
  bool isUserAssigned(String userId) {
    return assignedReferees.any((r) => r.userId == userId);
  }

  /// Get assigned referee by user ID
  AssignedReferee? getAssignedReferee(String userId) {
    try {
      return assignedReferees.firstWhere((r) => r.userId == userId);
    } catch (_) {
      return null;
    }
  }

  /// Check if job is completed
  bool get isCompleted => status == JobStatus.completed;

  /// Check if job is still available for applications
  bool get isAvailable =>
      status == JobStatus.open && needsReferees;

  /// Factory constructor from Firestore
  factory RefereeJobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle matchDate (required)
    final matchDate = (data['matchDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    // Handle startTime (may be null in older documents - fallback to matchDate)
    final startTime = (data['startTime'] as Timestamp?)?.toDate() ?? matchDate;
    
    // Handle endTime (may be null in older documents - fallback to matchDate + 2 hours)
    final endTime = (data['endTime'] as Timestamp?)?.toDate() ?? matchDate.add(const Duration(hours: 2));
    
    return RefereeJobModel(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      facilityId: data['facilityId'] ?? '',
      facilityName: data['facilityName'] ?? '',
      sport: SportType.fromCode(data['sport'] ?? 'FUTSAL'),
      matchDate: matchDate,
      startTime: startTime,
      endTime: endTime,
      location: data['location'] ?? '',
      earnings: (data['earnings'] ?? AppConstants.refereeEarningsTournament)
          .toDouble(),
      refereesRequired: data['refereesRequired'] ?? 1,
      assignedReferees: (data['assignedReferees'] as List? ?? [])
          .map((r) => AssignedReferee.fromMap(r))
          .toList(),
      status: JobStatus.fromCode(data['status'] ?? 'OPEN'),
      organizerUserId: data['organizerUserId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      notes: data['notes'],
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'facilityId': facilityId,
      'facilityName': facilityName,
      'sport': sport.code,
      'matchDate': Timestamp.fromDate(matchDate),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'earnings': earnings,
      'refereesRequired': refereesRequired,
      'assignedReferees': assignedReferees.map((r) => r.toMap()).toList(),
      'status': status.code,
      'organizerUserId': organizerUserId,
      'organizerName': organizerName,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  RefereeJobModel copyWith({
    String? bookingId,
    String? facilityId,
    String? facilityName,
    SportType? sport,
    DateTime? matchDate,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    double? earnings,
    int? refereesRequired,
    List<AssignedReferee>? assignedReferees,
    JobStatus? status,
    String? organizerUserId,
    String? organizerName,
    String? notes,
  }) {
    return RefereeJobModel(
      id: id,
      bookingId: bookingId ?? this.bookingId,
      facilityId: facilityId ?? this.facilityId,
      facilityName: facilityName ?? this.facilityName,
      sport: sport ?? this.sport,
      matchDate: matchDate ?? this.matchDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      earnings: earnings ?? this.earnings,
      refereesRequired: refereesRequired ?? this.refereesRequired,
      assignedReferees: assignedReferees ?? this.assignedReferees,
      status: status ?? this.status,
      organizerUserId: organizerUserId ?? this.organizerUserId,
      organizerName: organizerName ?? this.organizerName,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'RefereeJobModel(id: $id, sport: ${sport.displayName}, status: ${status.displayName})';
  }
}

/// Assigned referee information
class AssignedReferee {
  final String oderId;
  final String userId;
  final String name;
  final String email;
  final RefereeRole role;
  final bool hasCheckedIn;
  final DateTime? checkedInAt;
  final bool hasBeenRated;
  final double? rating;
  final DateTime assignedAt;

  const AssignedReferee({
    required this.oderId,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.hasCheckedIn = false,
    this.checkedInAt,
    this.hasBeenRated = false,
    this.rating,
    required this.assignedAt,
  });

  factory AssignedReferee.fromMap(Map<String, dynamic> map) {
    return AssignedReferee(
      oderId: map['oderId'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: RefereeRole.fromCode(map['role'] ?? 'SOLO'),
      hasCheckedIn: map['hasCheckedIn'] ?? false,
      checkedInAt: map['checkedInAt'] != null
          ? (map['checkedInAt'] as Timestamp).toDate()
          : null,
      hasBeenRated: map['hasBeenRated'] ?? false,
      rating: map['rating']?.toDouble(),
      assignedAt: map['assignedAt'] != null
          ? (map['assignedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'oderId': oderId,
      'userId': userId,
      'name': name,
      'email': email,
      'role': role.code,
      'hasCheckedIn': hasCheckedIn,
      'checkedInAt':
          checkedInAt != null ? Timestamp.fromDate(checkedInAt!) : null,
      'hasBeenRated': hasBeenRated,
      'rating': rating,
      'assignedAt': Timestamp.fromDate(assignedAt),
    };
  }

  AssignedReferee copyWith({
    bool? hasCheckedIn,
    DateTime? checkedInAt,
    bool? hasBeenRated,
    double? rating,
  }) {
    return AssignedReferee(
      oderId: oderId,
      userId: userId,
      name: name,
      email: email,
      role: role,
      hasCheckedIn: hasCheckedIn ?? this.hasCheckedIn,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      hasBeenRated: hasBeenRated ?? this.hasBeenRated,
      rating: rating ?? this.rating,
      assignedAt: assignedAt,
    );
  }
}

/// Referee roles for football crew
enum RefereeRole {
  mainReferee('MAIN', 'Main Referee'),
  linesman('LINESMAN', 'Linesman'),
  solo('SOLO', 'Referee');

  final String code;
  final String displayName;
  const RefereeRole(this.code, this.displayName);

  static RefereeRole fromCode(String code) {
    return RefereeRole.values.firstWhere(
      (e) => e.code == code,
      orElse: () => RefereeRole.solo,
    );
  }
}

