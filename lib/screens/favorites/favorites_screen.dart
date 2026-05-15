import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../data/app_data.dart';
import '../../models/product.dart';
import '../../services/favorites_service.dart';
import '../../widgets/product_card.dart';
import '../product/product_details_screen.dart';
import '../product/product_details_screen.dart';
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Product> get items => AppData.favorites;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'WISHLIST',
          style: GoogleFonts.syne(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 1.2,
            color: Colors.black,
          ),
        ),
      ),
      body: items.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        itemCount: items.length,
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 15,
          childAspectRatio: 0.65,
        ),
        itemBuilder: (context, index) {
          final product = items[index];
          return ProductCard(
            product: product,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProductDetailsScreen(product: product),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_outline_rounded,
              size: 70, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            'Nothing saved yet',
            style: GoogleFonts.syne(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Swipe right or tap ❤️ to save items',
            style: GoogleFonts.inter(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}