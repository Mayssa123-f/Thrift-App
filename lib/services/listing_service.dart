import 'package:thrift_app/models/product.dart';

import '../data/app_data.dart';


class ListingService {
  static void add(Product product) {
    AppData.myListings.add(product);
  }

  static void remove(Product product) {
    AppData.myListings.removeWhere((p) => p.id == product.id);
  }

  static List<Product> get all => AppData.myListings;
}