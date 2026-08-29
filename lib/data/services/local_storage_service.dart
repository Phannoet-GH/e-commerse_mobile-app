import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/notification_item.dart';
import '../models/order.dart';
import '../models/user_address.dart';
import '../models/wishlist_board.dart';

class LocalStorageService {
  static const hasOpenedBeforeKey = 'hasOpenedBefore_v3';
  static const isSignedInKey = 'isSignedIn';
  static const userNameKey = 'userName';
  static const userEmailKey = 'userEmail';
  static const userPhoneKey = 'userPhone';
  static const cartItemsKey = 'cartItems_v2';
  static const favoritesKey = 'favorites_v2';
  static const wishlistsKey = 'wishlists_v2';
  static const ordersKey = 'orders_v2';
  static const addressesKey = 'addresses_v2';
  static const searchHistoryKey = 'searchHistory_v2';
  static const notificationsKey = 'notifications_v2';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  bool get hasOpenedBefore => _prefs?.getBool(hasOpenedBeforeKey) ?? false;
  bool get isSignedIn => _prefs?.getBool(isSignedInKey) ?? false;
  String get userName => _prefs?.getString(userNameKey) ?? (isSignedIn ? 'Emma Wills' : '');
  String get userEmail => _prefs?.getString(userEmailKey) ?? (isSignedIn ? 'emma.wills@email.com' : '');
  String get userPhone => _prefs?.getString(userPhoneKey) ?? (isSignedIn ? '+1 (555) 234-5678' : '');

  Future<void> setHasOpenedBefore(bool value) async {
    await _prefs?.setBool(hasOpenedBeforeKey, value);
  }

  Future<void> setSignedIn(bool value) async {
    await _prefs?.setBool(isSignedInKey, value);
  }

  Future<void> setUserProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    await _prefs?.setString(userNameKey, name);
    await _prefs?.setString(userEmailKey, email);
    if (phone != null) {
      await _prefs?.setString(userPhoneKey, phone);
    }
  }

  // --- Cart Persistence ---
  List<CartItem> getCartItems() {
    final raw = _prefs?.getString(cartItemsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCartItems(List<CartItem> items) async {
    final raw = jsonEncode(items.map((i) => i.toJson()).toList());
    await _prefs?.setString(cartItemsKey, raw);
  }

  // --- Favorites Persistence ---
  Set<int> getFavorites() {
    final list = _prefs?.getStringList(favoritesKey);
    if (list == null) return {};
    return list.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toSet();
  }

  Future<void> saveFavorites(Set<int> favorites) async {
    final list = favorites.map((e) => e.toString()).toList();
    await _prefs?.setStringList(favoritesKey, list);
  }

  // --- Wishlist Persistence ---
  List<WishlistBoard> getWishlists() {
    final raw = _prefs?.getString(wishlistsKey);
    if (raw == null || raw.isEmpty) return _defaultWishlists();
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => WishlistBoard.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaultWishlists();
    }
  }

  Future<void> saveWishlists(List<WishlistBoard> wishlists) async {
    final raw = jsonEncode(wishlists.map((w) => w.toJson()).toList());
    await _prefs?.setString(wishlistsKey, raw);
  }

  List<WishlistBoard> _defaultWishlists() {
    return [
      WishlistBoard(
        id: 'wish_default',
        name: 'My Wishlist',
        description: 'Items saved to buy soon',
        icon: '✨',
        productIds: [],
        createdAt: DateTime.now(),
        isDefault: true,
      ),
    ];
  }

  // --- Orders Persistence ---
  List<Order> getOrders() {
    final raw = _prefs?.getString(ordersKey);
    if (raw == null || raw.isEmpty) return _defaultSampleOrders();
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaultSampleOrders();
    }
  }

  Future<void> saveOrders(List<Order> orders) async {
    final raw = jsonEncode(orders.map((o) => o.toJson()).toList());
    await _prefs?.setString(ordersKey, raw);
  }

  List<Order> _defaultSampleOrders() {
    return [];
  }

  // --- Address Book Persistence ---
  List<UserAddress> getAddresses() {
    final raw = _prefs?.getString(addressesKey);
    if (raw == null || raw.isEmpty) return _defaultAddresses();
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => UserAddress.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaultAddresses();
    }
  }

  Future<void> saveAddresses(List<UserAddress> addresses) async {
    final raw = jsonEncode(addresses.map((a) => a.toJson()).toList());
    await _prefs?.setString(addressesKey, raw);
  }

  List<UserAddress> _defaultAddresses() {
    final name = isSignedIn && userName.isNotEmpty ? userName : 'Guest Shopper';
    return [
      UserAddress(
        id: 'addr_1',
        recipientName: name,
        street: '14 Market Street, Apt 4B',
        city: 'New York',
        state: 'NY',
        zipCode: '10001',
        country: 'United States',
        phone: isSignedIn && userPhone.isNotEmpty ? userPhone : '+1 (555) 234-5678',
        isDefault: true,
      ),
      UserAddress(
        id: 'addr_2',
        recipientName: '$name (Work)',
        street: '450 Lexington Ave, Suite 1200',
        city: 'New York',
        state: 'NY',
        zipCode: '10017',
        country: 'United States',
        phone: '+1 (555) 987-6543',
        isDefault: false,
      ),
    ];
  }

  // --- Search History Persistence ---
  List<String> getSearchHistory() {
    return _prefs?.getStringList(searchHistoryKey) ??
        ['Hoodie', 'Sneakers', 'Watch', 'Headphones', 'Linen'];
  }

  Future<void> saveSearchHistory(List<String> queries) async {
    await _prefs?.setStringList(searchHistoryKey, queries);
  }

  // --- Notifications Persistence ---
  List<NotificationItem> getNotifications() {
    final raw = _prefs?.getString(notificationsKey);
    if (raw == null || raw.isEmpty) return _defaultNotifications();
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaultNotifications();
    }
  }

  Future<void> saveNotifications(List<NotificationItem> items) async {
    final raw = jsonEncode(items.map((n) => n.toJson()).toList());
    await _prefs?.setString(notificationsKey, raw);
  }

  List<NotificationItem> _defaultNotifications() {
    return [
      const NotificationItem(
        id: 'notif_1',
        title: 'Flash Sale Alert! ⚡',
        message: 'Get up to 40% off summer apparel & footwear today only with code LUXE20.',
        time: '2 hours ago',
        type: 'promo',
      ),
      const NotificationItem(
        id: 'notif_2',
        title: 'Welcome to LuxeCart',
        message: 'Your account has been set up. Enjoy free shipping on all orders over \$100.',
        time: '1 day ago',
        type: 'account',
      ),
    ];
  }
}
