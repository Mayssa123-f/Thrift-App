import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../constants/app_colors.dart';
import '../../controllers/product_controller.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';
import '../../services/favorites_service.dart';
import '../product/product_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final String search;

  const HomeScreen({super.key, required this.search});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductController productController = ProductController();

  String selectedStyle = 'All';

  bool isLoading = true;
  List<ProductModel> products = [];

  /// store favorites locally for fast UI updates
  Set<int> favoriteIds = {};

  final List<String> styleTags = [
    'All',
    'Vintage',
    'Y2K',
    'Streetwear',
    'Old Money',
    'Minimal',
    'Grunge',
    'Luxury',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadFavorites();
  }

  /// load favorites from backend
  Future<void> _loadFavorites() async {
    try {
      final favs = await FavoritesService.getFavorites();

      if (!mounted) return;

      setState(() {
        favoriteIds = favs.map((e) => e.id).toSet();
      });
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.search != widget.search) {
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => isLoading = true);

      final result = await productController.getProducts(
        style: selectedStyle,
        search: widget.search,
      );

      if (!mounted) return;

      setState(() {
        products = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  double _cardHeight(int index) {
    final heights = [230.0, 310.0, 260.0, 340.0, 280.0];
    return heights[index % heights.length];
  }

  bool _isFav(int id) => favoriteIds.contains(id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const SizedBox(height: 10),

          /// STYLE FILTER
          SizedBox(
            height: 55,
            width: double.infinity,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: styleTags.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final style = styleTags[index];
                final isActive = style == selectedStyle;

                return GestureDetector(
                  onTap: () {
                    setState(() => selectedStyle = style);
                    _loadProducts();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? Colors.black
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      style,
                      style: GoogleFonts.inter(
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

          const SizedBox(height: 18),

          /// GRID
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
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
              padding:
              const EdgeInsets.fromLTRB(18, 0, 18, 120),
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 14,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                return ProductCard(
                  product: product,
                  imageHeight: _cardHeight(index),

                  /// IMPORTANT:
                  /// ❌ removed isFavorite (not supported in your ProductCard)
                  /// ProductCard already handles favorites internally via service

                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsScreen(
                          product: product,
                        ),
                      ),
                    );

                    /// refresh favorites after returning
                    _loadFavorites();
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