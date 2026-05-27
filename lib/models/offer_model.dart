class OfferModel {
  final int id;
  final int conversationId;
  final int productId;
  final int buyerId;
  final int sellerId;
  final dynamic offeredPrice;
  final String status;
  final DateTime createdAt;

  OfferModel({
    required this.id,
    required this.conversationId,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.offeredPrice,
    required this.status,
    required this.createdAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      productId: json['product_id'],
      buyerId: json['buyer_id'],
      sellerId: json['seller_id'],
      offeredPrice: json['offered_price'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}