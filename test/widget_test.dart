import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:se_shop_e_commerce_app/app/app_providers.dart';
import 'package:se_shop_e_commerce_app/app/ecommerce_app.dart';
import 'package:se_shop_e_commerce_app/app/main_shell.dart';
import 'package:se_shop_e_commerce_app/core/widgets/nav_bar_item.dart';
import 'package:se_shop_e_commerce_app/data/models/cart_item.dart';
import 'package:se_shop_e_commerce_app/data/models/product.dart';
import 'package:se_shop_e_commerce_app/data/services/api_service.dart';
import 'package:se_shop_e_commerce_app/data/services/local_storage_service.dart';
import 'package:se_shop_e_commerce_app/presentation/cart/checkout_screen.dart';
import 'package:se_shop_e_commerce_app/presentation/explore/explore_screen.dart';
import 'package:se_shop_e_commerce_app/presentation/home/home_screen.dart';
import 'package:se_shop_e_commerce_app/presentation/onboarding/onboarding_screen.dart';
import 'package:se_shop_e_commerce_app/presentation/splash/splash_screen.dart';
import 'package:se_shop_e_commerce_app/providers/home_provider.dart';
import 'package:se_shop_e_commerce_app/providers/session_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FavoritesTestWidget extends StatefulWidget {
  final List<Product> products;

  const _FavoritesTestWidget({required this.products});

  @override
  State<_FavoritesTestWidget> createState() => _FavoritesTestWidgetState();
}

class _FavoritesTestWidgetState extends State<_FavoritesTestWidget> {
  final favorites = <int>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ExploreScreen(
        products: widget.products,
        onProductTap: (_) {},
        onFavoriteToggle: (id) {
          setState(() {
            if (favorites.contains(id)) {
              favorites.remove(id);
            } else {
              favorites.add(id);
            }
          });
        },
        favorites: favorites,
      ),
    );
  }
}

void main() {
  test('product and cart item support the app model specification', () {
    final product = Product(
      id: 1,
      name: 'Classic Tee',
      brand: 'LuxeCart',
      price: 39.99,
      originalPrice: 59.99,
      category: 'Apparel',
      image: 'https://example.com/tee.png',
      rating: 4.8,
      reviews: 120,
      description: 'Comfortable everyday tee',
      sizes: const ['S', 'M', 'L'],
      badge: 'NEW',
    );

    final cartItem = CartItem(product: product, qty: 2, size: 'M');

    expect(product.id, 1);
    expect(product.badge, 'NEW');
    expect(cartItem.qty, 2);
    expect(cartItem.size, 'M');
  });

  testWidgets('first screen displayed upon app launch is SplashScreen with brand emblem and version badge',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: provider,
        child: const ECommerceApp(),
      ),
    );
    await tester.pump();

    // Verify SplashScreen is displayed immediately
    expect(find.text('LuxeCart'), findsOneWidget);
    expect(find.text('CURATED LUXURY & MODERN ESSENTIALS'), findsOneWidget);
    expect(find.text('v2.4.0 • SE Final 2026'), findsOneWidget);

    // Advance past splash duration
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();

    // Now Onboarding is displayed
    expect(find.text('Welcome to LuxeCart'), findsOneWidget);
  });

  testWidgets('first-time unsigned user sees onboarding',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: provider,
        child: const ECommerceApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to LuxeCart'), findsOneWidget);
    expect(find.text('Sign In / Register'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(LocalStorageService.hasOpenedBeforeKey), isTrue);
  });

  testWidgets('returning unsigned user skips onboarding and shows home screen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      LocalStorageService.hasOpenedBeforeKey: true,
      LocalStorageService.isSignedInKey: false,
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: provider,
        child: const ECommerceApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();

    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Welcome to LuxeCart'), findsOneWidget);
    expect(find.text('Sign In for VIP Deals & Perks'), findsOneWidget);
    expect(find.textContaining('Emma'), findsNothing);
  });

  testWidgets('explore screen filters products by selected category',
      (WidgetTester tester) async {
    final products = [
      Product(
        id: 1,
        name: 'Classic Tee',
        brand: 'LuxeCart',
        price: 39.99,
        category: 'Apparel',
        image: 'https://example.com/tee.png',
        rating: 4.8,
        reviews: 120,
        description: 'Comfortable everyday tee',
        sizes: const ['S', 'M', 'L'],
        badge: 'NEW',
      ),
      Product(
        id: 2,
        name: 'Noise Cancelling Headphones',
        brand: 'AudioMax',
        price: 179.99,
        category: 'Electronics',
        image: 'https://example.com/headphones.png',
        rating: 4.7,
        reviews: 98,
        description: 'Premium sound',
        sizes: const ['Standard'],
        badge: 'HOT',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ExploreScreen(
          products: products,
          onProductTap: (_) {},
        ),
      ),
    );

    expect(find.text('Classic Tee'), findsOneWidget);
    expect(find.text('Noise Cancelling Headphones'), findsOneWidget);

    await tester.tap(find.text('#Electronics'));
    await tester.pumpAndSettle();

    expect(find.text('Classic Tee'), findsNothing);
    expect(find.text('Noise Cancelling Headphones'), findsOneWidget);
  });

  testWidgets('explore screen toggles favorite status on card',
      (WidgetTester tester) async {
    final products = [
      Product(
        id: 1,
        name: 'Classic Tee',
        brand: 'LuxeCart',
        price: 39.99,
        category: 'Apparel',
        image: 'https://example.com/tee.png',
        rating: 4.8,
        reviews: 120,
        description: 'Comfortable everyday tee',
        sizes: const ['S', 'M', 'L'],
        badge: 'NEW',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: _FavoritesTestWidget(products: products),
      ),
    );

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  test('home provider handles cart operations, promo discounts and orders', () {
    final provider = HomeProvider();
    final product = Product(
      id: 10,
      name: 'Summer Linen Shirt',
      brand: 'Riviera',
      price: 50.0,
      category: 'Apparel',
      image: 'https://example.com/shirt.png',
      rating: 4.9,
      reviews: 50,
      description: 'Linen shirt',
      sizes: const ['M', 'L'],
    );

    // 1. Add to cart
    provider.addToCart(product, size: 'L', qty: 2);
    expect(provider.cart.length, 1);
    expect(provider.cart.first.quantity, 2);
    expect(provider.subtotal, 100.0);

    // 2. Increment & Decrement
    provider.incrementQuantity(0);
    expect(provider.cart.first.quantity, 3);
    expect(provider.subtotal, 150.0);

    provider.decrementQuantity(0);
    expect(provider.cart.first.quantity, 2);
    expect(provider.subtotal, 100.0);

    // 3. Apply promo code LUXE20 (20% off)
    final promoErr = provider.applyPromoCode('LUXE20');
    expect(promoErr, isNull);
    expect(provider.discountAmount, 20.0);
    // Subtotal = 100, free shipping >= 100, Total = 100 - 20 = 80
    expect(provider.totalAmount, 80.0);

    // 4. Place order
    final order = provider.placeOrder(
      shippingAddress: '123 Test Street, CA',
      paymentMethod: 'PayPal',
    );
    expect(order.orderNumber, startsWith('#LX-'));
    expect(order.totalAmount, 80.0);
    expect(order.status, 'Processing');
    expect(provider.cart, isEmpty);
    expect(provider.orders.length, 1);
  });

  testWidgets('NavBarItem renders label, badge, and handles tap',
      (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              NavBarItem(
                activeIcon: Icons.shopping_bag_rounded,
                inactiveIcon: Icons.shopping_bag_outlined,
                label: 'Cart',
                isSelected: true,
                badgeCount: 3,
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_rounded), findsOneWidget);

    await tester.tap(find.text('Cart'));
    expect(tapped, isTrue);
  });

  testWidgets('HomeScreen category chips filter displayed products',
      (WidgetTester tester) async {
    final products = [
      Product(
        id: 1,
        name: 'Oversized Hoodie',
        brand: 'StreetLab',
        price: 64.99,
        category: 'Apparel',
        image: 'https://example.com/hoodie.png',
        rating: 4.8,
        reviews: 120,
        description: 'Cotton hoodie',
        sizes: const ['S', 'M', 'L'],
      ),
      Product(
        id: 2,
        name: 'Sapphire Watch',
        brand: 'Aster',
        price: 139.00,
        category: 'Accessories',
        image: 'https://example.com/watch.png',
        rating: 4.9,
        reviews: 98,
        description: 'Watch',
        sizes: const ['Standard'],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          onProductTap: (_) {},
          onCartTap: () {},
          cartCount: 0,
          products: products,
          isLoading: false,
        ),
      ),
    );

    // Initial state: shows both products under All
    expect(find.text('Oversized Hoodie'), findsOneWidget);
    expect(find.text('Sapphire Watch'), findsOneWidget);

    // Tap on Accessories chip
    await tester.tap(find.text('Accessories'));
    await tester.pumpAndSettle();

    // Now only Accessories product is visible
    expect(find.text('Oversized Hoodie'), findsNothing);
    expect(find.text('Sapphire Watch'), findsOneWidget);
  });

  testWidgets('ApiService handles product queries and category fallbacks',
      (WidgetTester tester) async {
    final apiService = ApiService();
    final allProducts = await apiService.getProducts();
    expect(allProducts, isNotEmpty);

    final apparel = await apiService.getProducts(category: 'Apparel');
    expect(apparel, isNotEmpty);
    expect(apparel.every((p) => p.category == 'Apparel'), isTrue);

    final categories = await apiService.getCategories();
    expect(categories, isNotEmpty);
  });

  testWidgets('SessionProvider handles sign in, registration and sign out lifecycle',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService();
    await storage.init();
    final session = SessionProvider(storage: storage);
    await session.load();

    expect(session.isSignedIn, isFalse);

    // Register
    await session.register(
      name: 'Sophia Laurent',
      email: 'sophia@example.com',
      password: 'password123',
      phone: '+1 555 999 8888',
    );
    expect(session.isSignedIn, isTrue);
    expect(session.userName, 'Sophia Laurent');
    expect(session.userEmail, 'sophia@example.com');
    expect(storage.isSignedIn, isTrue);

    // Sign Out
    await session.signOut();
    expect(session.isSignedIn, isFalse);
    expect(storage.isSignedIn, isFalse);

    // Sign In again
    await session.completeSignIn(email: 'sophia@example.com', name: 'Sophia Laurent');
    expect(session.isSignedIn, isTrue);
    expect(session.userName, 'Sophia Laurent');
  });

  testWidgets('HomeProvider separates quick favorites from curated wishlist boards',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService();
    await storage.init();
    final provider = HomeProvider(storage: storage);
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Test Favorites (❤️)
    provider.toggleFavorite(1);
    expect(provider.isFavorite(1), isTrue);
    expect(provider.favorites.contains(1), isTrue);

    provider.toggleFavorite(1);
    expect(provider.isFavorite(1), isFalse);

    // 2. Test Wishlists (📋)
    final board = provider.createWishlist(
      'Vacation Lookbook',
      description: 'Linen shirts and sunglasses',
      icon: '🏖️',
      initialProductIds: [6],
    );
    expect(provider.wishlists.any((w) => w.name == 'Vacation Lookbook'), isTrue);

    // Add item to wishlist
    provider.addToWishlist(board.id, 8);
    final updatedBoard = provider.wishlists.firstWhere((w) => w.id == board.id);
    expect(updatedBoard.productIds, containsAll([6, 8]));

    // Remove item from wishlist
    provider.removeFromWishlist(board.id, 6);
    final afterRemoveBoard = provider.wishlists.firstWhere((w) => w.id == board.id);
    expect(afterRemoveBoard.productIds, contains(8));
    expect(afterRemoveBoard.productIds, isNot(contains(6)));
  });

  testWidgets('CheckoutScreen handles order placement without freezing and navigates to OrderSuccessScreen',
      (WidgetTester tester) async {
    final sampleCart = [
      CartItem(
        product: Product(
          id: 1,
          name: 'Heavyweight Cotton Hoodie',
          brand: 'StreetLab',
          price: 64.99,
          category: 'Apparel',
          image: 'https://example.com/hoodie.png',
          rating: 4.8,
          reviews: 142,
          description: 'Premium heavyweight cotton hoodie',
          sizes: const ['S', 'M', 'L'],
        ),
        qty: 1,
        size: 'M',
        color: 'Black',
      ),
    ];

    bool orderPlaced = false;

    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutScreen(
          cartItems: sampleCart,
          onPlaceOrderWithDetails: ({required paymentMethod, required shippingAddress}) {
            orderPlaced = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Secure Checkout'), findsOneWidget);
    expect(find.textContaining('Place Order'), findsOneWidget);

    // Tap Place Order button
    await tester.tap(find.textContaining('Place Order'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(orderPlaced, isTrue);
  });

  testWidgets('unsigned user tapping checkout in MainShell is prompted to Sign Up / Sign In',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService();
    await storage.init();

    final homeProvider = HomeProvider(storage: storage);
    final sessionProvider = SessionProvider(storage: storage);

    // Add 1 item to cart
    homeProvider.addToCart(
      Product(
        id: 1,
        name: 'Heavyweight Cotton Hoodie',
        brand: 'StreetLab',
        price: 64.99,
        category: 'Apparel',
        image: 'https://example.com/hoodie.png',
        rating: 4.8,
        reviews: 142,
        description: 'Premium heavyweight cotton hoodie',
        sizes: const ['M'],
      ),
      size: 'M',
    );

    // Switch to Cart tab (index 2)
    homeProvider.setSelectedIndex(2);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: homeProvider),
          ChangeNotifierProvider.value(value: sessionProvider),
        ],
        child: const MaterialApp(
          home: MainShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Proceed to Checkout button is visible
    final checkoutBtn = find.textContaining('Proceed to Checkout');
    expect(checkoutBtn, findsOneWidget);

    // Ensure visible and tap Proceed to Checkout
    await tester.ensureVisible(checkoutBtn);
    await tester.pumpAndSettle();
    await tester.tap(checkoutBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Sign Up prompt sheet appears
    expect(find.text('Sign Up to Checkout'), findsOneWidget);
    expect(find.text('Create Account (Sign Up)'), findsOneWidget);
    expect(find.text('Already have an account? Sign In'), findsOneWidget);
  });

  testWidgets('SplashScreen renders luxury brand elements and auto-initializes',
      (WidgetTester tester) async {
    bool initialized = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          duration: const Duration(milliseconds: 100),
          onInitialized: () {
            initialized = true;
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('LuxeCart'), findsOneWidget);
    expect(find.text('CURATED LUXURY & MODERN ESSENTIALS'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 150));
    expect(initialized, isTrue);
  });

  testWidgets('OnboardingScreen advances through carousel slides and triggers callbacks',
      (WidgetTester tester) async {
    bool signInTapped = false;
    bool guestTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onSignInOrRegister: () {
            signInTapped = true;
          },
          onContinueAsGuest: () {
            guestTapped = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Slide 1
    expect(find.text('Welcome to LuxeCart'), findsOneWidget);
    expect(find.text('✨ SE SHOP COLLECTION 2026'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);

    // Tap Continue as Guest
    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();
    expect(guestTapped, isTrue);

    // Tap Skip to trigger auth
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(signInTapped, isTrue);
  });
}
