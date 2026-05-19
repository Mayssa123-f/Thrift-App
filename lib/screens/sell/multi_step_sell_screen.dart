import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/product_controller.dart';

class MultiStepSellScreen extends StatefulWidget {
  const MultiStepSellScreen({super.key});

  @override
  State<MultiStepSellScreen> createState() => _MultiStepSellScreenState();
}

class _MultiStepSellScreenState extends State<MultiStepSellScreen> {
  final PageController _pageController = PageController();
  final ProductController _productController = ProductController();
  final ImagePicker _picker = ImagePicker();

  int _currentStep = 0;
  final int _totalSteps = 3;
  bool _isPublishing = false;

  // TEXT FIELDS
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // IMAGES (FIXED → FILES ONLY)
  final List<File> _images = [];

  String _selectedCategory = 'Jackets';
  String _selectedCondition = 'like_new';
  String _selectedGender = 'unisex';
  String _selectedSize = 'M';

  final Map<String, String> _categoryStyleMap = {
    'Jackets': 'Vintage',
    'Hoodies': 'Streetwear',
    'Shoes': 'Streetwear',
    'Pants': 'Streetwear',
    'Tops': 'Minimal',
    'Accessories': 'Luxury',
    'Bags': 'Luxury',
    'Shorts': 'Streetwear',
    'Jeans': 'Vintage',
    'Shirts': 'Old Money',
    'Sneakers': 'Streetwear',
    'Coats': 'Old Money',
    'Dresses': 'Luxury',
  };

  final List<String> _categories = [
    'Jackets', 'Hoodies', 'Shoes', 'Pants', 'Tops',
    'Accessories', 'Bags', 'Shorts', 'Jeans',
    'Shirts', 'Sneakers', 'Coats', 'Dresses',
  ];

  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'One Size'];
  final List<String> _conditions = ['new', 'like_new', 'good', 'used'];
  final List<String> _genders = ['men', 'women', 'unisex'];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ================= IMAGE PICK =================
  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _images.add(File(picked.path)));
    }
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _images.add(File(picked.path)));
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  // ================= FIXED PUBLISH =================
  Future<void> _finishListing() async {
    final title = _titleController.text.trim();
    final priceText = _priceController.text.trim();

    if (title.isEmpty) return _showSnack("Enter title");
    if (priceText.isEmpty || double.tryParse(priceText) == null) {
      return _showSnack("Enter valid price");
    }
    if (_images.isEmpty) return _showSnack("Add at least 1 image");

    setState(() => _isPublishing = true);

    try {
      await _productController.createProduct(
        title: title,
        description: _descController.text.trim().isEmpty
            ? 'A unique thrifted piece in great condition.'
            : _descController.text.trim(),
        price: double.parse(priceText),
        category: _selectedCategory,
        size: _selectedSize,
        conditionType: _selectedCondition,
        gender: _selectedGender,
        styleTag: _categoryStyleMap[_selectedCategory] ?? 'Vintage',

        // ✅ FIX: send FILES (backend upload handles them)
        images: _images,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================
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
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey.shade100,
            valueColor: const AlwaysStoppedAnimation(Colors.black),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _stepImages(),
                _stepDetails(),   // ✅ YOUR DESIGN PRESERVED
                _stepCategory(),   // ✅ YOUR DESIGN PRESERVED
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _isPublishing
                    ? null
                    : (_currentStep == _totalSteps - 1
                    ? _finishListing
                    : _nextStep),
                child: Text(
                  _currentStep == _totalSteps - 1
                      ? "PUBLISH LISTING"
                      : "CONTINUE",
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= STEP 1 (UNCHANGED STYLE) =================
  Widget _stepImages() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo),
                  label: const Text("Gallery"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_images.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                itemBuilder: (c, i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(
                      children: [
                        Image.file(_images[i],
                            width: 100, height: 120, fit: BoxFit.cover),
                        Positioned(
                          right: 5,
                          top: 5,
                          child: GestureDetector(
                            onTap: () => setState(() => _images.removeAt(i)),
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            )
        ],
      ),
    );
  }

  // ================= YOUR ORIGINAL STEP 2 =================
  Widget _stepDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          _fieldLabel('ITEM NAME'),
          _textField(_titleController, 'e.g. Vintage Jacket'),

          const SizedBox(height: 20),

          _fieldLabel('PRICE'),
          _textField(_priceController, '0.00', isNumber: true),

          const SizedBox(height: 20),

          _fieldLabel('DESCRIPTION'),
          TextField(controller: _descController),
        ],
      ),
    );
  }

  // ================= YOUR ORIGINAL STEP 3 =================
  Widget _stepCategory() {
    return ListView(
      padding: const EdgeInsets.all(25),
      children: _categories.map((c) {
        return ListTile(
          title: Text(c),
          trailing:
          _selectedCategory == c ? const Icon(Icons.check) : null,
          onTap: () => setState(() => _selectedCategory = c),
        );
      }).toList(),
    );
  }

  Widget _fieldLabel(String t) => Text(t);
  Widget _textField(TextEditingController c, String h,
      {bool isNumber = false}) =>
      TextField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(hintText: h),
      );
}