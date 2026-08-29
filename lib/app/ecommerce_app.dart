import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../presentation/account/forgot_password_screen.dart';
import '../presentation/account/login_screen.dart';
import '../presentation/account/register_screen.dart';
import '../presentation/onboarding/onboarding_screen.dart';
import '../presentation/product_detail/detail_screen.dart';
import '../presentation/splash/splash_screen.dart';
import '../providers/home_provider.dart';
import '../providers/session_provider.dart';
import 'main_shell.dart';

class ECommerceApp extends StatefulWidget {
  final Duration? splashDuration;

  const ECommerceApp({
    super.key,
    this.splashDuration,
  });

  @override
  State<ECommerceApp> createState() => _ECommerceAppState();
}

class _ECommerceAppState extends State<ECommerceApp> {
  bool _splashFinished = false;

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
    // 1. Splash Screen: Displays unconditionally for 5000ms upon app open
    if (!session.isReady || !_splashFinished) {
      return SplashScreen(
        duration: widget.splashDuration ?? const Duration(milliseconds: 5000),
        onInitialized: () {
          if (mounted) {
            setState(() {
              _splashFinished = true;
            });
          }
        },
      );
    }

    // 2. Forgot Password Screen
    if (session.showForgotPassword) {
      return ForgotPasswordScreen(
        onBackToSignIn: () => context.read<SessionProvider>().backToSignIn(),
        onResetRequested: (email) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recovery email sent to $email'),
              backgroundColor: const Color(0xFF1E1E2F),
            ),
          );
        },
      );
    }

    // 3. Register Screen
    if (session.showAuth && session.showRegister) {
      return RegisterScreen(
        onRegisterSuccess: () {
          final email = context.read<SessionProvider>().userEmail;
          context.read<HomeProvider>().switchUserScope(email);
        },
        onBackToSignIn: () => context.read<SessionProvider>().backToSignIn(),
      );
    }

    // 4. Login Screen
    if (session.showAuth) {
      return LoginScreen(
        onLoginSuccess: () {
          final email = context.read<SessionProvider>().userEmail;
          context.read<HomeProvider>().switchUserScope(email);
        },
        onNavigateToRegister: () => context.read<SessionProvider>().openRegister(),
        onForgotPassword: () => context.read<SessionProvider>().openForgotPassword(),
        onBack: () {
          context.read<SessionProvider>().continueAsGuest();
          context.read<HomeProvider>().switchUserScope(null);
        },
      );
    }

    // 5. Onboarding / Auth Gateway for First-Time / Unauthenticated users
    if (session.showOnboarding) {
      return OnboardingScreen(
        onSignInOrRegister: () => context.read<SessionProvider>().openSignIn(),
        onSignIn: () => context.read<SessionProvider>().openSignIn(),
        onRegister: () => context.read<SessionProvider>().openRegister(),
        onForgotPassword: () => context.read<SessionProvider>().openForgotPassword(),
        onSocialLogin: (provider) async {
          final sessionProv = context.read<SessionProvider>();
          final homeProv = context.read<HomeProvider>();
          await sessionProv.signInWithSocial(provider: provider);
          homeProv.switchUserScope(sessionProv.userEmail);
        },
        onContinueAsGuest: () {
          context.read<SessionProvider>().continueAsGuest();
          context.read<HomeProvider>().switchUserScope(null);
        },
      );
    }

    // 6. Selected Product Detail Overlay
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

    // 7. Direct Entry to Main Dashboard / Home Screen (Authenticated or Guest)
    return const MainShell();
  }
}
