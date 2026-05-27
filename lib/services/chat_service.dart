import 'dart:io';

import 'package:dio/dio.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import './api_client.dart';

class ChatService {
  final Dio dio = ApiClient.dio;

  Future<List<ConversationModel>> getConversations() async {
    final response = await dio.get('/conversations');

    return (response.data['conversations'] as List)
        .map((json) => ConversationModel.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> sendImageMessage({
    required int conversationId,
    required File imageFile,
  }) async {
    final formData = FormData.fromMap({
      'conversation_id': conversationId.toString(),
      'image': await MultipartFile.fromFile(imageFile.path),
    });

    final response = await dio.post(
      '/messages/image',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return response.data;
  }

  Future<ConversationModel> getConversationById(int conversationId) async {
    try {
      final response = await dio.get('/conversations/$conversationId');

      return ConversationModel.fromJson(response.data['conversation']);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load conversation',
      );
    }
  }

  Future<int> getUnreadMessagesCount() async {
    final response = await dio.get('/conversations/unread/count');
    return response.data['unread_count'] ?? 0;
  }

  Future<void> markConversationAsRead(int conversationId) async {
    try {
      await dio.put('/messages/read/$conversationId');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to mark messages as read',
      );
    }
  }

  Future<ConversationModel> createConversation({
    required int productId,
    required int sellerId,
  }) async {
    final response = await dio.post(
      '/conversations',
      data: {'product_id': productId, 'seller_id': sellerId},
    );

    return ConversationModel.fromJson(response.data['conversation']);
  }

  Future<List<ChatMessageModel>> getMessages(int conversationId) async {
    final response = await dio.get('/messages/$conversationId');

    return (response.data['messages'] as List)
        .map((json) => ChatMessageModel.fromJson(json))
        .toList();
  }

  Future<ChatMessageModel> sendMessage({
    required int conversationId,
    required String messageText,
  }) async {
    final response = await dio.post(
      '/messages',
      data: {'conversation_id': conversationId, 'message_text': messageText},
    );

    return ChatMessageModel.fromJson(response.data['message']);
  }

  Future<ChatMessageModel> sendProductMessage({
    required int conversationId,
    required int productId,
  }) async {
    final response = await dio.post(
      '/messages/product',
      data: {'conversation_id': conversationId, 'product_id': productId},
    );

    return ChatMessageModel.fromJson(response.data['message']);
  }
}
