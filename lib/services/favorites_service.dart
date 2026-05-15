import '../data/app_data.dart';
import '../models/product.dart';

class FavoritesService {
  static bool isFavorite(Product product) {
    return AppData.favorites.any((p) => p.id == product.id);
  }

  static void toggle(Product product) {
    if (isFavorite(product)) {
      AppData.favorites.removeWhere((p) => p.id == product.id);
    } else {
      AppData.favorites.add(product);
    }
  }

  static void remove(Product product) {
    AppData.favorites.removeWhere((p) => p.id == product.id);
  }

  static int get count => AppData.favorites.length;
}