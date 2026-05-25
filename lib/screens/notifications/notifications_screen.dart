import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:thrift_app/models/notification_model.dart';
import 'package:thrift_app/screens/order/order_details_screen.dart';
import 'package:thrift_app/services/notification_service.dart';
import '../../controllers/chat_controller.dart';
import '../chat/chat_room_screen.dart';

import '../../controllers/notification_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationController _notificationController =
      NotificationController();

  bool _isLoading = true;
  final ChatController _chatController = ChatController();

  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    NotificationService.onNotificationListShouldRefresh = () {
      _loadNotifications();
    };
  }

  @override
  void dispose() {
    NotificationService.onNotificationListShouldRefresh = null;
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _notificationController.getNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAll() async {
    await _notificationController.clearNotifications();

    setState(() {
      _notifications.clear();
    });
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date.toLocal());

    if (difference.inSeconds < 60) {
      return 'now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays == 1) {
      return '1d ago';
    }

    return DateFormat('MMM d').format(date);
  }

  bool _isToday(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();

    return now.year == localDate.year &&
        now.month == localDate.month &&
        now.day == localDate.day;
  }

  bool _isYesterday(DateTime date) {
    final localDate = date.toLocal();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    return yesterday.year == localDate.year &&
        yesterday.month == localDate.month &&
        yesterday.day == localDate.day;
  }

  List<NotificationModel> _todayNotifications() {
    return _notifications.where((n) => _isToday(n.createdAt)).toList();
  }

  List<NotificationModel> _yesterdayNotifications() {
    return _notifications.where((n) => _isYesterday(n.createdAt)).toList();
  }

  List<NotificationModel> _olderNotifications() {
    return _notifications.where((n) {
      return !_isToday(n.createdAt) && !_isYesterday(n.createdAt);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final today = _todayNotifications();
    final yesterday = _yesterdayNotifications();
    final older = _olderNotifications();

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),

        title: Text(
          "NOTIFICATIONS",
          style: GoogleFonts.syne(
            fontWeight: FontWeight.w800,
            color: Colors.black,
            fontSize: 16,
          ),
        ),

        centerTitle: true,

        actions: [
          TextButton(
            onPressed: _notifications.isEmpty ? null : _clearAll,
            child: Text(
              "Clear all",
              style: GoogleFonts.inter(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 10),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _notifications.isEmpty
          ? _emptyState()
          : RefreshIndicator(
              color: Colors.black,
              onRefresh: _loadNotifications,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                children: [
                  if (today.isNotEmpty) ...[
                    _buildSectionHeader("TODAY"),

                    ...today.map(_buildNotificationItem),
                  ],

                  if (yesterday.isNotEmpty) ...[
                    const SizedBox(height: 25),

                    _buildSectionHeader("YESTERDAY"),

                    ...yesterday.map(_buildNotificationItem),
                  ],

                  if (older.isNotEmpty) ...[
                    const SizedBox(height: 25),

                    _buildSectionHeader("OLDER"),

                    ...older.map(_buildNotificationItem),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 55,
            color: Colors.grey.shade300,
          ),

          const SizedBox(height: 14),

          Text(
            'No notifications yet',
            style: GoogleFonts.syne(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Messages and marketplace activity\nwill appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.black45,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 5),
      child: Text(
        title,
        style: GoogleFonts.syne(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.black45,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return GestureDetector(
      onTap: () async {
        if (!notification.isRead) {
          await _notificationController.markAsRead(notification.id);
        }

        if (!mounted) return;

        if (notification.type == 'order' && notification.orderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OrderDetailsScreen(orderId: notification.orderId!),
            ),
          );
          return;
        }

        if ((notification.type == 'message' || notification.type == 'offer') &&
            notification.conversationId != null) {
          final conversation = await _chatController.getConversationById(
            notification.conversationId!,
          );

          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(conversation: conversation),
            ),
          );
        }
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.grey.shade50,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade100
                : Colors.transparent,
          ),
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            notification.actorImage != null
                ? CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(notification.actorImage!),
                  )
                : Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: notification.isRead
                          ? Colors.grey.shade100
                          : Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: notification.isRead ? Colors.black : Colors.white,
                      size: 18,
                    ),
                  ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      Text(
                        _formatTime(notification.createdAt),
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    notification.body,
                    style: GoogleFonts.inter(
                      color: Colors.black54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_outline_rounded;

      case 'order':
        return Icons.local_shipping_outlined;

      case 'offer':
        return Icons.sell_outlined;

      default:
        return Icons.notifications_none_rounded;
    }
  }
}
