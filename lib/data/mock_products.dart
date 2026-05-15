import '../models/product.dart';

class MockProducts {
  static const List<Product> all = [
    Product(
      id: '1',
      title: 'Vintage Leather Jacket',
      price: '\$45',
      image: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?q=80&w=1000',
      category: 'Vintage',
      tag: 'Rare',
      description: 'A timeless 90s leather jacket in excellent condition. Perfect for layering over any outfit. Minor scuffs add to the authentic vintage character.',
      sizes: ['S', 'M', 'L'],
      seller: 'Mayssa F.',
      sellerImage: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200',
    ),
    Product(
      id: '2',
      title: 'Retro Sneakers',
      price: '\$40',
      image: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?q=80&w=1000',
      category: 'Shoes',
      tag: 'New',
      description: 'Barely worn retro-style sneakers from the early 2000s. Clean white sole, original laces included. A streetwear essential.',
      sizes: ['40', '41', '42', '43', '44'],
      seller: 'Karim B.',
      sellerImage: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200',
    ),
    Product(
      id: '3',
      title: 'Y2K Hoodie',
      price: '\$30',
      image: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?q=80&w=1000',
      category: 'Streetwear',
      tag: 'Y2K',
      description: 'Classic early 2000s oversized hoodie. Soft fleece interior, faded wash for that authentic vintage feel. One of a kind.',
      sizes: ['M', 'L', 'XL'],
      seller: 'Sara K.',
      sellerImage: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=200',
    ),
    Product(
      id: '4',
      title: 'Denim Bomber',
      price: '\$35',
      image: 'https://images.unsplash.com/photo-1576905341939-422a996894c9?q=80&w=1000',
      category: 'Vintage',
      tag: 'Vintage',
      description: 'Light wash denim bomber with original stitching intact. Great structure, fits true to size. Goes with everything.',
      sizes: ['XS', 'S', 'M'],
      seller: 'Lara M.',
      sellerImage: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200',
    ),
    Product(
      id: '5',
      title: 'Graphic Tee',
      price: '\$18',
      image: 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?q=80&w=1000',
      category: 'Streetwear',
      tag: 'Basic',
      description: 'Vintage band tee with a faded print that still looks incredible. 100% cotton, washed to perfection over the years.',
      sizes: ['S', 'M', 'L', 'XL'],
      seller: 'Omar T.',
      sellerImage: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200',
    ),
    Product(
      id: '6',
      title: 'Cargo Pants',
      price: '\$45',
      image: 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?q=80&w=1000',
      category: 'Streetwear',
      tag: 'Street',
      description: 'Baggy Y2K cargo pants with all pockets functional. Khaki colorway goes with any top. These are impossible to find.',
      sizes: ['S', 'M', 'L'],
      seller: 'Nour A.',
      sellerImage: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
    ),
    Product(
      id: '7',
      title: 'Silk Slip Dress',
      price: '\$55',
      image: 'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?q=80&w=1000',
      category: 'Luxury',
      tag: 'Luxury',
      description: 'Elegant 90s silk slip dress in champagne. Minimal wear, flows beautifully. Perfect for going out or dressing down with a tee underneath.',
      sizes: ['XS', 'S', 'M'],
      seller: 'Mayssa F.',
      sellerImage: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200',
    ),
    Product(
      id: '8',
      title: 'Bucket Hat',
      price: '\$20',
      image: 'https://images.unsplash.com/photo-1556306535-0f09a537f0a3?q=80&w=1000',
      category: 'Accessories',
      tag: 'Essential',
      description: 'Reversible canvas bucket hat, two looks in one. Faded navy and cream. Worn once, practically new.',
      sizes: ['One Size'],
      seller: 'Karim B.',
      sellerImage: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200',
    ),
    Product(
      id: '9',
      title: 'Corduroy Blazer',
      price: '\$60',
      image: 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?q=80&w=1000',
      category: 'Vintage',
      tag: 'Rare',
      description: 'Brown corduroy blazer with elbow patches. The ultimate academic aesthetic piece. Structured fit, great for layering.',
      sizes: ['M', 'L'],
      seller: 'Sara K.',
      sellerImage: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=200',
    ),
    Product(
      id: '10',
      title: 'Mini Shoulder Bag',
      price: '\$38',
      image: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?q=80&w=1000',
      category: 'Accessories',
      tag: 'Vintage',
      description: 'Tan leather mini shoulder bag with gold hardware. Fits phone, cards, and keys. Compact and incredibly stylish.',
      sizes: ['One Size'],
      seller: 'Lara M.',
      sellerImage: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200',
    ),
  ];

  // Filter helpers — screens call these instead of filtering manually
  static List<Product> byCategory(String category) {
    if (category == 'All') return all;
    return all.where((p) => p.category == category).toList();
  }

  static List<Product> search(String query) {
    if (query.isEmpty) return all;
    return all.where((p) =>
    p.title.toLowerCase().contains(query.toLowerCase()) ||
        p.category.toLowerCase().contains(query.toLowerCase()) ||
        p.tag.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}