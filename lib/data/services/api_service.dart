import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../mock/mock_products.dart';
import '../models/category_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user_address.dart';
import '../models/wishlist_board.dart';

class ApiService {
  /// Automatic base URL detection for Android Emulator (10.0.2.2) vs Desktop/iOS/Web (localhost)
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    } catch (_) {}
    return 'http://localhost:8000/api';
  }

  static const Duration defaultTimeout = Duration(seconds: 10);

  final String baseUrl;
  final http.Client _client;

  String? _lastError;
  bool _isBackendConnected = false;

  String? get lastError => _lastError;
  bool get isBackendConnected => _isBackendConnected;

  ApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? defaultBaseUrl,
        _client = client ?? http.Client();

  /// GET /api/products
  Future<List<Product>> getProducts({String? category, String? search}) async {
    try {
      final uri = Uri.parse('$baseUrl/products').replace(
        queryParameters: {
          'limit': '100',
          if (category != null && category.isNotEmpty && category.toLowerCase() != 'all')
            'category': category,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final response = await _client.get(uri).timeout(defaultTimeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is List) {
          final list = (decoded['data'] as List)
              .map((item) => Product.fromJson(item as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty) {
            _lastError = null;
            _isBackendConnected = true;
            return list;
          }
        }
      }
      _lastError = 'Backend returned status ${response.statusCode}';
      _isBackendConnected = false;
    } catch (e) {
      _lastError = 'Cannot connect to backend server at $baseUrl';
      _isBackendConnected = false;
    }

    // Fallback to local mock catalog
    var fallback = MockData.products;
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      fallback = fallback.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
    }
    if (search != null && search.isNotEmpty) {
      fallback = fallback
          .where((p) =>
              p.name.toLowerCase().contains(search.toLowerCase()) ||
              p.brand.toLowerCase().contains(search.toLowerCase()) ||
              p.category.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    return fallback;
  }

  /// GET /api/products/$id
  Future<Product?> getProductById(int id) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/products/$id')).timeout(defaultTimeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return Product.fromJson(decoded['data'] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/categories
  Future<List<CategoryItem>> getCategories() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/categories')).timeout(defaultTimeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is List) {
          final list = (decoded['data'] as List)
              .map((item) => CategoryItem.fromJson(item as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty) {
            _lastError = null;
            _isBackendConnected = true;
            return list;
          }
        }
      }
      _lastError = 'Cannot connect to backend server at $baseUrl';
      _isBackendConnected = false;
    } catch (_) {
      _lastError = 'Cannot connect to backend server at $baseUrl';
      _isBackendConnected = false;
    }

    return CategoryItem.defaultCategories;
  }

  /// POST /api/auth/login
  Future<Map<String, dynamic>?> login({required String email, required String password}) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return decoded['data'] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/auth/register
  Future<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'phone': phone,
            }),
          )
          .timeout(defaultTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return decoded['data'] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/orders
  Future<Map<String, dynamic>?> placeOrder(Map<String, dynamic> orderPayload) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/orders'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(orderPayload),
          )
          .timeout(defaultTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return decoded['data'] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/orders/track?tracking_number=...
  Future<Map<String, dynamic>?> trackOrder(String trackingNumber) async {
    try {
      final uri = Uri.parse('$baseUrl/orders/track').replace(
        queryParameters: {'tracking_number': trackingNumber},
      );
      final response = await _client.get(uri).timeout(defaultTimeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return decoded['data'] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/coupons/validate
  Future<Map<String, dynamic>?> validateCoupon(String code, double subtotal) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/coupons/validate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code, 'subtotal': subtotal}),
          )
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return decoded['data'] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/reviews
  Future<bool> submitReview({
    required int productId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/reviews'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'product_id': productId,
              'user_name': userName,
              'rating': rating,
              'comment': comment,
            }),
          )
          .timeout(defaultTimeout);

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/auth/forgot-password
  Future<Map<String, dynamic>?> requestPasswordReset(String email) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return decoded['data'] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/auth/verify-otp
  Future<bool> verifyOtp({required String email, required String otp}) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(defaultTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/auth/reset-password
  Future<bool> resetPassword({
    required String email,
    required String newPassword,
    String? otp,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'new_password': newPassword,
              'otp': ?otp,
            }),
          )
          .timeout(defaultTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/auth/profile
  Future<Map<String, dynamic>?> updateUserProfile({
    required String email,
    required String name,
    String? phone,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/profile'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'name': name,
              'phone': ?phone,
            }),
          )
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return decoded['data'] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/orders
  Future<List<Order>> getOrders({String? userId}) async {
    try {
      final uri = Uri.parse('$baseUrl/orders').replace(
        queryParameters: {if (userId != null && userId.isNotEmpty) 'user_id': userId},
      );
      final response = await _client.get(uri).timeout(defaultTimeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((item) => Order.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/addresses
  Future<List<UserAddress>> getAddresses({String? userId}) async {
    try {
      final uri = Uri.parse('$baseUrl/addresses').replace(
        queryParameters: {if (userId != null && userId.isNotEmpty) 'user_id': userId},
      );
      final response = await _client.get(uri).timeout(defaultTimeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((item) => UserAddress.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// POST /api/addresses
  Future<UserAddress?> addAddress(Map<String, dynamic> addressPayload) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/addresses'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(addressPayload),
          )
          .timeout(defaultTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return UserAddress.fromJson(decoded['data'] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }

  /// DELETE /api/addresses
  Future<bool> deleteAddress(String addressId, {String? userId}) async {
    try {
      final uri = Uri.parse('$baseUrl/addresses').replace(
        queryParameters: {
          'id': addressId,
          if (userId != null && userId.isNotEmpty) 'user_id': userId,
        },
      );
      final response = await _client.delete(uri).timeout(defaultTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/addresses/default
  Future<bool> setDefaultAddress(String addressId, {required String userId}) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/addresses/default'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': addressId, 'user_id': userId}),
          )
          .timeout(defaultTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// GET /api/wishlists
  Future<List<WishlistBoard>> getWishlists({String? userId}) async {
    try {
      final uri = Uri.parse('$baseUrl/wishlists').replace(
        queryParameters: {if (userId != null && userId.isNotEmpty) 'user_id': userId},
      );
      final response = await _client.get(uri).timeout(defaultTimeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((item) => WishlistBoard.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// POST /api/wishlists
  Future<WishlistBoard?> createWishlist(Map<String, dynamic> wishlistPayload) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/wishlists'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(wishlistPayload),
          )
          .timeout(defaultTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return WishlistBoard.fromJson(decoded['data'] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }

  /// DELETE /api/wishlists
  Future<bool> deleteWishlist(String wishlistId, {String? userId}) async {
    try {
      final uri = Uri.parse('$baseUrl/wishlists').replace(
        queryParameters: {
          'id': wishlistId,
          if (userId != null && userId.isNotEmpty) 'user_id': userId,
        },
      );
      final response = await _client.delete(uri).timeout(defaultTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/wishlists/items
  Future<bool> addWishlistItem(String wishlistId, int productId) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/wishlists/items'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'wishlist_id': wishlistId, 'product_id': productId}),
          )
          .timeout(defaultTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// DELETE /api/wishlists/items
  Future<bool> removeWishlistItem(String wishlistId, int productId) async {
    try {
      final uri = Uri.parse('$baseUrl/wishlists/items').replace(
        queryParameters: {'wishlist_id': wishlistId, 'product_id': productId.toString()},
      );
      final response = await _client.delete(uri).timeout(defaultTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// GET /api/favorites
  Future<Set<int>> getFavorites({String? userId}) async {
    try {
      final uri = Uri.parse('$baseUrl/favorites').replace(
        queryParameters: {if (userId != null && userId.isNotEmpty) 'user_id': userId},
      );
      final response = await _client.get(uri).timeout(defaultTimeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((e) => (e as num).toInt())
              .where((id) => id > 0)
              .toSet();
        }
      }
    } catch (_) {}
    return {};
  }

  /// POST /api/favorites/toggle
  Future<bool?> toggleFavorite({required int productId, String? userId}) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/favorites/toggle'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'product_id': productId,
              'user_id': userId ?? 'guest',
            }),
          )
          .timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return decoded['data']['is_favorite'] as bool?;
        }
      }
    } catch (_) {}
    return null;
  }
}
