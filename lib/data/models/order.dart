import 'cart_item.dart';

class OrderTimelineStep {
  final String title;
  final String description;
  final String time;
  final bool isCompleted;

  const OrderTimelineStep({
    required this.title,
    required this.description,
    required this.time,
    required this.isCompleted,
  });

  factory OrderTimelineStep.fromJson(Map<String, dynamic> json) {
    return OrderTimelineStep(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'time': time,
      'isCompleted': isCompleted,
    };
  }
}

class Order {
  final String id;
  final String orderNumber;
  final List<CartItem> items;
  final double subtotal;
  final double shippingFee;
  final double discountAmount;
  final double totalAmount;
  final String? promoCode;
  final String shippingAddress;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final DateTime estimatedDelivery;
  final String trackingNumber;
  final List<OrderTimelineStep> timeline;

  Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.discountAmount,
    required this.totalAmount,
    this.promoCode,
    required this.shippingAddress,
    required this.paymentMethod,
    this.status = 'Processing',
    DateTime? createdAt,
    DateTime? estimatedDelivery,
    String? trackingNumber,
    List<OrderTimelineStep>? timeline,
  })  : createdAt = createdAt ?? DateTime.now(),
        estimatedDelivery = estimatedDelivery ??
            DateTime.now().add(const Duration(days: 4)),
        trackingNumber = trackingNumber ??
            'LX-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        timeline = timeline ??
            const [
              OrderTimelineStep(
                title: 'Order Placed',
                description: 'Your order has been received and verified.',
                time: 'Today',
                isCompleted: true,
              ),
              OrderTimelineStep(
                title: 'Processing',
                description: 'Seller is preparing your items for shipment.',
                time: 'In Progress',
                isCompleted: true,
              ),
              OrderTimelineStep(
                title: 'Shipped',
                description: 'Package handed over to courier partner.',
                time: 'Pending',
                isCompleted: false,
              ),
              OrderTimelineStep(
                title: 'Delivered',
                description: 'Package delivered to your shipping address.',
                time: 'Pending',
                isCompleted: false,
              ),
            ];

  int get totalItemCount =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawTimeline = json['timeline'] as List<dynamic>? ?? [];
    final timelineList = rawTimeline
        .map((e) => OrderTimelineStep.fromJson(e as Map<String, dynamic>))
        .toList();

    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      items: itemsList,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      promoCode: json['promoCode']?.toString(),
      shippingAddress: json['shippingAddress']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? 'Credit Card',
      status: json['status']?.toString() ?? 'Processing',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.tryParse(json['estimatedDelivery'].toString()) ??
              DateTime.now().add(const Duration(days: 4))
          : DateTime.now().add(const Duration(days: 4)),
      trackingNumber: json['trackingNumber']?.toString() ?? '',
      timeline: timelineList.isNotEmpty ? timelineList : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'promoCode': promoCode,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'estimatedDelivery': estimatedDelivery.toIso8601String(),
      'trackingNumber': trackingNumber,
      'timeline': timeline.map((t) => t.toJson()).toList(),
    };
  }
}

