import 'package:thrift_app/models/product_model.dart';

class CartItemModel {
  final int cartItemId;
  final int quantity;
  final String? selectedSize;

  final int? acceptedOfferId;
  final dynamic acceptedOfferPrice;

  final ProductModel product;

  CartItemModel({
    required this.cartItemId,
    required this.quantity,
    this.selectedSize,
    this.acceptedOfferId,
    this.acceptedOfferPrice,
    required this.product,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      cartItemId: json['cart_item_id'],
      quantity: json['quantity'] ?? 1,
      selectedSize: json['selected_size'],

      acceptedOfferId: json['accepted_offer_id'],
      acceptedOfferPrice: json['accepted_offer_price'],

      product: ProductModel.fromJson(json),
    );
  }

  bool get hasAcceptedOffer =>
      acceptedOfferPrice != null;

  double get effectivePrice {
    if (acceptedOfferPrice != null) {
      return double.parse(
        acceptedOfferPrice.toString(),
      );
    }

    return product.price;
  }

  double get totalPrice =>
      effectivePrice * quantity;
}