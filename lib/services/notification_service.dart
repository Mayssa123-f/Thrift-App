import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
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

      _showInAppBanner(message);
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
    try {
      final token = await FirebaseMessaging.instance.getToken();

      if (token == null || token.isEmpty) return;

      await dio.post(
        '/notifications/token',
        data: {'token': token, 'platform': 'android'},
      );
    } on DioException catch (e) {
      debugPrint(
        'Skipping FCM token sync: ${e.response?.statusCode ?? e.type}',
      );
    } catch (e) {
      debugPrint('Skipping FCM token sync: $e');
    }
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

  void _showInAppBanner(RemoteMessage message) {
    final overlay = navigatorKey.currentState?.overlay;

    if (overlay == null) {
      print('Overlay is null');
      return;
    }

    final notification = message.notification;

    if (notification == null) return;

    final String? imageUrl =
        message.data['actor_image'] ??
        message.data['sender_image'] ??
        message.data['buyer_image'];

    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 4,
          left: 14,
          right: 14,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -60, end: 0),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {
                  overlayEntry?.remove();

                  final conversationId = message.data['conversation_id'];

                  if (conversationId != null) {
                    _openChatFromNotification(conversationId);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.26),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PROFILE IMAGE
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: ClipOval(
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return const Icon(
                                      Icons.person_outline_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.person_outline_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title ?? 'VINTY',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  'now',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 7),

                            Text(
                              notification.body ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.72),
                                fontSize: 12,
                                height: 1.35,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);

    Timer(const Duration(seconds: 4), () {
      overlayEntry?.remove();
    });
  }
}
