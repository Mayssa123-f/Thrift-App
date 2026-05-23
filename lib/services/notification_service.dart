import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:thrift_app/controllers/chat_controller.dart';
import 'package:thrift_app/main.dart';
import 'package:thrift_app/models/notification_model.dart';
import 'package:thrift_app/screens/chat/chat_room_screen.dart';

import 'api_client.dart';

class NotificationService {
  final dio = ApiClient.dio;
  static bool _initialized = false;
  static int? activeConversationId;
  static VoidCallback? onNotificationReceived;
  static VoidCallback? onNotificationListShouldRefresh;
  static void setActiveConversation(int? conversationId) {
    activeConversationId = conversationId;
  }

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    _initialized = true;
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final conversationId = response.payload;

        if (conversationId == null) return;

        _openChatFromNotification(conversationId);
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'messages_channel',
      'Messages',
      description: 'Notifications for new messages',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;

      if (notification == null) return;

      final incomingConversationId = int.tryParse(
        message.data['conversation_id'] ?? '',
      );

      if (incomingConversationId != null &&
          incomingConversationId == activeConversationId) {
        print('User already inside this chat. Notification skipped.');
        return;
      }
      onNotificationReceived?.call();
      onNotificationListShouldRefresh?.call();
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'messages_channel',
            'Messages',
            channelDescription: 'Notifications for new messages',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: message.data['conversation_id'],
      );
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final conversationId = message.data['conversation_id'];

      if (conversationId == null) return;

      _openChatFromNotification(conversationId);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      final conversationId = initialMessage.data['conversation_id'];

      if (conversationId != null) {
        Future.delayed(const Duration(milliseconds: 700), () {
          _openChatFromNotification(conversationId);
        });
      }
    }
  }

  Future<void> _openChatFromNotification(String conversationId) async {
    try {
      final conversation = await ChatController().getConversationById(
        int.parse(conversationId),
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        final navigator = navigatorKey.currentState;

        if (navigator == null) {
          print('Navigator not ready yet');
          return;
        }

        navigator.push(
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(conversation: conversation),
          ),
        );
      });
    } catch (e) {
      print('Open chat from notification error: $e');
    }
  }

  Future<void> saveFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();

    if (token == null) return;

    await dio.post(
      '/notifications/token',
      data: {'token': token, 'platform': 'android'},
    );
  }

  Future<List<NotificationModel>> getNotifications() async {
    final response = await dio.get('/notifications');

    final List data = response.data['notifications'];

    return data.map((item) {
      return NotificationModel.fromJson(item);
    }).toList();
  }

  Future<int> getUnreadCount() async {
    final response = await dio.get('/notifications/unread-count');

    return response.data['unread_count'];
  }

  Future<void> markAsRead(int notificationId) async {
    await dio.patch('/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await dio.patch('/notifications/read-all');
  }

  Future<void> clearNotifications() async {
    await dio.delete('/notifications/clear');
  }
}
