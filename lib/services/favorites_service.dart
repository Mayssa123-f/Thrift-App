import 'package:dio/dio.dart';
import 'package:thrift_app/models/product_model.dart';

import 'api_client.dart';

class FavoritesService {
  static final Dio dio = ApiClient.dio;

  /// ADD FAVORITE
  static Future<void> addFavorite(int productId) async {
    try {
      await dio.post('/favorites/$productId');
    } on DioException catch (e) {
      throw Exception(_error(e, 'Failed to add favorite'));
    }
  }

  /// REMOVE FAVORITE
  static Future<void> removeFavorite(int productId) async {
    try {
      await dio.delete('/favorites/$productId');
    } on DioException catch (e) {
      throw Exception(_error(e, 'Failed to remove favorite'));
    }
  }

  /// CHECK FAVORITE
  static Future<bool> isFavorite(int productId) async {
    try {
      final res = await dio.get('/favorites/check/$productId');
      return res.data['isFavorite'] ?? false;
    } catch (_) {
      return false;
    }
  }
  
  /// GET ALL FAVORITES
  static Future<List<ProductModel>> getFavorites() async {
    try {
      final response = await dio.get('/favorites');

      final List data = response.data['favorites'] ?? [];

      return data.map((json) => ProductModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(_error(e, 'Failed to fetch favorites'));
    }
  }

  /// MAP BACKEND → ProductModel (NO MODEL CHANGE NEEDED)

  static String _error(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'];
    }
    return fallback;
  }
  
}
