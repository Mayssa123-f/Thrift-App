import 'package:dio/dio.dart';
import 'dart:io';

import 'package:thrift_app/models/product_model.dart';
import 'api_client.dart';

class ProductService {
  final Dio dio = ApiClient.dio;

  Future<List<ProductModel>> getProducts({
    String? category,
    String? style,
    String? search,
  }) async {
    try {
      final response = await dio.get(
        '/products',
        queryParameters: {
          if (category != null && category != 'All') 'category': category,
          if (style != null && style != 'All') 'style': style,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );

      final List products = response.data['products'];

      return products.map((json) => ProductModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load products');
    }
  }

  Future<ProductModel> getProductById(int id) async {
    try {
      final response = await dio.get('/products/$id');

      return ProductModel.fromJson(response.data['product']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load product');
    }
  }

  Future<ProductModel> createProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required String size,
    required String conditionType,
    required String gender,
    required String styleTag,
    required String brand,
    required String color,

    required List<File> images,
  }) async {
    try {
      final formData = FormData();

      formData.fields.addAll([
        MapEntry('title', title),
        MapEntry('description', description),
        MapEntry('price', price.toString()),
        MapEntry('category', category),
        MapEntry('size', size),
        MapEntry('condition_type', conditionType),
        MapEntry('gender', gender),
        MapEntry('style_tag', styleTag),
        MapEntry('brand', brand),
        MapEntry('color', color),
    
      ]);

      for (final file in images) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        );
      }

      final response = await dio.post(
        '/products',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return ProductModel.fromJson(response.data['product']);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to create listing',
      );
    }
  }

  Future<List<ProductModel>> getMyListings() async {
    try {
      final response = await dio.get('/products/my-listings');

      final List products = response.data['products'] ?? [];

      return products.map((json) => ProductModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load your listings',
      );
    }
  }

  // =========================
  // UPDATE PRODUCT
  // =========================
  Future<ProductModel> updateProduct({
    required int productId,
    required String title,
    required String description,
    required double price,
    required String category,
    required String size,
    required String conditionType,
    required String gender,
    required String styleTag,
  }) async {
    try {
      final response = await dio.put(
        '/products/$productId',
        data: {
          'title': title,
          'description': description,
          'price': price,
          'category': category,
          'size': size,
          'condition_type': conditionType,
          'gender': gender,
          'style_tag': styleTag,
        },
      );

      return ProductModel.fromJson(response.data['product']);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update product',
      );
    }
  }

  // =========================
  // DELETE PRODUCT
  // =========================
  Future<void> deleteProduct(int productId) async {
    try {
      await dio.delete('/products/$productId');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to delete product',
      );
    }
  }
}
