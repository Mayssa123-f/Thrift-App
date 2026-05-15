import '../data/app_data.dart';
import '../models/product.dart';

class CartService {
  static bool isInCart(Product product) {
    return AppData.cart.any((p) => p.id == product.id);
  }

  static void add(Product product) {
    if (!isInCart(product)) {
      AppData.cart.add(product);
    }
  }

  static void remove(Product product) {
    AppData.cart.removeWhere((p) => p.id == product.id);
  }

  static void clear() {
    AppData.cart.clear();
  }

  static double get total {
    return AppData.cart.fold(0, (sum, p) {
      final price = double.tryParse(p.price.replaceAll('\$', '')) ?? 0;
      return sum + price;
    });
  }

  static int get count => AppData.cart.length;
}