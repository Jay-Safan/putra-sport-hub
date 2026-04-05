import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/notifications/data/models/notification_model.dart';
import 'service_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATION PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// User notifications stream provider
final userNotificationsProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
      return ref
          .watch(notificationServiceProvider)
          .getUserNotifications(userId);
    });

/// Unread notifications count provider
final unreadNotificationsCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  return ref.watch(notificationServiceProvider).getUnreadCount(userId);
});
