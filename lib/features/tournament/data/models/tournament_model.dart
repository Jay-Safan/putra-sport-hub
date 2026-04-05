import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import 'tournament_team_model.dart';

// Import TournamentStatus enum
export '../../../../core/constants/app_constants.dart' show TournamentStatus;

/// Tournament model representing a complete tournament event
/// This is a standalone tournament with its own lifecycle, independent of bookings
class TournamentModel {
  // Identity
  final String id;
  final String title;
  final String? description;
  final SportType sport;

  // Organizer
  final String organizerId;
  final String organizerName;
  final String organizerEmail;

  // Format & Structure
  final TournamentFormat format;
  final int maxTeams;
  final int currentTeams;
  final double? entryFee; // Optional, can be free
  final double? firstPlacePrize; // Optional prize money for winner
  final double? organizerFee; // Optional organizer commission
  final bool isStudentOnly;

  // Scheduling
  final DateTime registrationDeadline;
  final DateTime startDate;
  final DateTime? endDate; // For multi-day tournaments
  final Duration matchDuration; // Per match time (e.g., 2 hours)

  // Facility & Booking
  final String facilityId;
  final String facilityName;
  final String venue;
  final String? bookingId; // Reference to underlying booking (if created)

  // Referee Package
  final int refereesRequired;
  final double refereeFeeTotal;
  final List<String> refereeJobIds; // Auto-created referee jobs
  final List<String>
  refereeUserIds; // Denormalized list of referee user IDs for O(1) role checking

  // Participants
  final List<TournamentTeamModel> teams;
  final Map<String, dynamic>? bracketData; // Bracket structure

  // Sharing & Discovery
  final String shareCode; // e.g., "TOURNAMENT-EAGLE-123"
  final bool isPublic; // Show in hub vs. private invite-only

  // Status
  final TournamentStatus status;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const TournamentModel({
    required this.id,
    required this.title,
    this.description,
    required this.sport,
    required this.organizerId,
    required this.organizerName,
    required this.organizerEmail,
    required this.format,
    required this.maxTeams,
    this.currentTeams = 0,
    this.entryFee,
    this.firstPlacePrize,
    this.organizerFee,
    this.isStudentOnly = true,
    required this.registrationDeadline,
    required this.startDate,
    this.endDate,
    required this.matchDuration,
    required this.facilityId,
    required this.facilityName,
    required this.venue,
    this.bookingId,
    required this.refereesRequired,
    required this.refereeFeeTotal,
    this.refereeJobIds = const [],
    this.refereeUserIds = const [],
    this.teams = const [],
    this.bracketData,
    required this.shareCode,
    this.isPublic = true,
    this.status = TournamentStatus.registrationOpen,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Check if registration is still open
  bool get isRegistrationOpen {
    return status == TournamentStatus.registrationOpen &&
        DateTime.now().isBefore(registrationDeadline) &&
        teams.length < maxTeams;
  }

  /// Check if tournament has available slots
  bool get hasAvailableSlots => teams.length < maxTeams;

  /// Get remaining slots
  int get remainingSlots => maxTeams - teams.length;

  /// Check if user is organizer
  bool isOrganizer(String userId) => organizerId == userId;

  /// Check if user is part of any team
  bool isUserParticipating(String userId) {
    return teams.any((team) => team.isMember(userId));
  }

  /// Check if user is a referee for this tournament
  bool isUserReferee(String userId) {
    return refereeUserIds.contains(userId);
  }

  /// Get team user belongs to (if any)
  TournamentTeamModel? getUserTeam(String userId) {
    try {
      return teams.firstWhere((team) => team.isMember(userId));
    } catch (e) {
      return null;
    }
  }

  /// Check if tournament is full
  bool get isFull => teams.length >= maxTeams;

  /// Factory constructor from Firestore
  factory TournamentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TournamentModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      sport: SportType.fromCode(data['sport'] ?? 'FOOTBALL'),
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      organizerEmail: data['organizerEmail'] ?? '',
      format:
          TournamentFormat.fromCode(data['format']) ??
          TournamentFormat.eightTeamKnockout,
      maxTeams: data['maxTeams'] ?? 8,
      currentTeams: data['currentTeams'] ?? 0,
      entryFee: data['entryFee']?.toDouble(),
      firstPlacePrize: data['firstPlacePrize']?.toDouble(),
      organizerFee: data['organizerFee']?.toDouble(),
      isStudentOnly: data['isStudentOnly'] ?? true,
      registrationDeadline:
          (data['registrationDeadline'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      matchDuration: Duration(
        minutes: data['matchDurationMinutes'] ?? 120, // Default 2 hours
      ),
      facilityId: data['facilityId'] ?? '',
      facilityName: data['facilityName'] ?? '',
      venue: data['venue'] ?? '',
      bookingId: data['bookingId'],
      refereesRequired: data['refereesRequired'] ?? 1,
      refereeFeeTotal: (data['refereeFeeTotal'] ?? 0).toDouble(),
      refereeJobIds: List<String>.from(data['refereeJobIds'] ?? []),
      refereeUserIds: List<String>.from(
        data['refereeUserIds'] ?? [],
      ), // Backward compatible: treat missing as empty
      teams:
          (data['teams'] as List<dynamic>?)
              ?.map(
                (t) => TournamentTeamModel.fromFirestore(
                  Map<String, dynamic>.from(t),
                ),
              )
              .toList() ??
          [],
      bracketData: data['bracketData'],
      shareCode: data['shareCode'] ?? '',
      isPublic: data['isPublic'] ?? true,
      status: TournamentStatus.fromCode(data['status'] ?? 'REGISTRATION_OPEN'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'sport': sport.code,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'organizerEmail': organizerEmail,
      'format': format.code,
      'maxTeams': maxTeams,
      'currentTeams': currentTeams,
      'entryFee': entryFee,
      'firstPlacePrize': firstPlacePrize,
      'organizerFee': organizerFee,
      'isStudentOnly': isStudentOnly,
      'registrationDeadline': Timestamp.fromDate(registrationDeadline),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'matchDurationMinutes': matchDuration.inMinutes,
      'facilityId': facilityId,
      'facilityName': facilityName,
      'venue': venue,
      'bookingId': bookingId,
      'refereesRequired': refereesRequired,
      'refereeFeeTotal': refereeFeeTotal,
      'refereeJobIds': refereeJobIds,
      'refereeUserIds': refereeUserIds,
      'teams': teams.map((t) => t.toFirestore()).toList(),
      'bracketData': bracketData,
      'shareCode': shareCode,
      'isPublic': isPublic,
      'status': status.code,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  TournamentModel copyWith({
    String? title,
    String? description,
    int? currentTeams,
    TournamentStatus? status,
    List<TournamentTeamModel>? teams,
    Map<String, dynamic>? bracketData,
    String? bookingId,
    List<String>? refereeJobIds,
    List<String>? refereeUserIds,
    DateTime? endDate,
  }) {
    return TournamentModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      sport: sport,
      organizerId: organizerId,
      organizerName: organizerName,
      organizerEmail: organizerEmail,
      format: format,
      maxTeams: maxTeams,
      currentTeams: currentTeams ?? this.currentTeams,
      entryFee: entryFee,
      firstPlacePrize: firstPlacePrize,
      organizerFee: organizerFee,
      isStudentOnly: isStudentOnly,
      registrationDeadline: registrationDeadline,
      startDate: startDate,
      endDate: endDate ?? this.endDate,
      matchDuration: matchDuration,
      facilityId: facilityId,
      facilityName: facilityName,
      venue: venue,
      bookingId: bookingId ?? this.bookingId,
      refereesRequired: refereesRequired,
      refereeFeeTotal: refereeFeeTotal,
      refereeJobIds: refereeJobIds ?? this.refereeJobIds,
      refereeUserIds: refereeUserIds ?? this.refereeUserIds,
      teams: teams ?? this.teams,
      bracketData: bracketData ?? this.bracketData,
      shareCode: shareCode,
      isPublic: isPublic,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      metadata: metadata,
    );
  }
}
