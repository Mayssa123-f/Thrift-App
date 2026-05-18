import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../constants/app_colors.dart';
import '../../data/mock_products.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../product/product_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final String search;

  const HomeScreen({super.key, required this.search});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Vintage',
    'Streetwear',
    'Shoes',
    'Accessories',
    'Luxury',
    'Y2K',
    'Minimal',
    'Grunge',
  ];
  List<Product> get filteredProducts {
    final byCategory = MockProducts.byCategory(selectedCategory);

    if (widget.search.isEmpty) return byCategory;

    return byCategory.where((p) {
      final search = widget.search.toLowerCase();

      return p.title.toLowerCase().contains(search) ||
          p.tag.toLowerCase().contains(search) ||
          p.category.toLowerCase().contains(search) ||
          p.seller.toLowerCase().contains(search);
    }).toList();
  }

  double _cardHeight(int index) {
    final pattern = [270.0, 340.0, 300.0, 250.0, 315.0];
    return pattern[index % pattern.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const SizedBox(height: 10),

          SizedBox(
            height: 56,
            width: double.infinity,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isActive = cat == selectedCategory;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => selectedCategory = cat);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive ? Colors.black : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Text(
                      'No items found',
                      style: GoogleFonts.syne(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : MasonryGridView.count(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                    crossAxisCount: 2,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 14,
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];

                      return ProductCard(
                        product: product,
                        imageHeight: _cardHeight(index),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailsScreen(product: product),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
