import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/chat_controller.dart';
import '../../models/conversation_model.dart';
import 'chat_room_screen.dart';
import 'bot_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ChatController chatController = ChatController();

  String _formatConversationTime(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';

    if (diff.inDays == 1) return 'Yesterday';

    return '${date.day}/${date.month}';
  }

  Timer? refreshTimer;
  bool isLoading = true;
  List<ConversationModel> conversations = [];
  int selectedTab = 0;

  List<ConversationModel> get filteredConversations {
    if (selectedTab == 1) {
      return conversations
          .where(
            (c) => c.lastMessage != null && c.lastMessage!.trim().isNotEmpty,
          )
          .toList();
    }

    return conversations;
  }

  @override
  void initState() {
    super.initState();

    _loadConversations();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _loadConversations(),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final data = await chatController.getConversations();
      if (!mounted) return;
      setState(() {
        conversations = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'MESSAGES',
          style: GoogleFonts.syne(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          // BOT BANNER
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BotScreen()),
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vinty Assistant',
                          style: GoogleFonts.syne(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Find items, track orders, check wallet...',
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white54,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),

          // CONVERSATIONS LIST
          // CONVERSATIONS LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: Row(
                          children: [
                            _tabButton(
                              title: 'All',
                              active: selectedTab == 0,
                              onTap: () => setState(() => selectedTab = 0),
                            ),
                            const SizedBox(width: 10),
                            _tabButton(
                              title: 'Unread',
                              active: selectedTab == 1,
                              onTap: () => setState(() => selectedTab = 1),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      Expanded(
                        child: filteredConversations.isEmpty
                            ? _emptyState()
                            : RefreshIndicator(
                                onRefresh: _loadConversations,
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    8,
                                    20,
                                    20,
                                  ),
                                  itemCount: filteredConversations.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 4),
                                  itemBuilder: (context, index) {
                                    final conversation =
                                        filteredConversations[index];
                                    final bool hasUnread =
                                        conversation.unreadCount > 0;

                                    return GestureDetector(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatRoomScreen(
                                              conversation: conversation,
                                            ),
                                          ),
                                        );

                                        _loadConversations();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child: SizedBox(
                                                width: 58,
                                                height: 58,
                                                child:
                                                    conversation.receiverImage !=
                                                            null &&
                                                        conversation
                                                            .receiverImage!
                                                            .isNotEmpty
                                                    ? Image.network(
                                                        conversation
                                                            .receiverImage!,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Container(
                                                        color: Colors
                                                            .grey
                                                            .shade200,
                                                        child: Center(
                                                          child: Text(
                                                            (conversation
                                                                        .receiverName ??
                                                                    'U')
                                                                .substring(0, 1)
                                                                .toUpperCase(),
                                                            style:
                                                                GoogleFonts.inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  fontSize: 20,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            ),

                                            const SizedBox(width: 14),

                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          conversation
                                                                  .receiverName ??
                                                              'User',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 5),

                                                  Text(
                                                    conversation.lastMessage ??
                                                        'No messages yet',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      color: hasUnread
                                                          ? Colors.black
                                                          : Colors.black54,
                                                      fontWeight: hasUnread
                                                          ? FontWeight.w800
                                                          : FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(width: 12),

                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _formatConversationTime(
                                                    conversation.lastMessageAt,
                                                  ),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: hasUnread
                                                        ? Colors.black
                                                        : Colors.black38,
                                                    fontWeight: hasUnread
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                  ),
                                                ),

                                                const SizedBox(height: 10),

                                                if (hasUnread)
                                                  Container(
                                                    width: 27,
                                                    height: 27,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.black,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: Center(
                                                      child: Text(
                                                        conversation.unreadCount >
                                                                9
                                                            ? '9+'
                                                            : '${conversation.unreadCount}',
                                                        style:
                                                            GoogleFonts.inter(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 62,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 18),
            Text(
              'No conversations yet',
              style: GoogleFonts.syne(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Message a seller to start negotiating or asking about an item.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.black45, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? Colors.black : Colors.grey.shade200,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            color: active ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
