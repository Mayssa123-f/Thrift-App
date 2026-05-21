import 'package:dio/dio.dart';
import 'api_client.dart';

class BotService {
  static final Dio dio = ApiClient.dio;

  static Future<Map<String, dynamic>> sendMessage({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    try {
      final response = await dio.post(
        '/bot/chat',
        data: {
          'message': message,
          'history': history,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Bot unavailable',
      );
    }
  }
  static Future<List<dynamic>> getConversations() async {
    try {
      final response = await dio.get('/conversations');
      return response.data['conversations'] ?? [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load conversations',
      );
    }
  }
}