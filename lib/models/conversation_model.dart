class ConversationModel {
  final int id;
  final int? productId;
  final int buyerId;
  final int sellerId;

  final String? productTitle;
  final String? productImage;
  final dynamic productPrice;

  final String? receiverName;
  final String? receiverImage;

  final String? lastMessage;

  final DateTime? lastMessageAt;
  final int unreadCount;

  ConversationModel({
    required this.id,
    this.productId,
    required this.buyerId,
    required this.sellerId,
    this.productTitle,
    this.productImage,
    this.productPrice,
    this.receiverName,
    this.receiverImage,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      productId: json['product_id'],
      buyerId: json['buyer_id'],
      sellerId: json['seller_id'],

      productTitle: json['product_title'],
      productImage: json['product_image'],
      productPrice: json['product_price'],

      receiverName: json['receiver_name'],
      receiverImage: json['receiver_image'],

      lastMessage: json['last_message'],

      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at']).toLocal()
          : null,

      unreadCount: json['unread_count'] ?? 0,
    );
  }
}
