import 'dart:io';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final int _totalSteps = 4;

  bool _isPublishing = false;

  // TEXT CONTROLLERS
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _shoeSizeController = TextEditingController();
  String _selectedColorName = 'Black';
  Color _selectedColor = Colors.black;

  // IMAGES
  final List<File> _images = [];

  // DATA
  String _selectedCategory = 'Jackets';
  String _selectedCondition = 'like_new';
  String _selectedGender = 'unisex';
  String _selectedSize = 'M';
  String _selectedStyle = 'Vintage';
  String? _titleError;
  String? _priceError;
  String? _shoeSizeError;

  final List<String> _categories = [
    'Jackets',
    'Hoodies',
    'Shoes',
    'Pants',
    'Tops',
    'Accessories',
    'Bags',
    'Shorts',
    'Jeans',
    'Shirts',
    'Sneakers',
    'Coats',
    'Dresses',
  ];

  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'One Size'];

  final List<String> _conditions = ['new', 'like_new', 'good', 'used'];

  final List<String> _genders = ['men', 'women', 'unisex'];

  final List<String> _styles = [
    'Vintage',
    'Streetwear',
    'Minimal',
    'Luxury',
    'Old Money',
    'Y2K',
  ];
  bool get _isShoeCategory {
    return _selectedCategory == 'Shoes' || _selectedCategory == 'Sneakers';
  }

  bool get _isTitleValid {
    return _titleController.text.trim().isNotEmpty;
  }

  bool get _isPriceValid {
    final price = double.tryParse(_priceController.text.trim());

    return price != null && price > 0;
  }

  bool get _isShoeSizeValid {
    if (!_isShoeCategory) return true;

    final size = int.tryParse(_shoeSizeController.text.trim());

    return size != null && size >= 20 && size <= 48;
  }

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _images.isNotEmpty;

      case 1:
        return _isTitleValid && _isPriceValid;

      case 2:
        return _isShoeSizeValid;

      default:
        return true;
    }
  }

  void _validateFields() {
    setState(() {
      // TITLE
      _titleError = _titleController.text.trim().isEmpty
          ? 'Please add a title'
          : null;

      // PRICE
      final price = double.tryParse(_priceController.text.trim());

      _priceError = price == null || price <= 0 ? 'Enter a valid price' : null;

      // SHOE SIZE
      if (_isShoeCategory) {
        final size = int.tryParse(_shoeSizeController.text.trim());

        _shoeSizeError = size == null || size < 20 || size > 48
            ? 'Enter an EU size between 20–48'
            : null;
      } else {
        _shoeSizeError = null;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _brandController.dispose();
    _shoeSizeController.dispose();
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

  Future<void> _openColorPicker() async {
    Color tempColor = _selectedColor;

    await ColorPicker(
      color: tempColor,

      onColorChanged: (Color color) {
        tempColor = color;
      },

      borderRadius: 16,

      spacing: 10,
      runSpacing: 10,
      wheelDiameter: 180,

      heading: Text(
        'Select Color',
        style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 18),
      ),

      subheading: Text('Choose any color', style: GoogleFonts.inter()),

      pickersEnabled: const {
        ColorPickerType.wheel: true,
        ColorPickerType.primary: false,
        ColorPickerType.accent: false,
        ColorPickerType.both: false,
        ColorPickerType.custom: false,
      },
    ).showPickerDialog(context, backgroundColor: Colors.white);

    setState(() {
      _selectedColor = tempColor;
      _selectedColorName =
          '#${tempColor.value.toRadixString(16).substring(2).toUpperCase()}';
    });
  }
  // ================= NAVIGATION =================

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ================= PUBLISH =================

  Future<void> _finishListing() async {
    final title = _titleController.text.trim();
    final price = _priceController.text.trim();

    if (title.isEmpty) {
      return _showSnack('Please enter a title');
    }

    if (price.isEmpty || double.tryParse(price) == null) {
      return _showSnack('Please enter a valid price');
    }

    if (_images.isEmpty) {
      return _showSnack('Add at least one photo');
    }
    if (_isShoeCategory) {
      final shoeSize = int.tryParse(_shoeSizeController.text.trim());

      if (shoeSize == null) {
        return _showSnack('Enter a valid EU shoe size');
      }

      if (shoeSize < 20 || shoeSize > 48) {
        return _showSnack('EU shoe size must be between 20 and 48');
      }
    }
    setState(() => _isPublishing = true);

    try {
      await _productController.createProduct(
        title: title,
        description: _descController.text.trim().isEmpty
            ? 'A unique thrifted piece in great condition.'
            : _descController.text.trim(),
        price: double.parse(price),
        category: _selectedCategory,
        size: _isShoeCategory ? _shoeSizeController.text.trim() : _selectedSize,
        conditionType: _selectedCondition,
        gender: _selectedGender,
        styleTag: _selectedStyle,
        brand: _brandController.text.trim(),
        color: _selectedColorName,
        images: _images,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
          onPressed: _previousStep,
          icon: Icon(
            _currentStep == 0 ? Icons.close : Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        title: Text(
          'STEP ${_currentStep + 1} OF $_totalSteps',
          style: GoogleFonts.syne(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: Colors.black,
          ),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: List.generate(_totalSteps, (index) {
                final isActive = index <= _currentStep;

                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 5,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.black : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) {
                setState(() => _currentStep = i);
              },
              children: [
                _photosStep(),
                _detailsStep(),
                _attributesStep(),
                _reviewStep(),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 34),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: (_isPublishing || !_canContinue)
                    ? null
                    : (_currentStep == _totalSteps - 1
                          ? _finishListing
                          : _nextStep),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _canContinue
                      ? Colors.black
                      : Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: _isPublishing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _currentStep == _totalSteps - 1
                            ? 'PUBLISH LISTING'
                            : 'CONTINUE',
                        style: GoogleFonts.syne(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= STEP 1 =================

  Widget _photosStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PHOTOS',
            style: GoogleFonts.syne(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'The first photo will be the cover.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
          ),

          const SizedBox(height: 12),

          if (_images.isNotEmpty)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    _images.first,
                    height: 320,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'COVER',
                      style: GoogleFonts.syne(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: _pickFromGallery,
              child: Container(
                height: 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image_outlined, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      'Add Photo',
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to upload',
                      style: GoogleFonts.inter(
                        color: Colors.black45,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_images.isNotEmpty) ...[
            const SizedBox(height: 10),

            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return Stack(
                    children: [
                      Container(
                        width: 58,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: i == 0 ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(_images[i], fit: BoxFit.cover),
                        ),
                      ),

                      Positioned(
                        top: 3,
                        right: 3,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _images.removeAt(i));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 11),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 20),

          Container(
            height: 82,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickFromGallery,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_outlined, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          'GALLERY',
                          style: GoogleFonts.syne(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Container(width: 1, height: 44, color: Colors.grey.shade300),

                Expanded(
                  child: InkWell(
                    onTap: _takePhoto,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          'CAMERA',
                          style: GoogleFonts.syne(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _tipCard(),
        ],
      ),
    );
  }
  // ================= STEP 2 =================

  Widget _detailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 8),

          Text(
            'Add the key information about your item.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
          ),

          const SizedBox(height: 30),

          _sectionLabel('Item Name *'),
          _modernField(
            controller: _titleController,
            hint: 'e.g. Vintage Leather Jacket',
            errorText: _titleError,
          ),

          const SizedBox(height: 24),

          _sectionLabel('Price *'),
          _modernField(
            controller: _priceController,
            hint: 'e.g. 45.00',
            isNumber: true,
            suffix: 'USD',
            errorText: _priceError,
          ),

          const SizedBox(height: 24),

          _sectionLabel('Brand'),
          _modernField(
            controller: _brandController,
            hint: "e.g. Zara, Nike, Levi's",
          ),

          const SizedBox(height: 24),

          _sectionLabel('Description'),
          _modernField(
            controller: _descController,
            hint:
                'Describe your item, its condition, flaws\nif any, and any other details.',
            maxLines: 6,
          ),
        ],
      ),
    );
  }
  // ================= STEP 3 =================

  Widget _attributesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STYLE & INFO',
            style: GoogleFonts.syne(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Select the details that best match your item.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
          ),

          const SizedBox(height: 26),

          _sectionLabel('CATEGORY *'),
          _optionGrid(
            values: [
              'Jackets',
              'Hoodies',
              'Tops',
              'Pants',
              'Shoes',
              'Accessories',
              'Bags',
              'Jeans',
              'Dresses',
            ],
            selected: _selectedCategory,
            onSelected: (value) {
              setState(() {
                _selectedCategory = value;
                _selectedStyle = _styleFromCategory(value);
              });
            },
            columns: 3,
          ),

          const SizedBox(height: 28),

          _sectionLabel(_isShoeCategory ? 'EU SHOE SIZE *' : 'SIZE *'),

          if (_isShoeCategory)
            _modernField(
              controller: _shoeSizeController,
              hint: 'e.g. 42',
              isNumber: true,
              errorText: _shoeSizeError,
            )
          else
            _optionGrid(
              values:
                  _selectedCategory == 'Bags' ||
                      _selectedCategory == 'Accessories'
                  ? ['One Size']
                  : ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'One Size'],
              selected: _selectedSize,
              onSelected: (value) {
                setState(() => _selectedSize = value);
              },
              columns: 6,
            ),
          const SizedBox(height: 28),

          _sectionLabel('CONDITION *'),
          _optionGrid(
            values: ['new', 'like_new', 'good', 'used'],
            selected: _selectedCondition,
            onSelected: (value) {
              setState(() => _selectedCondition = value);
            },
            columns: 4,
            displayText: (value) => _prettyValue(value),
          ),

          const SizedBox(height: 28),

          _sectionLabel('GENDER *'),
          _optionGrid(
            values: ['men', 'women', 'unisex'],
            selected: _selectedGender,
            onSelected: (value) {
              setState(() => _selectedGender = value);
            },
            columns: 3,
            displayText: (value) => _prettyValue(value),
          ),

          const SizedBox(height: 28),

          _sectionLabel('COLOR'),

          const SizedBox(height: 8),

          _colorSelector(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
  // ================= STEP 4 =================

  Widget _reviewStep() {
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Item'
        : _titleController.text.trim();

    final price = _priceController.text.trim().isEmpty
        ? '0.00'
        : _priceController.text.trim();

    final brand = _brandController.text.trim().isEmpty
        ? '—'
        : _brandController.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 8),

          Text(
            'Review your listing before publishing.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
          ),

          const SizedBox(height: 16),

          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _images.isNotEmpty
                    ? Image.file(
                        _images.first,
                        height: 245,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 245,
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image_outlined, size: 42),
                      ),
              ),

              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    _pageController.jumpToPage(0);
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        'EDIT',
                        style: GoogleFonts.syne(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _images.length > 3 ? 3 : _images.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '\$$price',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _previewRow('Brand', brand),
          _previewRow('Category', _selectedCategory),
          _previewRow('Size', _selectedSize),
          _previewRow('Condition', _prettyValue(_selectedCondition)),
          _previewRow('Gender', _prettyValue(_selectedGender)),
          _previewRowWithColor('Color', _selectedColorName),

          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "You're covered",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Your item will go live after our team reviews it.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.black54,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // GestureDetector(
          //   onTap: _finishListing,
          //   child: Container(
          //     height: 52,
          //     width: double.infinity,
          //     alignment: Alignment.center,
          //     decoration: BoxDecoration(
          //       color: Colors.black,
          //       borderRadius: BorderRadius.circular(6),
          //     ),
          //     child: Text(
          //       'PUBLISH LISTING',
          //       style: GoogleFonts.syne(
          //         color: Colors.white,
          //         fontSize: 12,
          //         fontWeight: FontWeight.w800,
          //         letterSpacing: 1.2,
          //       ),
          //     ),
          //   ),
          // ),

          // const SizedBox(height: 18),

          // Center(
          //   child: GestureDetector(
          //     onTap: () {
          //       _pageController.jumpToPage(1);
          //     },
          //     child: Text(
          //       'EDIT LISTING',
          //       style: GoogleFonts.syne(
          //         fontSize: 13,
          //         fontWeight: FontWeight.w800,
          //         letterSpacing: 1.2,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
  // ================= COMPONENTS =================

  Widget _title(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.syne(
            fontSize: 38,
            height: 1,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 15, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.syne(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _modernField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
    int maxLines = 1,
    String? prefix,
    String? suffix,
    String? errorText,
  }) {
    return TextField(
      onChanged: (_) {
        _validateFields();
      },
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,

        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),

        prefixText: prefix,

        suffixText: suffix,

        suffixStyle: GoogleFonts.inter(
          color: Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),

        filled: true,

        fillColor: errorText != null ? const Color(0xFFFFFAFA) : Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: errorText != null
                ? const Color(0xFFFF5A5F)
                : Colors.grey.shade300,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: errorText != null ? const Color(0xFFFF5A5F) : Colors.black,
            width: 1.2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF5A5F)),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF5A5F), width: 1.2),
        ),

        errorText: errorText,
      ),
    );
  }

  Widget _modernDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _chipSelector({
    required List<String> values,
    required String selected,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.map((item) {
        final isSelected = item == selected;

        return GestureDetector(
          onTap: () => onSelected(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              item.replaceAll('_', ' ').toUpperCase(),
              style: GoogleFonts.syne(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _uploadButton({
    required String title,
    required IconData icon,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: dark ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: dark ? Colors.white : Colors.black),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.syne(
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TIPS FOR GREAT PHOTOS',
            style: GoogleFonts.syne(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 18),
          _tip('Use natural lighting'),
          _tip('Show flaws honestly'),
          _tip('Include multiple angles'),
        ],
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18),
          const SizedBox(width: 10),
          Text(text, style: GoogleFonts.inter(color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _reviewTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _optionGrid({
    required List<String> values,
    required String selected,
    required Function(String) onSelected,
    required int columns,
    String Function(String value)? displayText,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 8;
        final double itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 8,
          children: values.map((value) {
            final bool isSelected = value == selected;

            return GestureDetector(
              onTap: () => onSelected(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: itemWidth,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  displayText != null ? displayText(value) : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Widget _colorSelector() {
  //   final colors = <Map<String, dynamic>>[
  //     {'name': 'Black', 'value': Colors.black},
  //     {'name': 'White', 'value': Colors.white},
  //     {'name': 'Grey', 'value': const Color(0xFF9E9E9E)},
  //     {'name': 'Brown', 'value': const Color(0xFF8B6B4A)},
  //     {'name': 'Beige', 'value': const Color(0xFFD8C7A7)},
  //     {'name': 'Navy', 'value': const Color(0xFF152744)},
  //     {'name': 'Green', 'value': const Color(0xFF244C3A)},
  //   ];

  //   return Row(
  //     children: colors.map((colorData) {
  //       final String name = colorData['name'];
  //       final Color color = colorData['value'];
  //       final bool isSelected = _colorController.text == name;

  //       return GestureDetector(
  //         onTap: () {
  //           setState(() {
  //             _colorController.text = name;
  //           });
  //         },
  //         child: AnimatedContainer(
  //           duration: const Duration(milliseconds: 180),
  //           margin: const EdgeInsets.only(right: 12),
  //           width: 30,
  //           height: 30,
  //           decoration: BoxDecoration(
  //             color: color,
  //             shape: BoxShape.circle,
  //             border: Border.all(
  //               color: isSelected ? Colors.black : Colors.grey.shade300,
  //               width: isSelected ? 2 : 1,
  //             ),
  //           ),
  //           child: isSelected
  //               ? Icon(
  //                   Icons.check_rounded,
  //                   size: 17,
  //                   color: name == 'White' || name == 'Beige'
  //                       ? Colors.black
  //                       : Colors.white,
  //                 )
  //               : null,
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }
  Widget _colorSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _quickColor('Black', Colors.black),
        _quickColor('White', Colors.white),
        _quickColor('Grey', const Color(0xFF9E9E9E)),
        _quickColor('Brown', const Color(0xFF8B6B4A)),
        _quickColor('Beige', const Color(0xFFD8C7A7)),
        _quickColor('Navy', const Color(0xFF152744)),
        _quickColor('Green', const Color(0xFF244C3A)),
        _quickColor('Red', const Color(0xFFB00020)),

        if (_selectedColorName.startsWith('#')) _customColorCircle(),

        GestureDetector(
          onTap: _openColorPicker,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.add, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _customColorCircle() {
    final bool isSelected = _selectedColorName.startsWith('#');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _selectedColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: isSelected
          ? Icon(
              Icons.check,
              size: 16,
              color: _selectedColor.computeLuminance() > 0.55
                  ? Colors.black
                  : Colors.white,
            )
          : null,
    );
  }

  String _prettyValue(String value) {
    return value
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _styleFromCategory(String category) {
    final map = {
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

    return map[category] ?? 'Vintage';
  }

  Widget _quickColor(String name, Color color) {
    final bool isSelected = _selectedColorName == name;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColorName = name;
          _selectedColor = color;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 10),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 16,
                color: name == 'White' || name == 'Beige'
                    ? Colors.black
                    : Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _previewRowWithColor(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
          ),
          const Spacer(),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: _selectedColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
