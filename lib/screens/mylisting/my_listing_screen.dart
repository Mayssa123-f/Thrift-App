import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/controllers/product_controller.dart';
import 'package:thrift_app/models/product_model.dart';

import '../product/product_details_screen.dart';
import '../sell/multi_step_sell_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final ProductController productController = ProductController();

  bool isLoading = true;
  List<ProductModel> listings = [];

  int selectedFilter = 0;

  static const Color primaryGreen = Color(0xFF18392B);
  static const Color softBg = Color(0xFFF7F7F5);

  List<ProductModel> get activeListings {
    return listings.where((product) => product.isAvailable).toList();
  }

  List<ProductModel> get soldListings {
    return listings.where((product) => !product.isAvailable).toList();
  }

  List<ProductModel> get filteredListings {
    if (selectedFilter == 1) return activeListings;
    if (selectedFilter == 2) return soldListings;
    return listings;
  }

  String _formatDate(DateTime date) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    try {
      setState(() => isLoading = true);

      final result = await productController.getMyListings();

      if (!mounted) return;

      setState(() {
        listings = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MultiStepSellScreen()),
          );

          _loadListings();
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            _buildSearchBar(),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredListings.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadListings,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filteredListings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _buildListingCard(filteredListings[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              "My Listings",
              textAlign: TextAlign.center,
              style: GoogleFonts.syne(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = [
      "All (${listings.length})",
      "Active (${activeListings.length})",
      "Sold (${soldListings.length})",
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = selectedFilter == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => selectedFilter = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  filters[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Colors.black38),
            const SizedBox(width: 10),
            Text(
              "Search your listings",
              style: GoogleFonts.inter(
                color: Colors.black38,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(ProductModel product) {
    final bool isSold = !product.isAvailable;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );

        _loadListings();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                product.image ?? 'https://via.placeholder.com/500',
                width: 122,
                height: 145,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: SizedBox(
                height: 145,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        _statusPill(isSold),
                      ],
                    ),

                    const SizedBox(height: 1),

                    Text(
                      "${product.size ?? 'Size'}    • ${product.conditionType ?? 'Condition'}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      product.formattedPrice,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      product.createdAt != null
                          ? "Listed on ${_formatDate(product.createdAt!)}"
                          : "Recently listed",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),

                    if (isSold)
                      _soldButton(product)
                    else
                      Row(
                        children: [
                          Expanded(child: _editButton(product)),
                          const SizedBox(width: 8),
                          Expanded(child: _deleteButton(product)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deleteButton(ProductModel product) {
    return GestureDetector(
      onTap: () => _confirmDelete(product),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: 17,
              color: Colors.red.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              "Delete",
              style: GoogleFonts.inter(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(bool isSold) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSold ? Colors.grey.shade100 : const Color(0xFFE4F3E8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        isSold ? "Sold" : "Active",
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isSold ? Colors.black45 : primaryGreen,
        ),
      ),
    );
  }

Widget _editButton(ProductModel product) {
  return GestureDetector(
    onTap: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MultiStepSellScreen(
            productToEdit: product,
          ),
        ),
      );

      _loadListings();
    },

    child: Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryGreen),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.edit_outlined,
            size: 17,
            color: primaryGreen,
          ),

          const SizedBox(width: 8),

          Text(
            "Edit",
            style: GoogleFonts.inter(
              color: primaryGreen,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _moreButton(ProductModel product) {
    return PopupMenuButton<String>(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) async {
        if (value == 'delete') {
          await _confirmDelete(product);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'delete',
          child: Text(
            'Delete Listing',
            style: GoogleFonts.inter(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
      child: Container(
        height: 42,
        width: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.more_horiz_rounded),
      ),
    );
  }

  Widget _soldButton(ProductModel product) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );

        _loadListings();
      },
      child: Container(
        height: 42,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.visibility_outlined, size: 17),
            const SizedBox(width: 8),
            Text(
              "View Details",
              style: GoogleFonts.inter(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Delete Listing',
          style: GoogleFonts.syne(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to delete this listing?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await productController.deleteProduct(product.id);

        _loadListings();

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Listing deleted')));
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _buildEmptyState() {
    String text = "No listings yet";
    String subtitle = "Start selling your first pre-loved piece.";

    if (selectedFilter == 1) {
      text = "No active listings";
      subtitle = "Your available items will appear here.";
    }

    if (selectedFilter == 2) {
      text = "No sold listings";
      subtitle = "Sold items will appear here after checkout.";
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 34,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              text,
              style: GoogleFonts.syne(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.black45, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(ProductModel product) async {
    final titleController = TextEditingController(text: product.title);
    final descController = TextEditingController(text: product.description);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Edit Listing',
            style: GoogleFonts.syne(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.black),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                try {
                  await productController.updateProduct(
                    productId: product.id,
                    title: titleController.text,
                    description: descController.text,
                    price: double.parse(priceController.text),
                    category: product.category ?? 'Jackets',
                    size: product.size ?? 'M',
                    conditionType: product.conditionType ?? 'good',
                    gender: product.gender ?? 'unisex',
                    styleTag: product.styleTag ?? 'Vintage',
                  );

                  if (!mounted) return;

                  Navigator.pop(context);
                  _loadListings();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Listing updated')),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: Text(
                'Save',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
