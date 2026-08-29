class WishlistBoard {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<int> productIds;
  final DateTime createdAt;
  final bool isDefault;

  const WishlistBoard({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = '📋',
    required this.productIds,
    required this.createdAt,
    this.isDefault = false,
  });

  WishlistBoard copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    List<int>? productIds,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return WishlistBoard(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      productIds: productIds ?? this.productIds,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'productIds': productIds,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  factory WishlistBoard.fromJson(Map<String, dynamic> json) {
    return WishlistBoard(
      id: json['id'] as String? ?? 'w_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'My Wishlist',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '📋',
      productIds: (json['productIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

