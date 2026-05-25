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

  final bool isAvailable;

  final int categoryId;
  final String? color;

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

    required this.isAvailable,

    required this.categoryId,
    this.color,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      // ── Safe int parsing ─────────────────────────────
      id: int.tryParse(
            (json['id'] ?? 0).toString(),
          ) ??
          0,

      // ── Basic info ──────────────────────────────────
      title: json['title']?.toString() ?? '',

      description:
          json['description']?.toString() ?? '',

      // ── Safe double parsing ─────────────────────────
      price: double.tryParse(
            (json['price'] ?? 0).toString(),
          ) ??
          0.0,

      currency:
          json['currency']?.toString() ?? 'USD',

      // ── Optional fields ─────────────────────────────
      brand: json['brand']?.toString(),

      size: json['size']?.toString(),

      conditionType:
          json['condition_type']?.toString(),

      gender: json['gender']?.toString(),

      styleTag:
          json['style_tag']?.toString(),

      location: json['location']?.toString(),

      category: json['category']?.toString(),

      // ── Seller ──────────────────────────────────────
      sellerId: int.tryParse(
            (json['seller_id'] ?? 0).toString(),
          ) ??
          0,

      seller:
          json['seller']?.toString() ??
              'Unknown Seller',

      sellerImage:
          json['seller_image']?.toString(),

      // ── Images ──────────────────────────────────────
      image: json['image']?.toString(),

      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],

      // ── Availability ────────────────────────────────
      isAvailable:
          json['is_available'] == 1 ||
              json['is_available'] == true,

      // ── AI stylist support ──────────────────────────
      categoryId: int.tryParse(
            (json['category_id'] ?? 0).toString(),
          ) ??
          0,

      color: json['color']?.toString(),
    );
  }

  String get formattedPrice {
    final cleanPrice = price % 1 == 0
        ? price.toInt().toString()
        : price.toStringAsFixed(2);

    return '\$$cleanPrice';
  }

  List<String> get sizes {
    if (size == null || size!.isEmpty) {
      return [];
    }

    return [size!];
  }
}