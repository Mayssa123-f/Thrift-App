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

  Future<ConversationModel> createConversation({
    required int productId,
    required int sellerId,
  }) async {
    final response = await dio.post(
      '/conversations',
      data: {
        'product_id': productId,
        'seller_id': sellerId,
      },
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
      data: {
        'conversation_id': conversationId,
        'message_text': messageText,
      },
    );

    return ChatMessageModel.fromJson(response.data['message']);
  }
}