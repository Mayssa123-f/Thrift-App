
import 'package:thrift_app/models/notification_model.dart';

import '../services/notification_service.dart';

class NotificationController {
  final NotificationService _notificationService = NotificationService();

  Future<List<NotificationModel>> getNotifications() async {
    return await _notificationService.getNotifications();
  }

  Future<int> getUnreadCount() async {
    return await _notificationService.getUnreadCount();
  }

  Future<void> markAsRead(int notificationId) async {
    await _notificationService.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    await _notificationService.markAllAsRead();
  }

  Future<void> clearNotifications() async {
    await _notificationService.clearNotifications();
  }
}