class ConversationModel {
  final int id;
  final int productId;
  final int buyerId;
  final int sellerId;
  final String? productTitle;
  final String? productImage;
  final String? lastMessage;

  ConversationModel({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    this.productTitle,
    this.productImage,
    this.lastMessage,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      productId: json['product_id'],
      buyerId: json['buyer_id'],
      sellerId: json['seller_id'],
      productTitle: json['product_title'],
      productImage: json['product_image'],
      lastMessage: json['last_message'],
    );
  }
}