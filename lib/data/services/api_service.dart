import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../mock/mock_products.dart';
import '../models/category_item.dart';
import '../models/product.dart';

class ApiService {
  /// Automatic base URL detection for Android Emulator (10.0.2.2) vs Desktop/iOS/Web (localhost)
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    } catch (_) {}
    return 'http://localhost:8000/api';
  }

  final String baseUrl;
  final http.Client _client;

  ApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? defaultBaseUrl,
        _client = client ?? http.Client();

  /// GET /api/products
  Future<List<Product>> getProducts({String? category, String? search}) async {
    try {
      final uri = Uri.parse('$baseUrl/products').replace(
        queryParameters: {
          if (category != null && category.isNotEmpty && category.toLowerCase() != 'all')
            'category': category,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final response = await _client.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is List) {
          final list = (decoded['data'] as List)
              .map((item) => Product.fromJson(item as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty) return list;
        }
      }
    } catch (_) {
      // Offline fallback
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

  /// GET /api/categories
  Future<List<CategoryItem>> getCategories() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/categories')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((item) => CategoryItem.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}

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
          .timeout(const Duration(seconds: 3));

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
          .timeout(const Duration(seconds: 3));

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
          .timeout(const Duration(seconds: 4));

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
      final response = await _client.get(uri).timeout(const Duration(seconds: 3));
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
          .timeout(const Duration(seconds: 3));

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
          .timeout(const Duration(seconds: 3));

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
          .timeout(const Duration(seconds: 3));

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
          .timeout(const Duration(seconds: 3));

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
              if (otp != null) 'otp': otp,
            }),
          )
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
