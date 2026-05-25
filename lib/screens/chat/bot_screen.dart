import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/models/product_model.dart';
import '../../models/conversation_model.dart';

import '../../services/bot_service.dart';
import '../../services/chat_service.dart';
import '../product/product_details_screen.dart';

class BotScreen extends StatefulWidget {
  const BotScreen({super.key});

  @override
  State<BotScreen> createState() => _BotScreenState();
}

class _BotScreenState extends State<BotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  bool _isTyping = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'content':
      "Hey! I'm Vinty Assistant 👋 What do you need?",
      'products': [],
    }
  ];

  List<Map<String, String>> get _history {
    return _messages
        .map((m) => {
      'role': m['role'] as String,
      'content': m['content'] as String,
    })
        .toList();
  }

  final List<String> _quickReplies = [
    "What's in my cart? 🛒",
    "Show me vintage jackets",
    "How's my wallet? 💰",
    "Where's my order?",
    "Find shoes under \$50",
    "Negotiation tips 💬",
  ];

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _isTyping) return;
    _controller.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': text, 'products': []});
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await BotService.sendMessage(
        message: text,
        history: _history,
      );

      final reply = response['reply'] as String;
      final rawProducts = response['products'] as List? ?? [];

      final products = rawProducts
          .map((p) => ProductModel(
        id: p['id'],
        title: p['title'] ?? '',
        description: '',
        price: double.tryParse(p['price'].toString()) ?? 0,
        currency: p['currency'] ?? 'USD',
        sellerId: 0,
        seller: p['seller'] ?? '',
        isAvailable: true,
        image: p['image'],
        category: p['category'],
        styleTag: p['style_tag'],
        size: p['size'],
        categoryId: int.tryParse((p['category_id'] ?? 0).toString()) ?? 0,
      ))
          .toList();

      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': reply,
          'products': products,
        });
        _isTyping = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': "Having trouble connecting. Try again! 🙏",
          'products': [],
        });
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  // SHARE PRODUCT TO CHAT
  Future<void> _shareProductToChat(ProductModel product) async {
    // Load conversations
    List<ConversationModel> conversations = [];

    try {
      final data = await BotService.getConversations();
      conversations = data
          .map((json) => ConversationModel.fromJson(json))
          .toList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load conversations')),
      );
      return;
    }

    if (!mounted) return;

    if (conversations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No conversations yet. Message a seller first!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Show conversation picker sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Share to conversation',
              style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick who to send "${product.title}" to',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),

            // Product preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      product.image ?? 'https://via.placeholder.com/150',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_outlined, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.syne(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          product.formattedPrice,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Conversation list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: conversations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final conv = conversations[i];
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await _sendProductToConversation(
                          product, conv);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border:
                        Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 46,
                              height: 46,
                              color: const Color(0xFFF3ECFF),
                              child: conv.receiverImage != null &&
                                  conv.receiverImage!.isNotEmpty
                                  ? Image.network(
                                conv.receiverImage!,
                                fit: BoxFit.cover,
                              )
                                  : Center(
                                child: Text(
                                  (conv.receiverName ?? 'U')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: GoogleFonts.syne(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              conv.receiverName ?? 'Seller',
                              style: GoogleFonts.syne(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Send',
                              style: GoogleFonts.syne(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendProductToConversation(
      ProductModel product, ConversationModel conversation) async {
    try {
      await _chatService.sendProductMessage(
        conversationId: conversation.id,
        productId: product.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sent "${product.title}" to ${conversation.receiverName ?? "chat"} ✓',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vinty Assistant',
                  style: GoogleFonts.syne(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Powered by AI',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),

          if (!_isTyping &&
              _messages.isNotEmpty &&
              _messages.last['role'] == 'assistant')
            _buildQuickReplies(),

          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isBot = msg['role'] == 'assistant';
    final content = msg['content'] as String;
    final products = (msg['products'] as List?)
        ?.whereType<ProductModel>()
        .toList() ??
        [];

    return Column(
      crossAxisAlignment:
      isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
          isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (isBot) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: isBot ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isBot ? 4 : 18),
                    bottomRight: Radius.circular(isBot ? 18 : 4),
                  ),
                  boxShadow: isBot
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                      : [],
                ),
                child: Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: isBot ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),

        // PRODUCT CARDS WITH SHARE BUTTON
        if (products.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 255,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 38),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final product = products[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailsScreen(product: product),
                    ),
                  ),
                  child: Container(
                    width: 155,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // IMAGE
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            product.image ??
                                'https://via.placeholder.com/150',
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 130,
                              color: Colors.grey.shade100,
                              child:
                              const Icon(Icons.image_outlined),
                            ),
                          ),
                        ),

                        // INFO
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              10, 8, 10, 0),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.syne(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                product.formattedPrice,
                                style: GoogleFonts.syne(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (product.size != null)
                                Text(
                                  'Size: ${product.size}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // SHARE BUTTON
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              8, 0, 8, 8),
                          child: GestureDetector(
                            onTap: () =>
                                _shareProductToChat(product),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.send_rounded,
                                    size: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Share to chat',
                                    style: GoogleFonts.syne(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_awesome,
              color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              _dot(),
              const SizedBox(width: 4),
              _dot(),
              const SizedBox(width: 4),
              _dot(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: Colors.grey.shade400.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickReplies() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => _send(_quickReplies[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _quickReplies[i],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: _send,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _send(_controller.text),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
