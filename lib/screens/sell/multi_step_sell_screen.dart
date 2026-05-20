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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Photos',
            style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'First photo will be the cover.',
            style: GoogleFonts.inter(color: Colors.black45, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // PICK BUTTONS
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library_outlined,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Gallery',
                          style: GoogleFonts.syne(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            color: Colors.black, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Camera',
                          style: GoogleFonts.syne(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // IMAGE PREVIEWS
          if (_images.isEmpty)
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.shade200,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text(
                      'No photos added yet',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Text(
              '${_images.length} photo${_images.length == 1 ? '' : 's'} added',
              style: GoogleFonts.syne(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.black45,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _images[i],
                          width: 120,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // COVER badge on first image
                      if (i == 0)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'COVER',
                              style: GoogleFonts.syne(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      // REMOVE button
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 24),

          // TIPS BOX
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TIPS FOR GREAT PHOTOS',
                  style: GoogleFonts.syne(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.black45,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                ...['Use natural lighting',
                  'Show any flaws honestly',
                  'Include multiple angles']
                    .map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_rounded,
                          size: 14, color: Colors.black54),
                      const SizedBox(width: 8),
                      Text(
                        tip,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
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