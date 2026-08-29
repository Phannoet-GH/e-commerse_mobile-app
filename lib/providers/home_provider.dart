import 'package:flutter/material.dart';

import '../data/models/cart_item.dart';
import '../data/models/notification_item.dart';
import '../data/models/order.dart';
import '../data/models/product.dart';
import '../data/models/user_address.dart';
import '../data/models/wishlist_board.dart';
import '../data/services/local_storage_service.dart';
import '../data/services/product_service.dart';

class HomeProvider extends ChangeNotifier {
  HomeProvider({LocalStorageService? storage, ProductService? productService})
      : _storage = storage ?? LocalStorageService(),
        _productService = productService ?? ProductService() {
    _initStorage();
  }

  final LocalStorageService _storage;
  final ProductService _productService;

  int _selectedIndex = 0;
  Product? _selectedProduct;
  List<Product> _products = [];
  bool _isLoadingProducts = false;
  String? _productsError;

  List<CartItem> _cart = [];
  Set<int> _favorites = {};
  List<WishlistBoard> _wishlists = [];
  List<Order> _orders = [];
  List<UserAddress> _addresses = [];
  List<NotificationItem> _notifications = [];
  List<String> _searchHistory = [];

  String? _appliedPromoCode;
  double _promoDiscountPercent = 0.0;
  double _promoDiscountFlat = 0.0;

  int get selectedIndex => _selectedIndex;
  Product? get selectedProduct => _selectedProduct;
  List<Product> get products => _products;
  bool get isLoadingProducts => _isLoadingProducts;
  String? get productsError => _productsError;

  List<CartItem> get cart => _cart;
  Set<int> get favorites => _favorites;
  List<WishlistBoard> get wishlists => _wishlists;
  int get totalWishlistItemsCount =>
      _wishlists.fold(0, (sum, w) => sum + w.productIds.length);
  List<Order> get orders => _orders;
  List<UserAddress> get addresses => _addresses;
  List<NotificationItem> get notifications => _notifications;
  List<String> get searchHistory => _searchHistory;
  String? get appliedPromoCode => _appliedPromoCode;

  UserAddress? get defaultAddress {
    if (_addresses.isEmpty) return null;
    return _addresses.firstWhere((a) => a.isDefault, orElse: () => _addresses.first);
  }

  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  Future<void> _initStorage() async {
    await _storage.init();
    _cart = List<CartItem>.from(_storage.getCartItems());
    _favorites = Set<int>.from(_storage.getFavorites());
    _wishlists = List<WishlistBoard>.from(_storage.getWishlists());
    _orders = List<Order>.from(_storage.getOrders());
    _addresses = List<UserAddress>.from(_storage.getAddresses());
    _notifications = List<NotificationItem>.from(_storage.getNotifications());
    _searchHistory = List<String>.from(_storage.getSearchHistory());
    notifyListeners();
  }

  // --- Navigation & Product Selection ---
  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void selectProduct(Product product) {
    _selectedProduct = product;
    notifyListeners();
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  // --- Favorites (Quick ❤️ Likes) ---
  bool isFavorite(int productId) => _favorites.contains(productId);

  void toggleFavorite(int productId) {
    if (_favorites.contains(productId)) {
      _favorites.remove(productId);
    } else {
      _favorites.add(productId);
    }
    _storage.saveFavorites(_favorites);
    notifyListeners();
  }

  // --- Wishlists (Curated 📋 Boards & Collections) ---
  WishlistBoard createWishlist(
    String name, {
    String description = '',
    String icon = '📋',
    List<int>? initialProductIds,
  }) {
    final board = WishlistBoard(
      id: 'wish_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      description: description.trim(),
      icon: icon,
      productIds: initialProductIds ?? [],
      createdAt: DateTime.now(),
      isDefault: false,
    );
    _wishlists.add(board);
    _storage.saveWishlists(_wishlists);
    notifyListeners();
    return board;
  }

  void addToWishlist(String wishlistId, int productId) {
    final index = _wishlists.indexWhere((w) => w.id == wishlistId);
    if (index != -1) {
      final board = _wishlists[index];
      if (!board.productIds.contains(productId)) {
        final updatedIds = List<int>.from(board.productIds)..add(productId);
        _wishlists[index] = board.copyWith(productIds: updatedIds);
        _storage.saveWishlists(_wishlists);
        notifyListeners();
      }
    }
  }

  void removeFromWishlist(String wishlistId, int productId) {
    final index = _wishlists.indexWhere((w) => w.id == wishlistId);
    if (index != -1) {
      final board = _wishlists[index];
      final updatedIds = List<int>.from(board.productIds)..remove(productId);
      _wishlists[index] = board.copyWith(productIds: updatedIds);
      _storage.saveWishlists(_wishlists);
      notifyListeners();
    }
  }

  void deleteWishlist(String wishlistId) {
    _wishlists.removeWhere((w) => w.id == wishlistId && !w.isDefault);
    _storage.saveWishlists(_wishlists);
    notifyListeners();
  }

  void addWishlistToCart(WishlistBoard board) {
    final matchingProducts = _products.where((p) => board.productIds.contains(p.id)).toList();
    for (final product in matchingProducts) {
      addToCart(product);
    }
  }

  // --- Cart Calculations ---
  double get subtotal => _cart.fold<double>(
        0,
        (sum, item) => sum + (item.product.price * item.quantity),
      );

  double get discountAmount {
    if (_cart.isEmpty) return 0.0;
    if (_promoDiscountPercent > 0) {
      return (subtotal * _promoDiscountPercent);
    }
    if (_promoDiscountFlat > 0) {
      return _promoDiscountFlat.clamp(0, subtotal);
    }
    return 0.0;
  }

  double get shippingFee {
    if (_cart.isEmpty) return 0.0;
    if (_appliedPromoCode == 'FREESHIP' || subtotal >= 100) return 0.0;
    return 12.00;
  }

  double get totalAmount {
    if (_cart.isEmpty) return 0.0;
    final total = subtotal - discountAmount + shippingFee;
    return total < 0 ? 0.0 : total;
  }

  // --- Cart Operations ---
  void addToCart(
    Product product, {
    String size = 'M',
    String color = 'Default',
    int qty = 1,
  }) {
    final existingIndex = _cart.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.size == size &&
          item.color == color,
    );

    if (existingIndex != -1) {
      final existing = _cart[existingIndex];
      _cart[existingIndex] = existing.copyWith(qty: existing.qty + qty);
    } else {
      _cart.add(
        CartItem(
          product: product,
          qty: qty,
          size: size,
          color: color,
        ),
      );
    }
    _storage.saveCartItems(_cart);
    notifyListeners();
  }

  void addMultipleToCart(List<Product> products) {
    for (final product in products) {
      addToCart(product);
    }
  }

  void incrementQuantity(int index) {
    if (index >= 0 && index < _cart.length) {
      final item = _cart[index];
      _cart[index] = item.copyWith(qty: item.qty + 1);
      _storage.saveCartItems(_cart);
      notifyListeners();
    }
  }

  void decrementQuantity(int index) {
    if (index >= 0 && index < _cart.length) {
      final item = _cart[index];
      if (item.qty > 1) {
        _cart[index] = item.copyWith(qty: item.qty - 1);
      } else {
        _cart.removeAt(index);
      }
      _storage.saveCartItems(_cart);
      notifyListeners();
    }
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cart.length) {
      _cart.removeAt(index);
      _storage.saveCartItems(_cart);
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    _appliedPromoCode = null;
    _promoDiscountPercent = 0.0;
    _promoDiscountFlat = 0.0;
    _storage.saveCartItems(_cart);
    notifyListeners();
  }

  // --- Promo Codes ---
  String? applyPromoCode(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return 'Please enter a voucher code.';

    if (code == 'LUXE20') {
      _appliedPromoCode = 'LUXE20';
      _promoDiscountPercent = 0.20;
      _promoDiscountFlat = 0.0;
      notifyListeners();
      return null; // Success
    } else if (code == 'SAVE10') {
      _appliedPromoCode = 'SAVE10';
      _promoDiscountPercent = 0.0;
      _promoDiscountFlat = 10.0;
      notifyListeners();
      return null;
    } else if (code == 'FREESHIP') {
      _appliedPromoCode = 'FREESHIP';
      _promoDiscountPercent = 0.0;
      _promoDiscountFlat = 0.0;
      notifyListeners();
      return null;
    } else {
      return 'Invalid coupon code. Try LUXE20 or SAVE10.';
    }
  }

  void removePromoCode() {
    _appliedPromoCode = null;
    _promoDiscountPercent = 0.0;
    _promoDiscountFlat = 0.0;
    notifyListeners();
  }

  // --- Orders & Checkout ---
  Order placeOrder({
    String? shippingAddress,
    String? paymentMethod,
  }) {
    final finalAddress = shippingAddress ??
        defaultAddress?.fullAddress ??
        '14 Market Street, New York, NY 10001';
    final finalPayment = paymentMethod ?? 'Visa •••• 4589';

    final order = Order(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: '#LX-${(100000 + _orders.length + 1)}',
      items: List<CartItem>.from(_cart),
      subtotal: subtotal,
      shippingFee: shippingFee,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      promoCode: _appliedPromoCode,
      shippingAddress: finalAddress,
      paymentMethod: finalPayment,
      status: 'Processing',
      createdAt: DateTime.now(),
    );

    _orders = List<Order>.from(_orders);
    _orders.insert(0, order);
    _storage.saveOrders(_orders);

    // Create confirmation notification
    final notif = NotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Order Confirmed! 📦',
      message: 'Order ${order.orderNumber} placed for \$${order.totalAmount.toStringAsFixed(2)}. Tracking: ${order.trackingNumber}',
      time: 'Just now',
      type: 'order',
    );
    _notifications = List<NotificationItem>.from(_notifications);
    _notifications.insert(0, notif);
    _storage.saveNotifications(_notifications);

    clearCart();
    _selectedIndex = 0;
    notifyListeners();
    return order;
  }

  void reorder(Order order) {
    for (final item in order.items) {
      _cart.add(item.copyWith());
    }
    _storage.saveCartItems(_cart);
    _selectedIndex = 2; // Navigate to cart
    notifyListeners();
  }

  // --- Address Book ---
  void addAddress(UserAddress address) {
    if (address.isDefault) {
      _addresses = _addresses.map((a) => a.copyWith(isDefault: false)).toList();
    }
    _addresses.add(address);
    _storage.saveAddresses(_addresses);
    notifyListeners();
  }

  void updateAddress(UserAddress updated) {
    final index = _addresses.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      if (updated.isDefault) {
        _addresses = _addresses.map((a) => a.copyWith(isDefault: false)).toList();
      }
      _addresses[index] = updated;
      _storage.saveAddresses(_addresses);
      notifyListeners();
    }
  }

  void deleteAddress(String id) {
    _addresses.removeWhere((a) => a.id == id);
    if (_addresses.isNotEmpty && !_addresses.any((a) => a.isDefault)) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }
    _storage.saveAddresses(_addresses);
    notifyListeners();
  }

  void setDefaultAddress(String id) {
    _addresses = _addresses.map((a) => a.copyWith(isDefault: a.id == id)).toList();
    _storage.saveAddresses(_addresses);
    notifyListeners();
  }

  // --- Search History ---
  void addSearchQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _searchHistory.remove(trimmed);
    _searchHistory.insert(0, trimmed);
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }
    _storage.saveSearchHistory(_searchHistory);
    notifyListeners();
  }

  void removeSearchQuery(String query) {
    _searchHistory.remove(query);
    _storage.saveSearchHistory(_searchHistory);
    notifyListeners();
  }

  void clearSearchHistory() {
    _searchHistory.clear();
    _storage.saveSearchHistory(_searchHistory);
    notifyListeners();
  }

  // --- Notifications ---
  void markNotificationRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _storage.saveNotifications(_notifications);
      notifyListeners();
    }
  }

  void clearAllNotifications() {
    _notifications.clear();
    _storage.saveNotifications(_notifications);
    notifyListeners();
  }

  // --- Product Fetching ---
  Future<void> loadProducts() async {
    if (_isLoadingProducts) return;

    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      _products = await _productService.fetchProducts();
    } catch (e) {
      _productsError = e.toString();
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }
}