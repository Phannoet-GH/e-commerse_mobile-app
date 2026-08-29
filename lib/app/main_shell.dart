import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/widgets/nav_bar_item.dart';
import '../presentation/account/login_screen.dart';
import '../presentation/account/profile_screen.dart';
import '../presentation/account/register_screen.dart';
import '../presentation/cart/cart_screen.dart';
import '../presentation/cart/checkout_screen.dart';
import '../presentation/cart/order_success_screen.dart';
import '../presentation/explore/explore_screen.dart';
import '../presentation/favorite/favorite_screen.dart';
import '../presentation/home/home_screen.dart';
import '../providers/home_provider.dart';
import '../providers/session_provider.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  void _navigateToCheckout(BuildContext context, HomeProvider homeProvider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (checkoutContext) => CheckoutScreen(
          cartItems: homeProvider.cart,
          savedAddresses: homeProvider.addresses,
          appliedPromoCode: homeProvider.appliedPromoCode,
          discountAmount: homeProvider.discountAmount,
          onPlaceOrderWithDetails: ({required shippingAddress, required paymentMethod}) {
            final order = context.read<HomeProvider>().placeOrder(
                  shippingAddress: shippingAddress,
                  paymentMethod: paymentMethod,
                );
            Navigator.of(checkoutContext).pushReplacement(
              MaterialPageRoute(
                builder: (successContext) => OrderSuccessScreen(
                  order: order,
                  onContinueShopping: () {
                    Navigator.of(successContext).pop();
                    context.read<HomeProvider>().setSelectedIndex(0);
                  },
                ),
              ),
            );
          },
          onPlaceOrder: () {
            final order = context.read<HomeProvider>().placeOrder();
            Navigator.of(checkoutContext).pushReplacement(
              MaterialPageRoute(
                builder: (successContext) => OrderSuccessScreen(
                  order: order,
                  onContinueShopping: () {
                    Navigator.of(successContext).pop();
                    context.read<HomeProvider>().setSelectedIndex(0);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAuthRequiredSheet(BuildContext context, HomeProvider homeProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFFF2D6F),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign Up to Checkout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please create an account or sign in to complete your order, track live delivery, and unlock VIP rewards.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            // Primary Button: Create Account (Sign Up)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (regContext) => RegisterScreen(
                        onRegisterSuccess: () {
                          Navigator.of(regContext).pop();
                          _navigateToCheckout(context, homeProvider);
                        },
                        onBackToSignIn: () {
                          Navigator.of(regContext).pop();
                        },
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2D6F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Create Account (Sign Up)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Secondary Button: Sign In
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (loginContext) => LoginScreen(
                        onLoginSuccess: () {
                          Navigator.of(loginContext).pop();
                          _navigateToCheckout(context, homeProvider);
                        },
                        onNavigateToRegister: () {
                          Navigator.of(loginContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (regCtx) => RegisterScreen(
                                onRegisterSuccess: () {
                                  Navigator.of(regCtx).pop();
                                  _navigateToCheckout(context, homeProvider);
                                },
                                onBackToSignIn: () => Navigator.of(regCtx).pop(),
                              ),
                            ),
                          );
                        },
                        onBack: () => Navigator.of(loginContext).pop(),
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Already have an account? Sign In',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();

    final screens = [
      HomeScreen(
        onProductTap: (product) => context.read<HomeProvider>().selectProduct(product),
        onCartTap: () => context.read<HomeProvider>().setSelectedIndex(2),
        onNavigateToExplore: () => context.read<HomeProvider>().setSelectedIndex(1),
        cartCount: homeProvider.cart.fold<int>(0, (sum, i) => sum + i.quantity),
        notificationCount: homeProvider.unreadNotificationsCount,
        products: homeProvider.products,
        isLoading: homeProvider.isLoadingProducts,
        productsError: homeProvider.productsError,
        favorites: homeProvider.favorites,
        onFavoriteToggle: (id) => context.read<HomeProvider>().toggleFavorite(id),
        onRefresh: () => context.read<HomeProvider>().loadProducts(),
      ),
      ExploreScreen(
        products: homeProvider.products,
        onProductTap: (product) => context.read<HomeProvider>().selectProduct(product),
        onFavoriteToggle: (id) => context.read<HomeProvider>().toggleFavorite(id),
        favorites: homeProvider.favorites,
        searchHistory: homeProvider.searchHistory,
        onSearchPerformed: (query) => context.read<HomeProvider>().addSearchQuery(query),
        onRemoveSearchQuery: (query) => context.read<HomeProvider>().removeSearchQuery(query),
      ),
      CartScreen(
        cartItems: homeProvider.cart,
        appliedPromoCode: homeProvider.appliedPromoCode,
        discountAmount: homeProvider.discountAmount,
        onIncrement: (idx) => context.read<HomeProvider>().incrementQuantity(idx),
        onDecrement: (idx) => context.read<HomeProvider>().decrementQuantity(idx),
        onRemove: (idx) => context.read<HomeProvider>().removeFromCart(idx),
        onClearCart: () => context.read<HomeProvider>().clearCart(),
        onApplyPromoCode: (code) {
          final err = context.read<HomeProvider>().applyPromoCode(code);
          if (err != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Voucher code applied!'),
                backgroundColor: Color(0xFF2E7D32),
              ),
            );
          }
        },
        onRemovePromoCode: () => context.read<HomeProvider>().removePromoCode(),
        onCheckout: () {
          final session = context.read<SessionProvider>();
          if (!session.isSignedIn) {
            _showAuthRequiredSheet(context, homeProvider);
          } else {
            _navigateToCheckout(context, homeProvider);
          }
        },
      ),
      FavoriteScreen(
        allProducts: homeProvider.products,
        favorites: homeProvider.favorites,
        onProductTap: (product) => context.read<HomeProvider>().selectProduct(product),
        onRemoveFavorite: (id) => context.read<HomeProvider>().toggleFavorite(id),
        onAddAllToCart: (products) {
          context.read<HomeProvider>().addMultipleToCart(products);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added all items to cart!')),
          );
          context.read<HomeProvider>().setSelectedIndex(2);
        },
      ),
      const ProfileScreen(),
    ];

    final cartBadgeCount = homeProvider.cart.fold<int>(0, (sum, i) => sum + i.quantity);

    return Scaffold(
      body: screens[homeProvider.selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NavBarItem(
                  activeIcon: Icons.home_rounded,
                  inactiveIcon: Icons.home_outlined,
                  label: 'Home',
                  isSelected: homeProvider.selectedIndex == 0,
                  onTap: () => context.read<HomeProvider>().setSelectedIndex(0),
                ),
                NavBarItem(
                  activeIcon: Icons.search_rounded,
                  inactiveIcon: Icons.search_outlined,
                  label: 'Explore',
                  isSelected: homeProvider.selectedIndex == 1,
                  onTap: () => context.read<HomeProvider>().setSelectedIndex(1),
                ),
                NavBarItem(
                  activeIcon: Icons.shopping_bag_rounded,
                  inactiveIcon: Icons.shopping_bag_outlined,
                  label: 'Cart',
                  isSelected: homeProvider.selectedIndex == 2,
                  badgeCount: cartBadgeCount,
                  onTap: () => context.read<HomeProvider>().setSelectedIndex(2),
                ),
                NavBarItem(
                  activeIcon: Icons.favorite_rounded,
                  inactiveIcon: Icons.favorite_outline_rounded,
                  label: 'Saved',
                  isSelected: homeProvider.selectedIndex == 3,
                  badgeCount: homeProvider.favorites.length,
                  onTap: () => context.read<HomeProvider>().setSelectedIndex(3),
                ),
                NavBarItem(
                  activeIcon: Icons.person_rounded,
                  inactiveIcon: Icons.person_outline_rounded,
                  label: 'Profile',
                  isSelected: homeProvider.selectedIndex == 4,
                  onTap: () => context.read<HomeProvider>().setSelectedIndex(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
