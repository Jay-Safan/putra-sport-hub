import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../features/notifications/data/models/notification_model.dart';

/// Service for managing in-app notifications
class NotificationService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  NotificationService()
      : _firestore = FirebaseFirestore.instance,
        _uuid = const Uuid();

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATE NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create a new notification for a user
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? relatedId,
    Map<String, dynamic>? data,
    String? route,
  }) async {
    try {
      final notificationId = _uuid.v4();
      final notification = NotificationModel(
        id: notificationId,
        userId: userId,
        type: type,
        title: title,
        body: body,
        isRead: false,
        createdAt: DateTime.now(),
        relatedId: relatedId,
        data: data,
        route: route,
      );

      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .set(notification.toFirestore());
    } catch (e) {
      debugPrint('Error creating notification: $e');
      // Don't throw - notifications are non-critical
    }
  }

  /// Create booking confirmed notification
  Future<void> notifyBookingConfirmed({
    required String userId,
    required String bookingId,
    required String facilityName,
    required DateTime bookingDate,
    required DateTime startTime,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.bookingConfirmed,
      title: 'Booking Confirmed! 🎉',
      body: 'Your booking for $facilityName on ${_formatDate(bookingDate)} at ${_formatTime(startTime)} is confirmed.',
      relatedId: bookingId,
      route: '/bookings',
      data: {'bookingId': bookingId},
    );
  }

  /// Create booking cancelled notification
  Future<void> notifyBookingCancelled({
    required String userId,
    required String bookingId,
    required String facilityName,
    required String? reason,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.bookingCancelled,
      title: 'Booking Cancelled',
      body: reason != null
          ? 'Your booking for $facilityName has been cancelled. Reason: $reason'
          : 'Your booking for $facilityName has been cancelled.',
      relatedId: bookingId,
      route: '/bookings',
      data: {'bookingId': bookingId},
    );
  }

  /// Create booking reminder notification
  Future<void> notifyBookingReminder({
    required String userId,
    required String bookingId,
    required String facilityName,
    required DateTime startTime,
    required int hoursUntil,
  }) async {
    final type = hoursUntil >= 24
        ? NotificationType.bookingReminder24h
        : NotificationType.bookingReminder1h;

    await createNotification(
      userId: userId,
      type: type,
      title: 'Booking Reminder',
      body: 'Your booking for $facilityName is ${hoursUntil >= 24 ? "tomorrow" : "in 1 hour"} at ${_formatTime(startTime)}.',
      relatedId: bookingId,
      route: '/bookings',
      data: {'bookingId': bookingId},
    );
  }

  /// Create payment received notification
  Future<void> notifyPaymentReceived({
    required String userId,
    required String transactionId,
    required double amount,
    String? bookingId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.paymentReceived,
      title: 'Payment Received 💰',
      body: 'Payment of RM ${amount.toStringAsFixed(2)} has been received successfully.',
      relatedId: bookingId ?? transactionId,
      route: bookingId != null ? '/bookings' : '/payment/transactions',
      data: {
        'transactionId': transactionId,
        'bookingId': bookingId,
        'amount': amount,
      },
    );
  }

  /// Create payment failed notification
  Future<void> notifyPaymentFailed({
    required String userId,
    required String transactionId,
    required String reason,
    String? bookingId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.paymentFailed,
      title: 'Payment Failed ⚠️',
      body: 'Your payment failed: $reason. Please try again.',
      relatedId: bookingId ?? transactionId,
      route: bookingId != null ? '/bookings' : '/payment',
      data: {
        'transactionId': transactionId,
        'bookingId': bookingId,
      },
    );
  }

  /// Create refund processed notification
  Future<void> notifyRefundProcessed({
    required String userId,
    required String bookingId,
    required double amount,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.refundProcessed,
      title: 'Refund Processed 💸',
      body: 'A refund of RM ${amount.toStringAsFixed(2)} has been processed for your cancelled booking.',
      relatedId: bookingId,
      route: '/bookings',
      data: {
        'bookingId': bookingId,
        'amount': amount,
      },
    );
  }

  /// Create referee job assigned notification
  Future<void> notifyRefereeJobAssigned({
    required String userId,
    required String jobId,
    required String facilityName,
    required String sport,
    required DateTime matchDate,
    required DateTime startTime,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.refereeJobAssigned,
      title: 'New Referee Job! 🏆',
      body: 'You\'ve been assigned to ref a $sport match at $facilityName on ${_formatDate(matchDate)} at ${_formatTime(startTime)}.',
      relatedId: jobId,
      route: '/referee/jobs',
      data: {'jobId': jobId},
    );
  }

  /// Create referee job cancelled notification
  Future<void> notifyRefereeJobCancelled({
    required String userId,
    required String jobId,
    required String facilityName,
    required String? reason,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.refereeJobCancelled,
      title: 'Referee Job Cancelled',
      body: reason != null
          ? 'Your referee job at $facilityName has been cancelled. Reason: $reason'
          : 'Your referee job at $facilityName has been cancelled.',
      relatedId: jobId,
      route: '/referee/jobs',
      data: {'jobId': jobId},
    );
  }

  /// Create referee payment released notification
  Future<void> notifyRefereePaymentReleased({
    required String userId,
    required String jobId,
    required double amount,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.refereePaymentReleased,
      title: 'Payment Released 💵',
      body: 'Your referee payment of RM ${amount.toStringAsFixed(2)} has been released to your wallet.',
      relatedId: jobId,
      route: '/payment',
      data: {
        'jobId': jobId,
        'amount': amount,
      },
    );
  }

  /// Create split bill request notification
  Future<void> notifySplitBillRequest({
    required String userId,
    required String bookingId,
    required String organizerName,
    required double amount,
    required String teamCode,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.splitBillRequest,
      title: 'Split Bill Request 👥',
      body: '$organizerName invited you to split a bill. Your share: RM ${amount.toStringAsFixed(2)}. Team code: $teamCode',
      relatedId: bookingId,
      route: '/payment/split-bill',
      data: {
        'bookingId': bookingId,
        'teamCode': teamCode,
        'amount': amount,
      },
    );
  }

  /// Notify organizer when participant joins split bill booking
  Future<void> notifyParticipantJoined({
    required String organizerUserId,
    required String bookingId,
    required String participantName,
    required String facilityName,
    required int totalParticipants,
  }) async {
    await createNotification(
      userId: organizerUserId,
      type: NotificationType.splitBillRequest,
      title: 'New Participant Joined 👥',
      body: '$participantName joined your booking for $facilityName. Total participants: $totalParticipants',
      relatedId: bookingId,
      route: '/booking/$bookingId',
      data: {
        'bookingId': bookingId,
        'participantName': participantName,
      },
    );
  }

  /// Notify organizer when participant pays their share
  Future<void> notifyParticipantPaid({
    required String organizerUserId,
    required String bookingId,
    required String participantName,
    required double amount,
    required int paidCount,
    required int totalCount,
  }) async {
    await createNotification(
      userId: organizerUserId,
      type: NotificationType.splitBillPaid,
      title: 'Payment Received 💰',
      body: '$participantName paid RM ${amount.toStringAsFixed(2)}. Progress: $paidCount/$totalCount paid',
      relatedId: bookingId,
      route: '/booking/$bookingId',
      data: {
        'bookingId': bookingId,
        'participantName': participantName,
        'amount': amount,
      },
    );
  }

  /// Notify all participants when booking is confirmed (all paid)
  Future<void> notifySplitBillConfirmed({
    required List<String> participantUserIds,
    required String bookingId,
    required String facilityName,
    required DateTime startTime,
  }) async {
    for (final userId in participantUserIds) {
      await createNotification(
        userId: userId,
        type: NotificationType.bookingConfirmed,
        title: 'Booking Confirmed! 🎉',
        body: 'All payments received! Your booking for $facilityName on ${_formatDate(startTime)} at ${_formatTime(startTime)} is confirmed.',
        relatedId: bookingId,
        route: '/booking/$bookingId',
        data: {'bookingId': bookingId},
      );
    }
  }

  /// Create split bill paid notification (legacy - keeping for compatibility)
  Future<void> notifySplitBillPaid({
    required String userId,
    required String bookingId,
    required String participantName,
    required double amount,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.splitBillPaid,
      title: 'Split Bill Payment Received ✅',
      body: '$participantName has paid their share of RM ${amount.toStringAsFixed(2)}.',
      relatedId: bookingId,
      route: '/payment/split-bill',
      data: {
        'bookingId': bookingId,
        'amount': amount,
      },
    );
  }

  /// Create tournament created notification
  Future<void> notifyTournamentCreated({
    required String userId,
    required String tournamentId,
    required String tournamentName,
    required String sport,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.tournamentCreated,
      title: 'Tournament Created! 🏅',
      body: 'A new $sport tournament "$tournamentName" has been created. Check it out!',
      relatedId: tournamentId,
      route: '/tournaments',
      data: {'tournamentId': tournamentId},
    );
  }

  /// Create tournament registration open notification
  Future<void> notifyTournamentRegistrationOpen({
    required String userId,
    required String tournamentId,
    required String tournamentName,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.tournamentRegistrationOpen,
      title: 'Tournament Registration Open! 🎯',
      body: 'Registration for "$tournamentName" is now open. Join now!',
      relatedId: tournamentId,
      route: '/tournaments',
      data: {'tournamentId': tournamentId},
    );
  }

  /// Create weather warning notification
  Future<void> notifyWeatherWarning({
    required String userId,
    required String bookingId,
    required String facilityName,
    required DateTime bookingDate,
    required String warningMessage,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.weatherWarning,
      title: 'Weather Warning 🌧️',
      body: 'Weather alert for your booking at $facilityName on ${_formatDate(bookingDate)}: $warningMessage',
      relatedId: bookingId,
      route: '/bookings',
      data: {
        'bookingId': bookingId,
        'facilityName': facilityName,
      },
    );
  }

  /// Create merit points awarded notification
  Future<void> notifyMeritPointsAwarded({
    required String userId,
    required int points,
    required String reason,
    String? recordId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.meritPointsAwarded,
      title: 'Merit Points Awarded! ⭐',
      body: 'You\'ve earned $points merit points. Reason: $reason',
      relatedId: recordId,
      route: '/merit',
      data: {
        'points': points,
        'reason': reason,
        'recordId': recordId,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all notifications for a user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// Get unread notifications count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPDATE NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Delete all read notifications for a user
  Future<void> deleteAllRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting read notifications: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

