import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:se_shop_e_commerce_app/data/services/api_service.dart';
import 'package:se_shop_e_commerce_app/providers/home_provider.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Live Backend API & Flutter Data Loading Integration Tests', () {
    test('ApiService.getProducts fetches all 50 catalog items from live Laravel API', () async {
      final api = ApiService();
      final products = await api.getProducts();

      expect(products, isNotEmpty);
      expect(products.length, equals(50));

      final first = products.first;
      expect(first.id, equals(1));
      expect(first.name, equals('Oversized Heavyweight Cotton Hoodie'));
      expect(first.price, closeTo(64.99, 0.01));
      expect(first.originalPrice, closeTo(89.99, 0.01));
      expect(first.inStock, isTrue);
      expect(first.reviews, equals(142));
      expect(first.category, equals('Apparel'));
      expect(first.specs, isNotNull);
      expect(first.specs?['Origin'], equals('Portugal'));

      // Validate all 50 items parsed without exception
      for (final p in products) {
        expect(p.id, isPositive);
        expect(p.name, isNotEmpty);
        expect(p.price, isPositive);
        expect(p.category, isNotEmpty);
      }
    });

    test('ApiService.getCategories retrieves live category breakdown', () async {
      final api = ApiService();
      final categories = await api.getCategories();

      expect(categories, isNotEmpty);
      final catNames = categories.map((c) => c.name).toSet();
      expect(catNames.contains('Apparel'), isTrue);
      expect(catNames.contains('Footwear'), isTrue);
      expect(catNames.contains('Accessories'), isTrue);
      expect(catNames.contains('Electronics'), isTrue);
    });

    test('ApiService.getProductById returns single product details', () async {
      final api = ApiService();
      final product = await api.getProductById(1);

      expect(product, isNotNull);
      expect(product!.id, equals(1));
      expect(product.brand, equals('StreetLab'));
      expect(product.specs?['Material'], equals('100% Organic Heavyweight Cotton'));
    });

    test('HomeProvider.loadAllData performs loading lifecycle and populates catalog', () async {
      final provider = HomeProvider();

      final loadFuture = provider.loadAllData();
      // Loading state turns true during fetch
      expect(provider.isLoadingProducts, isTrue);

      await loadFuture;

      // Loading finishes cleanly
      expect(provider.isLoadingProducts, isFalse);
      expect(provider.productsError, isNull);
      expect(provider.products.length, equals(50));
      expect(provider.categories, isNotEmpty);
    });
  });
}
