import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../presentation/account/login_screen.dart';
import '../presentation/account/register_screen.dart';
import '../presentation/onboarding/onboarding_screen.dart';
import '../presentation/product_detail/detail_screen.dart';
import '../presentation/splash/splash_screen.dart';
import '../providers/home_provider.dart';
import '../providers/session_provider.dart';
import 'main_shell.dart';

class ECommerceApp extends StatefulWidget {
  const ECommerceApp({super.key});

  @override
  State<ECommerceApp> createState() => _ECommerceAppState();
}

class _ECommerceAppState extends State<ECommerceApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeProvider>().loadProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final homeProvider = context.watch<HomeProvider>();

    return MaterialApp(
      title: 'LuxeCart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _home(session, homeProvider),
    );
  }

  Widget _home(SessionProvider session, HomeProvider homeProvider) {
    if (!session.isReady) {
      return SplashScreen(
        onGetStarted: () {},
      );
    }

    if (session.showOnboarding) {
      return OnboardingScreen(
        onSignInOrRegister: () => context.read<SessionProvider>().openSignIn(),
        onContinueAsGuest: () => context.read<SessionProvider>().continueAsGuest(),
      );
    }

    if (session.showAuth && session.showRegister) {
      return RegisterScreen(
        onRegisterSuccess: () => context.read<SessionProvider>().completeSignIn(),
        onBackToSignIn: () => context.read<SessionProvider>().backToSignIn(),
      );
    }

    if (session.showAuth) {
      return LoginScreen(
        onLoginSuccess: () => context.read<SessionProvider>().completeSignIn(),
        onNavigateToRegister: () => context.read<SessionProvider>().openRegister(),
        onBack: () => context.read<SessionProvider>().continueAsGuest(),
      );
    }

    if (homeProvider.selectedProduct != null) {
      final product = homeProvider.selectedProduct!;
      return DetailScreen(
        product: product,
        allProducts: homeProvider.products,
        isFavorite: homeProvider.isFavorite(product.id),
        onFavoriteToggle: () => context.read<HomeProvider>().toggleFavorite(product.id),
        onRelatedProductTap: (rel) => context.read<HomeProvider>().selectProduct(rel),
        onBack: () => context.read<HomeProvider>().clearSelectedProduct(),
        onAddToCart: () {
          context.read<HomeProvider>().addToCart(product);
          context.read<HomeProvider>().clearSelectedProduct();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${product.name}" to cart!'),
              backgroundColor: const Color(0xFF1E1E2F),
              action: SnackBarAction(
                label: 'View Cart',
                textColor: const Color(0xFFFF2D6F),
                onPressed: () => context.read<HomeProvider>().setSelectedIndex(2),
              ),
            ),
          );
        },
      );
    }

    return const MainShell();
  }
}
