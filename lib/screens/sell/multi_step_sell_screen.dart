import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thrift_app/models/product.dart';
import '../../constants/app_colors.dart';

import '../../services/listing_service.dart';

class MultiStepSellScreen extends StatefulWidget {
  const MultiStepSellScreen({super.key});

  @override
  State<MultiStepSellScreen> createState() => _MultiStepSellScreenState();
}

class _MultiStepSellScreenState extends State<MultiStepSellScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  final List<XFile?> _images = [null, null, null];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = 'Vintage';
  final List<String> _selectedSizes = ['M'];

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (selected != null) setState(() => _images[index] = selected);
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishListing() {
    final title = _titleController.text.trim();
    final price = _priceController.text.trim();

    if (title.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in title and price',
              style: GoogleFonts.inter()),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final newProduct = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      price: '\$$price',
      image: _images[0] != null
          ? _images[0]!.path
          : 'https://images.unsplash.com/photo-1551028719-00167b16eac5?q=80&w=1000',
      category: _selectedCategory,
      tag: _selectedCategory,
      description: _descController.text.trim().isEmpty
          ? 'A unique thrifted piece in great condition.'
          : _descController.text.trim(),
      sizes: _selectedSizes.isEmpty ? ['One Size'] : _selectedSizes,
      seller: 'Mayssa F.',
      sellerImage:
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200',
    );

    ListingService.add(newProduct);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${newProduct.title}" is now listed!',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _currentStep == 0 ? Icons.close : Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () {
            if (_currentStep == 0) {
              Navigator.pop(context);
            } else {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            }
          },
        ),
        title: Text(
          'STEP ${_currentStep + 1} OF $_totalSteps',
          style: GoogleFonts.syne(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // PROGRESS BAR
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey.shade100,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
            minHeight: 3,
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _stepPhotos(),
                _stepDetails(),
                _stepCategory(),
              ],
            ),
          ),

          // BOTTOM BUTTON
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed:
                _currentStep == _totalSteps - 1 ? _finishListing : _nextStep,
                child: Text(
                  _currentStep == _totalSteps - 1 ? 'PUBLISH LISTING' : 'CONTINUE',
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 1: PHOTOS
  Widget _stepPhotos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Photos',
              style: GoogleFonts.syne(
                  fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('First photo will be the cover.',
              style: GoogleFonts.inter(color: Colors.black45, fontSize: 14)),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) => _imageCard(i)),
          ),
          const SizedBox(height: 30),
          Text('Tips for great photos',
              style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black45)),
          const SizedBox(height: 12),
          ...[
            'Use natural lighting',
            'Show any flaws honestly',
            'Include multiple angles',
          ].map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_rounded,
                    size: 16, color: Colors.black),
                const SizedBox(width: 8),
                Text(tip,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.black54)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // STEP 2: DETAILS
  Widget _stepDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Item Details',
              style: GoogleFonts.syne(
                  fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 30),
          _fieldLabel('ITEM NAME'),
          _textField(_titleController, 'e.g. Vintage Leather Jacket'),
          const SizedBox(height: 20),
          _fieldLabel('PRICE (USD)'),
          _textField(_priceController, '0.00', isNumber: true),
          const SizedBox(height: 20),
          _fieldLabel('DESCRIPTION'),
          TextField(
            controller: _descController,
            maxLines: 4,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Describe the condition, style, measurements...',
              hintStyle: GoogleFonts.inter(color: Colors.black26, fontSize: 13),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),
          _fieldLabel('AVAILABLE SIZES'),
          const SizedBox(height: 8),
          _sizePicker(),
        ],
      ),
    );
  }

  // STEP 3: CATEGORY
  Widget _stepCategory() {
    final cats = [
      {'label': 'Vintage', 'icon': Icons.auto_awesome_outlined},
      {'label': 'Streetwear', 'icon': Icons.style_outlined},
      {'label': 'Luxury', 'icon': Icons.diamond_outlined},
      {'label': 'Accessories', 'icon': Icons.watch_outlined},
      {'label': 'Shoes', 'icon': Icons.straighten_outlined},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category',
              style: GoogleFonts.syne(
                  fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Where does your item fit?',
              style: GoogleFonts.inter(color: Colors.black45, fontSize: 14)),
          const SizedBox(height: 30),
          ...cats.map((cat) {
            final isSelected = _selectedCategory == cat['label'];
            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedCategory = cat['label'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.black,
                      size: 22,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      cat['label'] as String,
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _imageCard(int index) {
    final hasImage = _images[index] != null;
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Container(
        width: (MediaQuery.of(context).size.width - 80) / 3,
        height: 130,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? Colors.black : Colors.grey.shade200,
            width: hasImage ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: hasImage
              ? Image.file(File(_images[index]!.path), fit: BoxFit.cover)
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined,
                  color: Colors.grey.shade400),
              const SizedBox(height: 6),
              if (index == 0)
                Text(
                  'COVER',
                  style: GoogleFonts.syne(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sizePicker() {
    final sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'One Size'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sizes.map((size) {
        final isSelected = _selectedSizes.contains(size);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedSizes.remove(size);
              } else {
                _selectedSizes.add(size);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.shade200,
              ),
            ),
            child: Text(
              size,
              style: GoogleFonts.syne(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.syne(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.black45,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        GoogleFonts.inter(color: Colors.black26, fontSize: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}