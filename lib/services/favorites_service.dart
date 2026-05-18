import 'package:dio/dio.dart';
import '../models/product_model.dart';
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

      return data.map((json) => _mapToProduct(json)).toList();
    } on DioException catch (e) {
      throw Exception(_error(e, 'Failed to fetch favorites'));
    }
  }

  /// MAP BACKEND → ProductModel (NO MODEL CHANGE NEEDED)
  static ProductModel _mapToProduct(Map json) {
    return ProductModel(
      id: json['product_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      currency: json['currency'] ?? 'USD',
      brand: json['brand'],
      size: json['size'],
      conditionType: json['condition_type'],
      gender: json['gender'],
      styleTag: json['style_tag'],
      location: json['location'],
      category: json['category'],

      sellerId: 0, // not returned in favorites query
      seller: json['seller_name'] ?? 'Unknown Seller',
      sellerImage: json['seller_image'],

      image: null,
      images: [],
    );
  }

  static String _error(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'];
    }
    return fallback;
  }
}