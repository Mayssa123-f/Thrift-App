class ProductModel {
  final int id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String? brand;
  final String? size;
  final String? conditionType;
  final String? gender;
  final String? styleTag;
  final String? location;
  final String? category;
  final int sellerId;
  final String seller;
  final String? sellerImage;
  final String? image;
  final List<String> images;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    this.brand,
    this.size,
    this.conditionType,
    this.gender,
    this.styleTag,
    this.location,
    this.category,
    required this.sellerId,
    required this.seller,
    this.sellerImage,
    this.image,
    this.images = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      currency: json['currency'] ?? 'USD',
      brand: json['brand'],
      size: json['size'],
      conditionType: json['condition_type'],
      gender: json['gender'],
      styleTag: json['style_tag'],
      location: json['location'],
      category: json['category'],
      sellerId: json['seller_id'],
      seller: json['seller'] ?? 'Unknown Seller',
      sellerImage: json['seller_image'],
      image: json['image'],
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
    );
  }

  String get formattedPrice {
    final cleanPrice = price % 1 == 0 ? price.toInt().toString() : price.toStringAsFixed(2);
    return '\$$cleanPrice';
  }

  List<String> get sizes {
    if (size == null || size!.isEmpty) return [];
    return [size!];
  }
}