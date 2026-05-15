import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../data/mock_products.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../product/product_details_screen.dart';
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
    'All', 'Vintage', 'Streetwear', 'Shoes', 'Accessories', 'Luxury'
  ];

  List<Product> get filteredProducts {
    final byCategory = MockProducts.byCategory(selectedCategory);
    if (widget.search.isEmpty) return byCategory;
    return byCategory.where((p) =>
    p.title.toLowerCase().contains(widget.search.toLowerCase()) ||
        p.tag.toLowerCase().contains(widget.search.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const SizedBox(height: 10),

          // CATEGORY ROW
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isActive = cat == selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? Colors.black : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // PRODUCT GRID
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
                : GridView.builder(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 100),
              itemCount: filteredProducts.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 15,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
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
          ),
        ],
      ),
    );
  }
}