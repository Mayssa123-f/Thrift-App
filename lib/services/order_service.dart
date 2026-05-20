import 'package:dio/dio.dart';
import 'api_client.dart';

class OrderService {
  static final Dio dio = ApiClient.dio;

  static Future<Map<String, dynamic>> createPaymentIntent() async {
    try {
      final response = await dio.post('/orders/payment-intent');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to create payment',
      );
    }
  }

  static Future<Map<String, dynamic>> createOrder({
    required String deliveryMethod,
    required String paymentIntentId,
  }) async {
    try {
      final response = await dio.post(
        '/orders',
        data: {
          'delivery_method': deliveryMethod,
          'payment_intent_id': paymentIntentId,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to place order',
      );
    }
  }

  static Future<List<dynamic>> getMyOrders() async {
    try {
      final response = await dio.get('/orders');
      return response.data['orders'] ?? [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch orders',
      );
    }
  }

  static Future<Map<String, dynamic>> getSellerOrders() async {
    try {
      final response = await dio.get('/orders/seller');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch seller orders',
      );
    }
  }
  static Future<Map<String, dynamic>> getWallet() async {
    try {
      final response = await dio.get('/orders/wallet');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch wallet',
      );
    }
  }
}