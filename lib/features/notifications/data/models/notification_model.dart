import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';

/// Notification model for in-app notifications
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedId; // bookingId, jobId, tournamentId, etc.
  final Map<String, dynamic>? data; // Additional data for deep linking
  final String? route; // Route to navigate when tapped

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
    this.relatedId,
    this.data,
    this.route,
  });

  /// Factory constructor from Firestore
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.fromCode(data['type'] ?? 'GENERAL'),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      relatedId: data['relatedId'],
      data: data['data'] != null ? Map<String, dynamic>.from(data['data']) : null,
      route: data['route'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.code,
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'relatedId': relatedId,
      'data': data,
      'route': route,
    };
  }

  /// Create a copy with modified fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
    String? relatedId,
    Map<String, dynamic>? data,
    String? route,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      relatedId: relatedId ?? this.relatedId,
      data: data ?? this.data,
      route: route ?? this.route,
    );
  }

  /// Get icon for notification type
  String get icon {
    switch (type) {
      case NotificationType.bookingConfirmed:
        return '🎉';
      case NotificationType.bookingCancelled:
        return '❌';
      case NotificationType.bookingReminder24h:
      case NotificationType.bookingReminder1h:
        return '⏰';
      case NotificationType.paymentReceived:
        return '💰';
      case NotificationType.paymentFailed:
        return '⚠️';
      case NotificationType.refundProcessed:
        return '💸';
      case NotificationType.refereeJobAssigned:
        return '🏆';
      case NotificationType.refereeJobCancelled:
        return '🚫';
      case NotificationType.refereePaymentReleased:
        return '💵';
      case NotificationType.splitBillRequest:
        return '👥';
      case NotificationType.splitBillPaid:
        return '✅';
      case NotificationType.tournamentCreated:
        return '🏅';
      case NotificationType.tournamentRegistrationOpen:
      case NotificationType.tournamentRegistrationClosed:
        return '🎯';
      case NotificationType.weatherWarning:
        return '🌧️';
      case NotificationType.meritPointsAwarded:
        return '⭐';
      case NotificationType.general:
        return '📢';
    }
  }
}

