import 'dart:async';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onSignInOrRegister;
  final VoidCallback onContinueAsGuest;
  final VoidCallback? onSignIn;
  final VoidCallback? onRegister;
  final VoidCallback? onForgotPassword;
  final Function(String provider)? onSocialLogin;
  final bool autoSlide;
  final Duration autoSlideDuration;

  const OnboardingScreen({
    super.key,
    required this.onSignInOrRegister,
    required this.onContinueAsGuest,
    this.onSignIn,
    this.onRegister,
    this.onForgotPassword,
    this.onSocialLogin,
    this.autoSlide = true,
    this.autoSlideDuration = const Duration(milliseconds: 3200),
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      icon: Icons.storefront_rounded,
      title: 'Welcome to LuxeCart',
      subtitle: 'Discover top-grade mobile accessories, power banks, audio gadgets, and lifestyle essentials from LuxeCart.',
      badge: '✨ SE SHOP COLLECTION 2026',
    ),
    _OnboardingPageData(
      icon: Icons.pin_drop_rounded,
      title: 'Accurate Map Pinning',
      subtitle: 'Pin your precise delivery address with building and landmark notes for express courier dispatch across Cambodia.',
      badge: '📍 LUXECART MAP DELIVERY',
    ),
    _OnboardingPageData(
      icon: Icons.qr_code_scanner_rounded,
      title: 'Fast ABA KHQR & COD',
      subtitle: 'Checkout seamlessly using ABA PAY, local mobile wallets, or pay in cash upon doorstep delivery.',
      badge: '⚡ INSTANT LOCAL PAYMENTS',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.autoSlide) {
      _startAutoSlideTimer();
    }
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(widget.autoSlideDuration, (timer) {
      if (!mounted || !_pageController.hasClients) return;
      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      if (_currentPage + 1 >= _pages.length - 1) {
        _autoSlideTimer?.cancel();
      }
    } else {
      _autoSlideTimer?.cancel();
      widget.onContinueAsGuest();
    }
  }

  void _handleSignIn() {
    (widget.onSignIn ?? widget.onSignInOrRegister)();
  }

  void _handleRegister() {
    (widget.onRegister ?? widget.onSignInOrRegister)();
  }

  void _handleSocial(String provider) {
    if (widget.onSocialLogin != null) {
      widget.onSocialLogin!(provider);
    } else {
      widget.onSignInOrRegister();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF2D6F),
              Color(0xFFE01E5A),
              Color(0xFF8B0032),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              children: [
                // Top Bar with Brand Pill & Skip Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'SE SHOP 2026',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onContinueAsGuest,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Multi-Slide Carousel
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (idx) {
                      setState(() => _currentPage = idx);
                      if (idx >= _pages.length - 1) {
                        _autoSlideTimer?.cancel();
                      }
                    },
                    itemBuilder: (context, index) {
                      final item = _pages[index];
                      return Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          // Luxury Icon Circle with Glow
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: const Color(0xFFFF2D6F).withValues(alpha: 0.3),
                                  blurRadius: 36,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              item.icon,
                              size: 54,
                              color: const Color(0xFFFF2D6F),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Pill Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              item.badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Title
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              item.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.90),
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Fluid Capsule Page Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: _currentPage == index
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Action Area
                if (!isLastPage) ...[
                  // Primary Action Button (Next)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF2D6F),
                        elevation: 6,
                        shadowColor: Colors.black.withValues(alpha: 0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.navigate_next_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Final Slide Action - Simple Konfulon Design
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: widget.onContinueAsGuest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF2D6F),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Simple Member Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: _handleSignIn,
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
  });
}
