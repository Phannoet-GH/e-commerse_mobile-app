import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final int qty;
  final String size;
  final String color;

  CartItem({
    String? id,
    required this.product,
    required this.qty,
    required this.size,
    this.color = 'Default',
  }) : id = id ?? '${product.id}_${size}_$color';

  int get quantity => qty;
  String get selectedSize => size;
  String get selectedColor => color;

  double get totalPrice => product.price * qty;

  CartItem copyWith({
    String? id,
    Product? product,
    int? qty,
    String? size,
    String? color,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      qty: qty ?? this.qty,
      size: size ?? this.size,
      color: color ?? this.color,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString(),
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      size: json['size']?.toString() ?? 'M',
      color: json['color']?.toString() ?? 'Default',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'qty': qty,
      'size': size,
      'color': color,
    };
  }
}
