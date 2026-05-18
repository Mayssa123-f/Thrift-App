
import 'package:thrift_app/models/product_model.dart';

import '../services/product_service.dart';

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
}
