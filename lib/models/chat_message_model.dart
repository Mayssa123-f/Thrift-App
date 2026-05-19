class ChatMessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String messageType;
  final String? messageText;
  final int? offerId;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    this.messageText,
    this.offerId,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      messageType: json['message_type'],
      messageText: json['message_text'],
      offerId: json['offer_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}