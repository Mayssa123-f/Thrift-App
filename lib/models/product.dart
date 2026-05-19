class Product {
  final String id;
  final String title;
  final String price;
  final String image;
  final String category;
  final String tag;
  final String description;
  final List<String> sizes;
  final String seller;
  final String sellerImage;
  

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.image,
    required this.category,
    required this.tag,
    required this.description,
    required this.sizes,
    required this.seller,
    required this.sellerImage,
  });

  // Converts to Map for backwards compatibility during transition
  Map<String, String> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'image': image,
      'category': category,
      'tag': tag,
    };
  }
}