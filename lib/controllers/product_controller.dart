import 'dart:io';

import 'package:thrift_app/models/product_model.dart';
import 'package:thrift_app/services/product_service.dart';

class ProductController {
  final ProductService _productService = ProductService();

  Future<List<ProductModel>> getProducts({
    String? category,
    String? style,
    String? search,
  }) async {
    return await _productService.getProducts(
      category: category,
      style: style,
      search: search,
    );
  }

  Future<ProductModel> getProductById(int id) async {
    return await _productService.getProductById(id);
  }

  // =========================
  // FIXED: CREATE PRODUCT
  // =========================
  Future<ProductModel> createProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required String size,
    required String conditionType,
    required String gender,
    required String styleTag,
    required List<File> images, // 👈 CHANGED HERE
  }) async {
    return await _productService.createProduct(
      title: title,
      description: description,
      price: price,
      category: category,
      size: size,
      conditionType: conditionType,
      gender: gender,
      styleTag: styleTag,
      images: images,
    );
  }

  Future<List<ProductModel>> getMyListings() async {
    return await _productService.getMyListings();
  }
}