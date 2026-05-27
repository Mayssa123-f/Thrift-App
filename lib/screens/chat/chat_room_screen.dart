import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thrift_app/controllers/product_controller.dart';
import 'package:thrift_app/screens/product/product_details_screen.dart';
import 'package:thrift_app/services/notification_service.dart';

import '../../controllers/chat_controller.dart';
import '../../models/chat_message_model.dart';
import '../../models/conversation_model.dart';
import '../../models/product_model.dart';
import '../../services/auth_service.dart';
import '../../controllers/offer_controller.dart';

class ChatRoomScreen extends StatefulWidget {
  final ConversationModel conversation;
  final ProductModel? sourceProduct;
  final String? receiverName;
  final String? receiverImage;

  const ChatRoomScreen({
    super.key,
    required this.conversation,
    this.sourceProduct,
    this.receiverName,
    this.receiverImage,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatController chatController = ChatController();
  final OfferController offerController = OfferController();
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ProductController productController = ProductController();
  Timer? refreshTimer;

  bool isLoading = true;
  bool isSending = false;
  List<ChatMessageModel> messages = [];
  int? get currentUserId => AuthService.currentUser?.id;

  bool get isSeller => currentUserId == widget.conversation.sellerId;

  @override
  void initState() {
    super.initState();
    NotificationService.setActiveConversation(widget.conversation.id);
    _loadMessages();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _loadMessages(),
    );
  }

  Future<void> _loadMessages() async {
    try {
      final data = await chatController.getMessages(widget.conversation.id);

      await chatController.markConversationAsRead(widget.conversation.id);

      if (!mounted) return;

      setState(() {
        messages = data;
        isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    setState(() => isSending = true);

    try {
      final newMessage = await chatController.sendMessage(
        conversationId: widget.conversation.id,
        messageText: text,
      );

      if (!mounted) return;

      setState(() {
        messages.add(newMessage);
        messageController.clear();
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _productContextCard() {
    final product = widget.sourceProduct;

    final title = product?.title ?? widget.conversation.productTitle;
    final image = product?.image ?? widget.conversation.productImage;
    final price =
        product?.formattedPrice ??
        (widget.conversation.productPrice != null
            ? "\$${widget.conversation.productPrice}"
            : null);

    if (title == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              image ?? 'https://via.placeholder.com/150',
              height: 58,
              width: 58,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You started this chat from",
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.black45),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.syne(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (price != null)
                  Text(
                    price,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            "View",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(ChatMessageModel message) {
    final currentUserId = AuthService.currentUser?.id;
    final bool isMine = message.senderId == currentUserId;

    // SYSTEM MESSAGE
    if (message.messageType == 'system') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message.messageText ?? "",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // OFFER MESSAGE
    if (message.messageType == 'offer') {
      final bool isSeller =
          AuthService.currentUser?.id == widget.conversation.sellerId;

      final status = message.offerStatus ?? 'pending';

      Color backgroundColor;
      Color textColor;

      switch (status) {
        case 'accepted':
          backgroundColor = const Color(0xFFE8F7EE);
          textColor = Colors.green.shade700;
          break;

        case 'declined':
          backgroundColor = const Color(0xFFFFECEC);
          textColor = Colors.red.shade700;
          break;

        case 'expired':
          backgroundColor = Colors.grey.shade100;
          textColor = Colors.grey.shade600;
          break;
        default:
          backgroundColor = Colors.grey.shade100;
          textColor = Colors.black;
      }

      return Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 285,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: status == 'accepted'
                  ? Colors.green.shade100
                  : status == 'declined'
                  ? Colors.red.shade100
                  : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_offer_outlined, size: 16, color: textColor),
                  const SizedBox(width: 6),
                  Text(
                    "Offer",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Text(
                message.productTitle ?? 'Item',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              Text(
                "\$${message.offeredPrice ?? ''}",
                style: GoogleFonts.inter(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 10),

              if (status == 'accepted')
                Text(
                  "Offer accepted",
                  style: GoogleFonts.inter(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                )
              else if (status == 'declined')
                Text(
                  "Offer declined",
                  style: GoogleFonts.inter(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                )
              else if (isSeller && message.offerId != null)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await offerController.acceptOffer(message.offerId!);

                          _loadMessages();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          "Accept",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await offerController.declineOffer(message.offerId!);

                          _loadMessages();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          "Decline",
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  "Waiting for seller response",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      );
    }
    // PRODUCT MESSAGE
    if (message.messageType == 'product') {
      return Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 290,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMine ? 20 : 6),
              bottomRight: Radius.circular(isMine ? 6 : 20),
            ),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  message.productImage ?? '',
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                message.productTitle ?? "Product",
                style: GoogleFonts.syne(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                message.messageText ?? "",
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Text(
                    "\$${message.productPrice}",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  if (!isSeller && message.productId != null)
                    GestureDetector(
                      onTap: () {
                        _showOfferBottomSheet(
                          productId: message.productId!,
                          productTitle: message.productTitle ?? "this item",
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          "Make Offer",
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),

                  GestureDetector(
                    onTap: () async {
                      try {
                        final product = await productController.getProductById(
                          message.productId!,
                        );

                        if (!mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailsScreen(product: product),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        "View Item",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
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
    }
    if (message.messageType == 'image') {
      return Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          constraints: const BoxConstraints(maxWidth: 190),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              'http://10.0.2.2:8080${message.imageUrl}',
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }
    // NORMAL TEXT MESSAGE
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMine ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
        ),
        child: Text(
          message.messageText ?? "",
          style: GoogleFonts.inter(
            color: isMine ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _showOfferBottomSheet({
    required int productId,
    required String productTitle,
  }) async {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Make an Offer",
                style: GoogleFonts.syne(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Suggest your price for $productTitle",
                style: GoogleFonts.inter(color: Colors.black54, fontSize: 14),
              ),

              const SizedBox(height: 24),

              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  prefixText: "\$ ",
                  prefixStyle: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  hintText: "0",
                  hintStyle: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.black26,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () async {
                    final value = double.tryParse(controller.text.trim());

                    if (value == null || value <= 0) {
                      return;
                    }

                    try {
                      await offerController.createOffer(
                        conversationId: widget.conversation.id,
                        productId: productId,
                        sellerId: widget.conversation.sellerId!,
                        offeredPrice: value,
                      );

                      if (!mounted) return;

                      Navigator.pop(context);

                      _loadMessages();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Offer sent successfully"),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst('Exception: ', ''),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    "Send Offer",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _attachmentOption(
                  icon: Icons.camera_alt_rounded,
                  title: "Take Photo",
                  onTap: () {
                    Navigator.pop(context);
                    _openCamera();
                  },
                ),

                const SizedBox(height: 14),

                _attachmentOption(
                  icon: Icons.photo_library_rounded,
                  title: "Choose from Gallery",
                  onTap: () {
                    Navigator.pop(context);
                    _openGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attachmentOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black),

            const SizedBox(width: 14),

            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _openCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo != null) {
      _sendImageMessage(File(photo.path));
    }
  }

  Future<void> _openGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      _sendImageMessage(File(image.path));
    }
  }

  Future<void> _sendImageMessage(File imageFile) async {
    setState(() => isSending = true);

    try {
      final newMessage = await chatController.sendImageMessage(
        conversationId: widget.conversation.id,
        imageFile: imageFile,
      );

      if (!mounted) return;

      setState(() {
        messages.add(newMessage);
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  @override
  void dispose() {
    NotificationService.setActiveConversation(null);
    refreshTimer?.cancel();
    scrollController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receiverName =
        widget.receiverName ?? widget.conversation.receiverName ?? "Seller";
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.receiverImage != null
                  ? NetworkImage(widget.receiverImage!)
                  : widget.conversation.receiverImage != null
                  ? NetworkImage(widget.conversation.receiverImage!)
                  : null,
              child: widget.receiverImage == null
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              receiverName,
              style: GoogleFonts.syne(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _messageBubble(messages[index]);
                    },
                  ),
          ),

          SafeArea(
            top: false,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                  child: GestureDetector(
                    onTap: _showAttachmentSheet,
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.black),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: isSending ? null : _sendMessage,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
