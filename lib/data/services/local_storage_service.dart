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

  static const cartItemsBaseKey = 'cartItems_v3';
  static const favoritesBaseKey = 'favorites_v3';
  static const wishlistsBaseKey = 'wishlists_v3';
  static const ordersBaseKey = 'orders_v3';
  static const addressesBaseKey = 'addresses_v3';
  static const searchHistoryBaseKey = 'searchHistory_v3';
  static const notificationsBaseKey = 'notifications_v3';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String _scopedKey(String baseKey, String? userId) {
    final scope = (userId != null && userId.trim().isNotEmpty)
        ? userId.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        : 'guest';
    return '${baseKey}_$scope';
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

  // --- Cart Persistence (Per-User Scoped) ---
  List<CartItem> getCartItems({String? userId}) {
    final key = _scopedKey(cartItemsBaseKey, userId);
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCartItems(List<CartItem> items, {String? userId}) async {
    final key = _scopedKey(cartItemsBaseKey, userId);
    final raw = jsonEncode(items.map((i) => i.toJson()).toList());
    await _prefs?.setString(key, raw);
  }

  // --- Favorites Persistence (Per-User Scoped) ---
  Set<int> getFavorites({String? userId}) {
    final key = _scopedKey(favoritesBaseKey, userId);
    final list = _prefs?.getStringList(key);
    if (list == null) return {};
    return list.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toSet();
  }

  Future<void> saveFavorites(Set<int> favorites, {String? userId}) async {
    final key = _scopedKey(favoritesBaseKey, userId);
    final list = favorites.map((e) => e.toString()).toList();
    await _prefs?.setStringList(key, list);
  }

  // --- Wishlist Persistence (Per-User Scoped) ---
  List<WishlistBoard> getWishlists({String? userId}) {
    final key = _scopedKey(wishlistsBaseKey, userId);
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return _defaultWishlists();
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => WishlistBoard.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaultWishlists();
    }
  }

  Future<void> saveWishlists(List<WishlistBoard> wishlists, {String? userId}) async {
    final key = _scopedKey(wishlistsBaseKey, userId);
    final raw = jsonEncode(wishlists.map((w) => w.toJson()).toList());
    await _prefs?.setString(key, raw);
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

  // --- Orders Persistence (Per-User Scoped) ---
  List<Order> getOrders({String? userId}) {
    final key = _scopedKey(ordersBaseKey, userId);
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveOrders(List<Order> orders, {String? userId}) async {
    final key = _scopedKey(ordersBaseKey, userId);
    final raw = jsonEncode(orders.map((o) => o.toJson()).toList());
    await _prefs?.setString(key, raw);
  }

  // --- Address Book Persistence (Per-User Scoped) ---
  List<UserAddress> getAddresses({String? userId}) {
    final key = _scopedKey(addressesBaseKey, userId);
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return _defaultAddresses(userId: userId);
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => UserAddress.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaultAddresses(userId: userId);
    }
  }

  Future<void> saveAddresses(List<UserAddress> addresses, {String? userId}) async {
    final key = _scopedKey(addressesBaseKey, userId);
    final raw = jsonEncode(addresses.map((a) => a.toJson()).toList());
    await _prefs?.setString(key, raw);
  }

  List<UserAddress> _defaultAddresses({String? userId}) {
    // Only return default address if it's an authenticated user session
    if (userId == null || userId.trim().isEmpty || userId == 'guest') {
      return [];
    }
    return [
      const UserAddress(
        id: 'addr_default_1',
        recipientName: 'Emma Wills',
        phone: '+1 (555) 234-5678',
        street: '742 Evergreen Terrace, Apt 4B',
        city: 'Springfield',
        state: 'OR',
        zipCode: '97477',
        country: 'United States',
        isDefault: true,
      ),
    ];
  }

  // --- Search History (Per-User Scoped) ---
  List<String> getSearchHistory({String? userId}) {
    final key = _scopedKey(searchHistoryBaseKey, userId);
    return _prefs?.getStringList(key) ?? [];
  }

  Future<void> saveSearchHistory(List<String> history, {String? userId}) async {
    final key = _scopedKey(searchHistoryBaseKey, userId);
    await _prefs?.setStringList(key, history);
  }

  // --- Notifications Persistence (Per-User Scoped) ---
  List<NotificationItem> getNotifications({String? userId}) {
    final key = _scopedKey(notificationsBaseKey, userId);
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return _defaultNotifications(userId: userId);
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _defaultNotifications(userId: userId);
    }
  }

  Future<void> saveNotifications(List<NotificationItem> notifications, {String? userId}) async {
    final key = _scopedKey(notificationsBaseKey, userId);
    final raw = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await _prefs?.setString(key, raw);
  }

  List<NotificationItem> _defaultNotifications({String? userId}) {
    if (userId == null || userId.trim().isEmpty || userId == 'guest') {
      return [];
    }
    return [
      NotificationItem(
        id: 'notif_welcome',
        title: 'Welcome to LuxeCart VIP Club!',
        message: 'Your account is active. Use promo code LUXE20 to get 20% off your first purchase.',
        time: '1 hour ago',
        type: 'promo',
        isRead: false,
      ),
    ];
  }
}
