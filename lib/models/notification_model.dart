class NotificationModel {
  final int id;
  final int userId;
  final int? actorId;

  final String type;
  final String title;
  final String body;

  final int? conversationId;
  final int? productId;
  final int? orderId;
  final int? offerId;

  final bool isRead;
  final DateTime createdAt;

  final String? actorName;
  final String? actorImage;

  NotificationModel({
    required this.id,
    required this.userId,
    this.actorId,
    required this.type,
    required this.title,
    required this.body,
    this.conversationId,
    this.productId,
    this.orderId,
    this.offerId,
    required this.isRead,
    required this.createdAt,
    this.actorName,
    this.actorImage,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      actorId: json['actor_id'],
      type: json['type'],
      title: json['title'],
      body: json['body'],
      conversationId: json['conversation_id'],
      productId: json['product_id'],
      orderId: json['order_id'],
      offerId: json['offer_id'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      actorName: json['actor_name'],
      actorImage: json['actor_image'],
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      actorId: actorId,
      type: type,
      title: title,
      body: body,
      conversationId: conversationId,
      productId: productId,
      orderId: orderId,
      offerId: offerId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      actorName: actorName,
      actorImage: actorImage,
    );
  }
}
