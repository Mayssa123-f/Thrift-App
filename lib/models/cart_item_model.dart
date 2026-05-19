import 'package:thrift_app/models/product_model.dart';

class CartItemModel {
  final int cartItemId;
  final int quantity;
  final String? selectedSize;
  final ProductModel product;

  CartItemModel({
    required this.cartItemId,
    required this.quantity,
    this.selectedSize,
    required this.product,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      cartItemId: json['cart_item_id'],
      quantity: json['quantity'] ?? 1,
      selectedSize: json['selected_size'],
      product: ProductModel.fromJson(json),
    );
  }

  double get totalPrice => product.price * quantity;
}