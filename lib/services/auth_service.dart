import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../utils/token_storage.dart';
import 'api_client.dart';

class AuthService {
  final Dio dio = ApiClient.dio;
  Future<UserModel> loginWithGoogle(String idToken) async {
    try {
      final response = await dio.post(
        '/auth/google',
        data: {'idToken': idToken},
      );

      final data = response.data;

      await TokenStorage.saveToken(data['token']);

      return UserModel.fromJson(data['user']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Google login failed');
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );

      final data = response.data;

      await TokenStorage.saveToken(data['token']);

      return UserModel.fromJson(data['user']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Login failed');
    }
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'full_name': fullName.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data;

      await TokenStorage.saveToken(data['token']);

      return UserModel.fromJson(data['user']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Registration failed');
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await dio.get('/auth/profile');

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get profile');
    }
  }

  Future<UserModel> updateProfile({
    required String fullName,
    String? bio,
    String? location,
    String? profileImageUrl,
  }) async {
    try {
      final response = await dio.put(
        '/auth/profile',
        data: {
          'full_name': fullName.trim(),
          'bio': bio?.trim(),
          'location': location?.trim(),
          'profile_image_url': profileImageUrl,
        },
      );

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update profile',
      );
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearToken();
  }

  Future<void> forgotPassword(String email) async {
    try {
      await dio.post('/auth/forgot-password', data: {'email': email.trim()});
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to send reset code',
      );
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await dio.post(
        '/auth/reset-password',
        data: {
          'email': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to reset password',
      );
    }
  }
}
