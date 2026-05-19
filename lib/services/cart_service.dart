import 'package:dio/dio.dart';
import 'package:thrift_app/models/cart_item_model.dart';
import 'api_client.dart';

class CartService {
  static final Dio dio = ApiClient.dio;

  static Future<List<CartItemModel>> getCartItems() async {
    try {
      final response = await dio.get('/cart');

      final List data = response.data['cartItems'] ?? [];

      return data.map((json) => CartItemModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load cart',
      );
    }
  }

  static Future<void> addToCart({
    required int productId,
    String? selectedSize,
  }) async {
    try {
      await dio.post(
        '/cart/$productId',
        data: {
          'selected_size': selectedSize,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to add to cart',
      );
    }
  }

  static Future<void> removeFromCart(int productId) async {
    try {
      await dio.delete('/cart/$productId');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to remove from cart',
      );
    }
  }

  static Future<void> clearCart() async {
    try {
      await dio.delete('/cart');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to clear cart',
      );
    }
  }
}