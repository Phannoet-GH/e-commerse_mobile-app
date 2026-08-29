import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final Color accentColor;
  final String? badge;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.accentColor = const Color(0xFFFF2D6F),
    this.badge,
  });

  static const List<CategoryItem> defaultCategories = [
    CategoryItem(
      id: 'all',
      name: 'All',
      icon: Icons.grid_view_rounded,
      description: 'Explore our complete curated luxury collection',
      accentColor: Color(0xFFFF2D6F),
    ),
    CategoryItem(
      id: 'apparel',
      name: 'Apparel',
      icon: Icons.checkroom_rounded,
      description: 'Premium hoodies, linen shirts, tees & tailored pants',
      accentColor: Color(0xFF6C63FF),
      badge: 'POPULAR',
    ),
    CategoryItem(
      id: 'accessories',
      name: 'Accessories',
      icon: Icons.watch_rounded,
      description: 'Sapphire watches, aviator sunglasses, belts & beanies',
      accentColor: Color(0xFFFFA800),
      badge: 'TRENDING',
    ),
    CategoryItem(
      id: 'footwear',
      name: 'Footwear',
      icon: Icons.directions_run_rounded,
      description: 'High-performance runners, low-top sneakers & slides',
      accentColor: Color(0xFF10B981),
      badge: 'NEW',
    ),
    CategoryItem(
      id: 'electronics',
      name: 'Electronics',
      icon: Icons.headphones_rounded,
      description: 'Wireless ANC headphones, Bluetooth speakers & chargers',
      accentColor: Color(0xFF2563EB),
      badge: 'HOT',
    ),
    CategoryItem(
      id: 'bags',
      name: 'Bags',
      icon: Icons.shopping_bag_outlined,
      description: 'Waxed canvas totes, commuter backpacks & slings',
      accentColor: Color(0xFF8B5CF6),
    ),
    CategoryItem(
      id: 'jewelry',
      name: 'Jewelry',
      icon: Icons.diamond_outlined,
      description: '14k solid gold signet rings, silver chains & pendants',
      accentColor: Color(0xFFEC4899),
      badge: 'LUXE',
    ),
  ];

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? 'All';
    final existing = defaultCategories.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase() || c.id.toLowerCase() == (json['id']?.toString().toLowerCase() ?? ''),
      orElse: () => CategoryItem(
        id: json['id']?.toString() ?? name.toLowerCase(),
        name: name,
        icon: Icons.category_outlined,
        description: json['description']?.toString() ?? 'Explore $name products',
      ),
    );

    return CategoryItem(
      id: json['id']?.toString() ?? existing.id,
      name: name,
      icon: existing.icon,
      description: json['description']?.toString() ?? existing.description,
      accentColor: existing.accentColor,
      badge: json['badge']?.toString() ?? existing.badge,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'badge': badge,
    };
  }

  static CategoryItem getByName(String name) {
    return defaultCategories.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => CategoryItem(
        id: name.toLowerCase(),
        name: name,
        icon: Icons.category_outlined,
        description: 'Explore $name products',
      ),
    );
  }
}

