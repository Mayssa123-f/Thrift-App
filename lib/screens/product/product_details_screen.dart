import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/controllers/cart_controller.dart';
import 'package:thrift_app/models/product_model.dart';

import '../../constants/app_colors.dart';
import '../../controllers/chat_controller.dart';
import '../../services/favorites_service.dart';
import '../../widgets/ai_stylist_section.dart';
import '../chat/chat_room_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String selectedSize = '';
  final CartController cartController = CartController();
  late final PageController _imageController;

  bool isFav = false;
  bool isLoadingFav = true;
  bool isOpeningChat = false;
  int currentImageIndex = 0;

  @override
  void initState() {
    super.initState();

    _imageController = PageController();
    selectedSize = widget.product.sizes.isNotEmpty
        ? widget.product.sizes.first
        : '';

    _initFavorite();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _initFavorite() async {
    try {
      final result = await FavoritesService.isFavorite(widget.product.id);
      if (!mounted) return;
      setState(() {
        isFav = result;
        isLoadingFav = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoadingFav = false);
    }
  }

  Future<void> _toggleFav() async {
    if (isLoadingFav) return;

    try {
      setState(() => isFav = !isFav);

      if (isFav) {
        await FavoritesService.addFavorite(widget.product.id);
        _showSnack('Added to favorites');
      } else {
        await FavoritesService.removeFavorite(widget.product.id);
        _showSnack('Removed from favorites');
      }
    } catch (e) {
      setState(() => isFav = !isFav);
      _showSnack('Failed to update favorites');
    }
  }

  Future<void> _addToCart() async {
    if (!widget.product.isAvailable) {
      _showSnack('This item is no longer available');
      return;
    }

    try {
      await cartController.addToCart(
        productId: widget.product.id,
        selectedSize: selectedSize.isNotEmpty ? selectedSize : null,
      );
      if (!mounted) return;
      _showSnack('${widget.product.title} added to cart');
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _messageSeller() async {
    if (isOpeningChat) return;
    setState(() => isOpeningChat = true);

    try {
      final chatController = ChatController();

      final conversation = await chatController.startConversation(
        productId: widget.product.id,
        sellerId: widget.product.sellerId,
      );

      await chatController.sendProductMessage(
        conversationId: conversation.id,
        productId: widget.product.id,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            conversation: conversation,
            receiverName: widget.product.seller,
            receiverImage: widget.product.sellerImage,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isOpeningChat = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(milliseconds: 1100),
        backgroundColor: AppColors.black,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  List<String> get _galleryImages {
    final images = <String>{};
    final mainImage = widget.product.image?.trim();

    if (mainImage != null && mainImage.isNotEmpty) {
      images.add(mainImage);
    }

    for (final image in widget.product.images) {
      final cleanImage = image.trim();
      if (cleanImage.isNotEmpty) {
        images.add(cleanImage);
      }
    }

    if (images.isEmpty) {
      return ['https://via.placeholder.com/600x800?text=Thrift+Piece'];
    }

    return images.toList();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeroAppBar(product),
          SliverToBoxAdapter(child: _buildDetailsPanel(product)),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(product),
    );
  }

  SliverAppBar _buildHeroAppBar(ProductModel product) {
    final images = _galleryImages;

    return SliverAppBar(
      expandedHeight: 430,
      pinned: true,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 70,
      leading: _roundIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.pop(context),
      ),
      actions: [
        _roundIconButton(
          icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: isFav ? Colors.redAccent : AppColors.black,
          isLoading: isLoadingFav,
          onTap: _toggleFav,
        ),
        const SizedBox(width: 10),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: product.image ?? product.id,
              child: PageView.builder(
                controller: _imageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() => currentImageIndex = index);
                },
                itemBuilder: (context, index) {
                  return Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _imagePlaceholder();
                    },
                    errorBuilder: (_, _, _) => _imagePlaceholder(),
                  );
                },
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.30),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.48),
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _imageStatusPill(product.isAvailable),
                      const Spacer(),
                      if (images.length > 1) _imageDots(images.length),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.syne(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsPanel(ProductModel product) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 122),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 22),
          _buildTagRow(product),
          const SizedBox(height: 18),
          _buildMetaChips(product),
          const SizedBox(height: 22),
          _sellerCard(product),
          const SizedBox(height: 28),
          _sectionTitle('About this piece'),
          const SizedBox(height: 10),
          Text(
            _hasText(product.description)
                ? product.description.trim()
                : 'No description provided yet.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.65,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (product.sizes.isNotEmpty) ...[
            const SizedBox(height: 30),
            _buildSizeSection(product),
          ],
          AiStylistSection(
            productId: product.id,
            productName: product.title,
            categoryId: product.categoryId,
            style: product.styleTag,
            color: product.color,
          ),
        ],
      ),
    );
  }

  Widget _buildTagRow(ProductModel product) {
    final primaryTag = _hasText(product.styleTag)
        ? product.styleTag!
        : 'Curated';
    final category = _hasText(product.category)
        ? product.category!
        : 'Thrift find';

    return Row(
      children: [
        Expanded(child: _pill(primaryTag, AppColors.black, Colors.white)),
        const SizedBox(width: 10),
        Expanded(
          child: _pill(
            category,
            const Color(0xFFF2F2EF),
            AppColors.darkGray,
            icon: Icons.sell_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildMetaChips(ProductModel product) {
    final chips = <Widget>[
      if (_hasText(product.brand))
        _detailChip(Icons.verified_outlined, product.brand!.trim()),
      if (_hasText(product.conditionType))
        _detailChip(
          Icons.auto_awesome_motion_outlined,
          product.conditionType!.trim(),
        ),
      if (_hasText(product.color))
        _detailChip(Icons.palette_outlined, product.color!.trim()),
      if (_hasText(product.gender))
        _detailChip(Icons.person_outline_rounded, product.gender!.trim()),
      if (_hasText(product.location))
        _detailChip(Icons.location_on_outlined, product.location!.trim()),
    ];

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 10, runSpacing: 10, children: chips);
  }

  Widget _buildSizeSection(ProductModel product) {
    final sizeOptions = _sizeOptions(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionTitle('Size'),
            const Spacer(),
            Text(
              selectedSize,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: sizeOptions.map((size) {
            final selected = _sameSize(size, selectedSize);

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _sizeBubble(size, selected),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _sizeBubble(String size, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.black : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.black : Colors.grey.shade300,
        ),
      ),
      child: Text(
        size.toUpperCase(),
        style: GoogleFonts.syne(
          color: selected ? Colors.white : Colors.grey.shade500,
          fontSize: size.length > 2 ? 11 : 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _sellerCard(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _sellerAvatar(product),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.seller,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.syne(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _sellerHandle(product.seller),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          _sellerMessageButton(),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(ProductModel product) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Price',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.formattedPrice,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.syne(
                    color: AppColors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: product.isAvailable
                      ? AppColors.black
                      : Colors.grey.shade300,
                  foregroundColor: product.isAvailable
                      ? Colors.white
                      : Colors.grey.shade600,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19),
                  ),
                  textStyle: GoogleFonts.syne(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: product.isAvailable ? _addToCart : null,
                icon: const Icon(Icons.shopping_bag_rounded, size: 20),
                label: Text(
                  product.isAvailable ? 'Add to Cart' : 'Sold Out',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sellerMessageButton() {
    return Material(
      color: AppColors.black,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isOpeningChat ? null : _messageSeller,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              isOpeningChat
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
              const SizedBox(width: 7),
              Text(
                isOpeningChat ? 'Opening' : 'Message',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = AppColors.black,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 46,
        height: 46,
        margin: const EdgeInsets.only(left: 14, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 21, color: iconColor),
        ),
      ),
    );
  }

  Widget _imageStatusPill(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isAvailable ? AppColors.green : Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isAvailable ? 'Available now' : 'Sold out',
            style: GoogleFonts.inter(
              color: AppColors.black,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageDots(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (index) {
          final selected = index == currentImageIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 18 : 6,
            height: 6,
            margin: EdgeInsets.only(left: index == 0 ? 0 : 5),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }

  Widget _pill(String label, Color bg, Color textColor, {IconData? icon}) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: textColor),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade700),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.darkGray,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.syne(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: AppColors.black,
      ),
    );
  }

  Widget _sellerAvatar(ProductModel product) {
    final image = product.sellerImage?.trim();

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: image != null && image.isNotEmpty
          ? Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _sellerInitial(product.seller),
            )
          : _sellerInitial(product.seller),
    );
  }

  Widget _sellerInitial(String name) {
    return Center(
      child: Text(
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
        style: GoogleFonts.syne(
          color: AppColors.black,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFEDEBE7),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 42,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  List<String> _sizeOptions(ProductModel product) {
    final options = ['XS', 'S', 'M', 'L', 'XL'];

    for (final size in product.sizes) {
      if (!options.any((option) => _sameSize(option, size))) {
        options.add(size);
      }
    }

    return options;
  }

  bool _sameSize(String first, String second) {
    return first.trim().toLowerCase() == second.trim().toLowerCase();
  }

  String _sellerHandle(String seller) {
    final cleanSeller = seller.trim().toLowerCase().replaceAll(' ', '.');
    return cleanSeller.isEmpty ? '@seller' : '@$cleanSeller';
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}