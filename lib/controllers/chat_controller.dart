import 'dart:io';

import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';

class ChatController {
  final ChatService _chatService = ChatService();

  Future<List<ConversationModel>> getConversations() {
    return _chatService.getConversations();
  }

  Future<ConversationModel> getConversationById(int conversationId) async {
    return await _chatService.getConversationById(conversationId);
  }

  Future<ConversationModel> startConversation({
    required int productId,
    required int sellerId,
  }) {
    return _chatService.createConversation(
      productId: productId,
      sellerId: sellerId,
    );
  }

  Future<List<ChatMessageModel>> getMessages(int conversationId) {
    return _chatService.getMessages(conversationId);
  }

  Future<int> getUnreadMessagesCount() async {
    return await _chatService.getUnreadMessagesCount();
  }

  Future<ChatMessageModel> sendImageMessage({
    required int conversationId,
    required File imageFile,
  }) async {
    try {
      final data = await _chatService.sendImageMessage(
        conversationId: conversationId,
        imageFile: imageFile,
      );

      return ChatMessageModel.fromJson(data['message']);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // NORMAL TEXT MESSAGE
  Future<ChatMessageModel> sendMessage({
    required int conversationId,
    required String messageText,
  }) {
    return _chatService.sendMessage(
      conversationId: conversationId,
      messageText: messageText,
    );
  }

  Future<void> markConversationAsRead(int conversationId) async {
    await _chatService.markConversationAsRead(conversationId);
  }

  // PRODUCT CARD MESSAGE
  Future<ChatMessageModel> sendProductMessage({
    required int conversationId,
    required int productId,
  }) {
    return _chatService.sendProductMessage(
      conversationId: conversationId,
      productId: productId,
    );
  }
}
