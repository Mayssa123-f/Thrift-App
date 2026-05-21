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

  bool isLoading = true;
  List<ConversationModel> conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
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
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
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
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : conversations.isEmpty
                ? _emptyState()
                : RefreshIndicator(
              onRefresh: _loadConversations,
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: conversations.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(
                            conversation: conversation,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color:
                            Colors.black.withOpacity(0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(18),
                            child: Container(
                              height: 58,
                              width: 58,
                              color: const Color(0xFFF3ECFF),
                              child: conversation.receiverImage !=
                                  null &&
                                  conversation.receiverImage!
                                      .isNotEmpty
                                  ? Image.network(
                                conversation.receiverImage!,
                                fit: BoxFit.cover,
                              )
                                  : Center(
                                child: Text(
                                  (conversation.receiverName ??
                                      'U')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: GoogleFonts.syne(
                                    fontSize: 22,
                                    fontWeight:
                                    FontWeight.w800,
                                    color:
                                    Colors.deepPurple,
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
                                Text(
                                  conversation.receiverName ??
                                      'Seller',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.syne(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  conversation.lastMessage ??
                                      'No messages yet',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.black26,
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
              style: GoogleFonts.inter(
                color: Colors.black45,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}