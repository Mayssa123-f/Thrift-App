class OrderModel {
  final int id;
  final String status;
  final dynamic totalPrice;
  final dynamic originalPrice;
  final dynamic finalPrice;
  final String deliveryMethod;
  final DateTime createdAt;

  final int buyerId;
  final int sellerId;
  final int productId;

  final String title;
  final dynamic price;
  final String? size;
  final String? conditionType;
  final String? gender;
  final String? brand;
  final String? color;
  final String? image;

  final String buyerName;
  final String? buyerImage;
  final String sellerName;
  final String? sellerImage;

  final String viewerRole;

  OrderModel({
    required this.id,
    required this.status,
    required this.totalPrice,
    required this.originalPrice,
    required this.finalPrice,
    required this.deliveryMethod,
    required this.createdAt,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.title,
    required this.price,
    this.size,
    this.conditionType,
    this.gender,
    this.brand,
    this.color,
    this.image,
    required this.buyerName,
    this.buyerImage,
    required this.sellerName,
    this.sellerImage,
    required this.viewerRole,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      status: json['status'],
      totalPrice: json['total_price'],
      originalPrice: json['original_price'],
      finalPrice: json['final_price'],
      deliveryMethod: json['delivery_method'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      buyerId: json['buyer_id'],
      sellerId: json['seller_id'],
      productId: json['product_id'],
      title: json['title'],
      price: json['price'],
      size: json['size'],
      conditionType: json['condition_type'],
      gender: json['gender'],
      brand: json['brand'],
      color: json['color'],
      image: json['image'],
      buyerName: json['buyer_name'],
      buyerImage: json['buyer_image'],
      sellerName: json['seller_name'],
      sellerImage: json['seller_image'],
      viewerRole: json['viewer_role'],
    );
  }
}