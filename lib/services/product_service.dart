import 'package:dio/dio.dart';
import '../models/product_model.dart';
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
    throw Exception(
      e.response?.data['message'] ?? 'Failed to load products',
    );
  }
}
  Future<ProductModel> getProductById(int id) async {
    try {
      final response = await dio.get('/products/$id');

      return ProductModel.fromJson(response.data['product']);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load product',
      );
    }
  }
}