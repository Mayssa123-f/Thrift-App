
import 'package:thrift_app/models/cart_item_model.dart';
import 'package:thrift_app/services/cart_service.dart';

class CartController {
  Future<List<CartItemModel>> getCartItems() async {
    return await CartService.getCartItems();
  }

  Future<void> addToCart({
    required int productId,
    String? selectedSize,
  }) async {
    await CartService.addToCart(
      productId: productId,
      selectedSize: selectedSize,
    );
  }

  Future<void> removeFromCart(int productId) async {
    await CartService.removeFromCart(productId);
  }

  Future<void> clearCart() async {
    await CartService.clearCart();
  }
}