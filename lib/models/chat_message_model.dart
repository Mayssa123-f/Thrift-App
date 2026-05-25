class ChatMessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String messageType;
  final String? messageText;
  final int? offerId;
  final DateTime createdAt;

  final int? productId;
  final String? productTitle;
  final String? productImage;
  final dynamic productPrice;
  final String? offerStatus;
  final dynamic offeredPrice;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    this.messageText,
    this.offerId,
    required this.createdAt,
    this.productId,
    this.productTitle,
    this.productImage,
    this.productPrice,
    this.offerStatus,
    this.offeredPrice,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      messageType: json['message_type'],
      messageText: json['message_text'],
      offerId: json['offer_id'],
      createdAt: DateTime.parse(json['created_at']),

      productId: json['product_id'],
      productTitle: json['product_title'],
      productImage: json['product_image'],
      productPrice: json['product_price'],
      offerStatus: json['offer_status'],
      offeredPrice: json['offered_price'],
    );
  }
}
