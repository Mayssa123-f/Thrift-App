import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_client.dart';

class NotificationService {
  final dio = ApiClient.dio;

  Future<void> saveFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();

    if (token == null) return;

    await dio.post(
      '/notifications/token',
      data: {
        'token': token,
        'platform': 'android',
      },
    );
  }
}