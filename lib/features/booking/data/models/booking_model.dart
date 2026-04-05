import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';

/// Booking model for facility reservations
class BookingModel {
  final String id;
  final String facilityId;
  final String facilityName;
  final SportType sport;
  final String userId;
  final String userName;
  final String userEmail;
  final bool isStudentBooking;
  final String? subUnit; // For badminton court selection
  final DateTime bookingDate;
  final DateTime startTime;
  final DateTime endTime;
  final double facilityFee;
  final double? refereeFee;
  final double totalAmount;
  final BookingStatus status;
  final String? refereeJobId;
  final BookingType? bookingType; // 'PRACTICE' or 'MATCH'
  final TournamentFormat? tournamentFormat; // Tournament format if Match
  final int? tournamentTeams; // Number of teams in tournament
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final String? qrCode;
  final bool isCheckedIn;
  final DateTime? checkedInAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const BookingModel({
    required this.id,
    required this.facilityId,
    required this.facilityName,
    required this.sport,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.isStudentBooking,
    this.subUnit,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.facilityFee,
    this.refereeFee,
    required this.totalAmount,
    required this.status,
    this.refereeJobId,
    this.bookingType,
    this.tournamentFormat,
    this.tournamentTeams,
    this.cancellationReason,
    this.cancelledAt,
    this.qrCode,
    this.isCheckedIn = false,
    this.checkedInAt,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Get duration in hours
  int get durationHours => endTime.difference(startTime).inHours;

  /// Check if booking is active (not cancelled/completed)
  bool get isActive =>
      status != BookingStatus.cancelled &&
      status != BookingStatus.completed &&
      status != BookingStatus.refunded;

  /// Check if booking can be cancelled (24 hours rule)
  bool get canCancel {
    if (!isActive) return false;
    final now = DateTime.now();
    final hoursUntilBooking = startTime.difference(now).inHours;
    return hoursUntilBooking >= AppConstants.cancellationHoursThreshold;
  }

  /// Check if booking is eligible for refund
  bool get isRefundEligible => canCancel;

  /// Factory constructor from Firestore
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      facilityId: data['facilityId'] ?? '',
      facilityName: data['facilityName'] ?? '',
      sport: SportType.fromCode(data['sport'] ?? 'FUTSAL'),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      isStudentBooking: data['isStudentBooking'] ?? false,
      subUnit: data['subUnit'],
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      facilityFee: (data['facilityFee'] ?? 0).toDouble(),
      refereeFee: data['refereeFee']?.toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: BookingStatus.fromCode(data['status'] ?? 'PENDING_PAYMENT'),
      refereeJobId: data['refereeJobId'],
      bookingType:
          data['bookingType'] != null
              ? BookingType.fromCode(data['bookingType'])
              : null,
      tournamentFormat:
          data['tournamentFormat'] != null
              ? TournamentFormat.fromCode(data['tournamentFormat'])
              : null,
      tournamentTeams: data['tournamentTeams'],
      cancellationReason: data['cancellationReason'],
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      qrCode: data['qrCode'],
      isCheckedIn: data['isCheckedIn'] ?? false,
      checkedInAt: (data['checkedInAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'facilityId': facilityId,
      'facilityName': facilityName,
      'sport': sport.code,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'isStudentBooking': isStudentBooking,
      'subUnit': subUnit,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'facilityFee': facilityFee,
      'refereeFee': refereeFee,
      'totalAmount': totalAmount,
      'status': status.code,
      'refereeJobId': refereeJobId,
      'bookingType': bookingType?.code,
      'tournamentFormat': tournamentFormat?.code,
      'tournamentTeams': tournamentTeams,
      'cancellationReason': cancellationReason,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'qrCode': qrCode,
      'isCheckedIn': isCheckedIn,
      'checkedInAt':
          checkedInAt != null ? Timestamp.fromDate(checkedInAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'metadata': metadata,
    };
  }

  BookingModel copyWith({
    String? facilityId,
    String? facilityName,
    SportType? sport,
    String? userId,
    String? userName,
    String? userEmail,
    bool? isStudentBooking,
    String? subUnit,
    DateTime? bookingDate,
    DateTime? startTime,
    DateTime? endTime,
    double? facilityFee,
    double? refereeFee,
    double? totalAmount,
    BookingStatus? status,
    String? refereeJobId,
    BookingType? bookingType,
    TournamentFormat? tournamentFormat,
    int? tournamentTeams,
    String? cancellationReason,
    DateTime? cancelledAt,
    String? qrCode,
    bool? isCheckedIn,
    DateTime? checkedInAt,
    Map<String, dynamic>? metadata,
  }) {
    return BookingModel(
      id: id,
      facilityId: facilityId ?? this.facilityId,
      facilityName: facilityName ?? this.facilityName,
      sport: sport ?? this.sport,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      isStudentBooking: isStudentBooking ?? this.isStudentBooking,
      subUnit: subUnit ?? this.subUnit,
      bookingDate: bookingDate ?? this.bookingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      facilityFee: facilityFee ?? this.facilityFee,
      refereeFee: refereeFee ?? this.refereeFee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      refereeJobId: refereeJobId ?? this.refereeJobId,
      bookingType: bookingType ?? this.bookingType,
      tournamentFormat: tournamentFormat ?? this.tournamentFormat,
      tournamentTeams: tournamentTeams ?? this.tournamentTeams,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      qrCode: qrCode ?? this.qrCode,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'BookingModel(id: $id, facility: $facilityName, status: ${status.displayName})';
  }
}
