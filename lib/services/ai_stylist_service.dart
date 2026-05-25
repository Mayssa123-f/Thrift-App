import '../models/product_model.dart';
import 'api_client.dart';

class OutfitSuggestion {
  final int categoryId;
  final String tip;
  final List<ProductModel> products;

  OutfitSuggestion({
    required this.categoryId,
    required this.tip,
    required this.products,
  });

  factory OutfitSuggestion.fromJson(Map<String, dynamic> json) {
    final productsJson = json['products'];

    return OutfitSuggestion(
      categoryId: int.tryParse((json['category_id'] ?? 0).toString()) ?? 0,
      tip: json['tip'] ?? '',
      products: productsJson is List
          ? productsJson
                .map(
                  (product) =>
                      ProductModel.fromJson(Map<String, dynamic>.from(product)),
                )
                .toList()
          : [],
    );
  }
}

class AiStylistService {
  Future<List<OutfitSuggestion>> getSuggestions({
    required int productId,
    required String productName,
    required int categoryId,
    String? style,
    String? color,
  }) async {
    final response = await ApiClient.dio.post(
      '/ai/suggest-outfit',
      data: {
        'productId': productId,
        'productName': productName,
        'categoryId': categoryId,
        'style': style,
        'color': color,
      },
    );

    final data = Map<String, dynamic>.from(response.data);
    final suggestions = data['suggestions'];

    if (suggestions is! List) return [];

    return suggestions.map((suggestion) {
      return OutfitSuggestion.fromJson(Map<String, dynamic>.from(suggestion));
    }).toList();
  }
}
