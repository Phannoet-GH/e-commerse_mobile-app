class Review {
  final String userName;
  final double rating;
  final String comment;
  final String date;
  final String? avatarUrl;

  const Review({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
    this.avatarUrl,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      userName: json['userName']?.toString() ?? 'Anonymous',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comment: json['comment']?.toString() ?? '',
      date: json['date']?.toString() ?? 'Recently',
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'date': date,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}

class Product {
  final int id;
  final String name;
  final String brand;
  final double price;
  final double? originalPrice;
  final String category;
  final String image;
  final List<String> images;
  final List<String> colors;
  final double rating;
  final int reviews;
  final String description;
  final List<String> sizes;
  final String? badge;
  final Map<String, String> specs;
  final List<Review> customerReviews;
  final bool inStock;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    this.originalPrice,
    required this.category,
    required this.image,
    List<String>? images,
    List<String>? colors,
    required this.rating,
    required this.reviews,
    required this.description,
    required this.sizes,
    this.badge,
    Map<String, String>? specs,
    List<Review>? customerReviews,
    this.inStock = true,
  })  : images = (images != null && images.isNotEmpty) ? images : [image],
        colors = colors ?? const ['#1A1A1A', '#FF2D6F', '#6C63FF'],
        specs = specs ?? const {},
        customerReviews = customerReviews ?? const [];

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List<dynamic>?;
    final imageList = rawImages?.map((e) => e.toString()).toList();
    final primaryImage = json['image']?.toString() ??
        (imageList != null && imageList.isNotEmpty ? imageList.first : '');

    final rawColors = json['colors'] as List<dynamic>?;
    final colorList = rawColors?.map((e) => e.toString()).toList();

    final rawReviews = json['customerReviews'] as List<dynamic>?;
    final reviewsList = rawReviews
        ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawSpecs = json['specs'] as Map<String, dynamic>?;
    final specsMap = rawSpecs?.map((k, v) => MapEntry(k, v.toString()));

    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Product',
      brand: json['brand']?.toString() ?? 'LuxeCart',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      category: json['category']?.toString() ?? 'General',
      image: primaryImage,
      images: imageList ?? (primaryImage.isNotEmpty ? [primaryImage] : const []),
      colors: colorList ?? const ['#1A1A1A', '#FF2D6F', '#6C63FF'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? '',
      sizes: (json['sizes'] as List<dynamic>?)
              ?.map((size) => size.toString())
              .toList() ??
          const ['S', 'M', 'L', 'XL'],
      badge: json['badge']?.toString(),
      specs: specsMap,
      customerReviews: reviewsList,
      inStock: json['inStock'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'originalPrice': originalPrice,
      'category': category,
      'image': image,
      'images': images,
      'colors': colors,
      'rating': rating,
      'reviews': reviews,
      'description': description,
      'sizes': sizes,
      'badge': badge,
      'specs': specs,
      'customerReviews': customerReviews.map((r) => r.toJson()).toList(),
      'inStock': inStock,
    };
  }

  String get imageUrl => image;
  double get originalPriceValue => originalPrice ?? price;
  int get reviewsCount => reviews;
  bool get isFlashSale => badge != null && badge!.toUpperCase().contains('SALE');
}
