import 'package:cloud_firestore/cloud_firestore.dart';

/// Tournament team model representing a registered team in a tournament
class TournamentTeamModel {
  final String teamId;
  final String teamName;
  final String captainId;
  final String captainName;
  final String captainEmail;
  final List<String> memberIds; // User IDs of team members
  final List<String> memberNames; // Names of team members
  final DateTime registeredAt;
  final bool paidEntryFee;
  final String? entryFeeTransactionId;
  final int? seed; // For bracket seeding

  const TournamentTeamModel({
    required this.teamId,
    required this.teamName,
    required this.captainId,
    required this.captainName,
    required this.captainEmail,
    this.memberIds = const [],
    this.memberNames = const [],
    required this.registeredAt,
    this.paidEntryFee = false,
    this.entryFeeTransactionId,
    this.seed,
  });

  /// Get total team members count (captain + members)
  int get totalMembers => 1 + memberIds.length;

  /// Check if user is part of this team
  bool isMember(String userId) {
    return captainId == userId || memberIds.contains(userId);
  }

  /// Factory constructor from Firestore
  factory TournamentTeamModel.fromFirestore(Map<String, dynamic> data) {
    return TournamentTeamModel(
      teamId: data['teamId'] ?? '',
      teamName: data['teamName'] ?? '',
      captainId: data['captainId'] ?? '',
      captainName: data['captainName'] ?? '',
      captainEmail: data['captainEmail'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberNames: List<String>.from(data['memberNames'] ?? []),
      registeredAt: (data['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidEntryFee: data['paidEntryFee'] ?? false,
      entryFeeTransactionId: data['entryFeeTransactionId'],
      seed: data['seed'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'captainId': captainId,
      'captainName': captainName,
      'captainEmail': captainEmail,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'paidEntryFee': paidEntryFee,
      'entryFeeTransactionId': entryFeeTransactionId,
      'seed': seed,
    };
  }

  TournamentTeamModel copyWith({
    String? teamName,
    List<String>? memberIds,
    List<String>? memberNames,
    bool? paidEntryFee,
    String? entryFeeTransactionId,
    int? seed,
  }) {
    return TournamentTeamModel(
      teamId: teamId,
      teamName: teamName ?? this.teamName,
      captainId: captainId,
      captainName: captainName,
      captainEmail: captainEmail,
      memberIds: memberIds ?? this.memberIds,
      memberNames: memberNames ?? this.memberNames,
      registeredAt: registeredAt,
      paidEntryFee: paidEntryFee ?? this.paidEntryFee,
      entryFeeTransactionId: entryFeeTransactionId ?? this.entryFeeTransactionId,
      seed: seed ?? this.seed,
    );
  }
}

