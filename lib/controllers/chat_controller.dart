import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';

class ChatController {
  final ChatService _chatService = ChatService();

  Future<List<ConversationModel>> getConversations() {
    return _chatService.getConversations();
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