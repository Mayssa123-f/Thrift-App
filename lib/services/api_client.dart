import 'package:dio/dio.dart';
import '../utils/token_storage.dart';

class ApiClient {
  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: 'http://10.0.2.2:8080/api',
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 20),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await TokenStorage.getToken();

              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }

              handler.next(options);
            },

            onError: (error, handler) {
              print('Dio Error: ${error.response?.data}');
              handler.next(error);
            },
          ),
        );
}
