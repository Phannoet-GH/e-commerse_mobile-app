import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/category_item.dart';
import '../../data/models/product.dart';
import '../../providers/home_provider.dart';
import '../../providers/session_provider.dart';
import '../account/address_manager_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(Product) onProductTap;
  final VoidCallback onCartTap;
  final VoidCallback? onNavigateToExplore;
  final int cartCount;
  final int notificationCount;
  final List<Product> products;
  final bool isLoading;
  final String? productsError;
  final Set<int>? favorites;
  final Function(int)? onFavoriteToggle;
  final Future<void> Function()? onRefresh;

  const HomeScreen({
    super.key,
    required this.onProductTap,
    required this.onCartTap,
    this.onNavigateToExplore,
    required this.cartCount,
    this.notificationCount = 0,
    required this.products,
    required this.isLoading,
    this.productsError,
    this.favorites,
    this.onFavoriteToggle,
    this.onRefresh,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory;
  late Timer _countdownTimer;
  Duration _timeLeft = const Duration(hours: 9, minutes: 42, seconds: 18);

  final PageController _bannerController = PageController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _promotionsKey = GlobalKey();
  final GlobalKey _bestSellersKey = GlobalKey();
  final GlobalKey _categoriesKey = GlobalKey();

  int _currentBannerIndex = 0;
  late Timer _bannerTimer;

  static const List<Map<String, dynamic>> _defaultBannerSlides = [
    {
      'tag': 'FESTIVE SALE',
      'tagColor': Color(0xFFFFD700),
      'title': "50% OFF\nMEGA DEALS",
      'badge': 'UP TO 50% OFF',
      'category': 'Electronics',
      'fallbackImage':
          'https://images.unsplash.com/photo-1546868871-7041f2a55e12?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'tag': 'POWER STATION',
      'tagColor': Color(0xFF00E676),
      'title': "1500W Backup\nSolar Generator",
      'badge': '100W PD FAST',
      'category': 'Electronics',
      'fallbackImage':
          'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'tag': 'WIRELESS AUDIO',
      'tagColor': Color(0xFF40C4FF),
      'title': "Bass Boost\nTWS Earbuds",
      'badge': 'HOT DROP',
      'category': 'Accessories',
      'fallbackImage':
          'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'tag': 'FAST CHARGING',
      'tagColor': Color(0xFFFFAB40),
      'title': "65W GaN Hub\n& Braided Wire",
      'badge': 'BESTSELLER',
      'category': 'Accessories',
      'fallbackImage':
          'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'tag': 'OFFICIAL STORE',
      'tagColor': Color(0xFFFF5252),
      'title': "100% Genuine\nLuxeCart Gear",
      'badge': '1-YR WARRANTY',
      'category': 'Apparel',
      'fallbackImage':
          'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=1200&q=80',
    },
  ];

  Map<String, dynamic> _getSlideData(int index) {
    final base = _defaultBannerSlides[index % _defaultBannerSlides.length];
    String imageUrl = base['fallbackImage'] as String;
    if (widget.products.isNotEmpty) {
      final matched = widget.products
          .where((p) => p.category.toLowerCase() == (base['category'] as String).toLowerCase())
          .toList();
      if (matched.isNotEmpty) {
        imageUrl = matched[index % matched.length].image;
      } else if (index < widget.products.length) {
        imageUrl = widget.products[index].image;
      }
    }
    return {
      ...base,
      'image': imageUrl,
    };
  }

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft.inSeconds > 0) {
            _timeLeft = _timeLeft - const Duration(seconds: 1);
          }
        });
      }
    });

    _bannerTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (!mounted || !_bannerController.hasClients || !_bannerController.position.haveDimensions) return;
      final nextIndex = (_currentBannerIndex + 1) % 5;
      try {
        _bannerController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _bannerTimer.cancel();
    _bannerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  List<String> _getCategories() {
    final categories = {'All'};
    try {
      final homeProv = context.read<HomeProvider>();
      for (final cat in homeProv.categories) {
        if (cat.name.trim().isNotEmpty && cat.name.trim() != 'All') {
          categories.add(cat.name.trim());
        }
      }
    } catch (_) {}
    for (final product in widget.products) {
      categories.add(product.category);
    }
    return categories.toList();
  }

  int _getItemCountForCategory(String category) {
    if (category == 'All') return widget.products.length;
    return widget.products
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .length;
  }

  List<Product> _getFilteredProducts() {
    if (_selectedCategory == null || _selectedCategory == 'All') {
      return widget.products;
    }
    return widget.products
        .where((p) => p.category.toLowerCase() == _selectedCategory!.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredProducts();
    final currentCategoryItem = _selectedCategory != null
        ? CategoryItem.getByName(_selectedCategory!)
        : null;

    // Optional provider context reading
    bool isSignedIn = false;
    String userName = 'Guest User';
    SessionProvider? sessionProv;
    try {
      final session = context.watch<SessionProvider>();
      sessionProv = session;
      isSignedIn = session.isSignedIn;
      if (session.isSignedIn) {
        if (session.userName.trim().isNotEmpty) {
          userName = session.userName.trim();
        } else if (session.userEmail.isNotEmpty) {
          userName = session.userEmail.split('@').first;
        }
      }
    } catch (_) {}

    // Read active address for location bar
    String locationText = '14 Market Street, New York';
    try {
      final homeProv = context.watch<HomeProvider>();
      final defAddr = homeProv.defaultAddress;
      if (defAddr != null) {
        final formatted = '${defAddr.city}, ${defAddr.state} ${defAddr.zipCode}'.trim();
        locationText = formatted.isNotEmpty ? formatted : defAddr.street;
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: Column(
        children: [
          // 💎 1. LUXECART SIGNATURE GRADIENT HEADER BAR
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF2D6F), // LuxeCart Signature Pink
                  Color(0xFFE01E5A),
                  Color(0xFFC2185B),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33FF2D6F),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 12.0),
                child: Column(
                  children: [
                    // Row A: Delivery Location & Account Greeting
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Delivery location
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AddressManagerScreen(),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Deliver: ',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    locationText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // User account state badge
                        GestureDetector(
                          onTap: () {
                            if (!isSignedIn) {
                              sessionProv?.openSignIn();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isSignedIn ? Icons.person : Icons.person_outline_rounded,
                                      size: 12,
                                      color: const Color(0xFFFF2D6F),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 100),
                                  child: Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Row B: White Pill Search Bar + Konfulon '文A' Language Switcher
                    Row(
                      children: [
                        // White Pill Search Bar
                        Expanded(
                          child: GestureDetector(
                            onTap: () => widget.onNavigateToExplore?.call(),
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    color: Colors.grey.shade500,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Search',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Konfulon '文A' Language Switcher Button
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Language: English / ភាសាខ្មែរ'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            height: 40,
                            width: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '文A',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 📜 2. SCROLLABLE HOME FEED
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFFF2D6F),
              onRefresh: widget.onRefresh ?? () async {},
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14.0, 10.0, 14.0, 110.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🎈 A. HERO BANNER CAROUSEL (50% OFF Festive Promo)
                    SizedBox(
                      width: double.infinity,
                      height: 165,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: PageView.builder(
                              controller: _bannerController,
                              itemCount: 5,
                              onPageChanged: (idx) {
                                setState(() => _currentBannerIndex = idx);
                              },
                              itemBuilder: (context, index) {
                                final slide = _getSlideData(index);
                                return GestureDetector(
                                  onTap: () => widget.onNavigateToExplore?.call(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: index == 0
                                            ? [
                                                const Color(0xFFFF2D6F),
                                                const Color(0xFFE01E5A),
                                                const Color(0xFFC2185B),
                                              ]
                                            : [
                                                const Color(0xFF1E1E2F),
                                                const Color(0xFF2C2440),
                                                const Color(0xFFFF2D6F),
                                              ],
                                      ),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // Product backdrop
                                        Opacity(
                                          opacity: 0.35,
                                          child: Image.network(
                                            slide['image'] as String,
                                            fit: BoxFit.cover,
                                            alignment: Alignment.centerRight,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const SizedBox.shrink(),
                                          ),
                                        ),

                                        // Festive overlay
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                Colors.black.withValues(alpha: 0.65),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Banner Text Content
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: slide['tagColor'] as Color,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  slide['tag'] as String,
                                                  style: const TextStyle(
                                                    color: Color(0xFF1A1A1A),
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                slide['title'] as String,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1.1,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 9, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  slide['badge'] as String,
                                                  style: const TextStyle(
                                                    color: Color(0xFFFF2D6F),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Indicator Dots
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (dotIndex) {
                                final isActive = dotIndex == _currentBannerIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                  width: isActive ? 18 : 6,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFFFF2D6F)
                                        : Colors.white.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 🎯 B. THE 5 KONFULON CIRCULAR ACTION ICONS (Expanded to fit any screen width)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildKonfulonIconCircle(
                              color: const Color(0xFFFF2D6F), // LuxeCart Pink
                              icon: Icons.format_list_bulleted_rounded,
                              label: 'Category',
                              onTap: () => _scrollToKey(_categoriesKey),
                            ),
                          ),
                          Expanded(
                            child: _buildKonfulonIconCircle(
                              color: const Color(0xFFFFA000), // Amber Gold
                              icon: Icons.local_offer_rounded,
                              label: 'Promotions',
                              onTap: () => _scrollToKey(_promotionsKey),
                            ),
                          ),
                          Expanded(
                            child: _buildKonfulonIconCircle(
                              color: const Color(0xFF6C63FF), // LuxeCart Purple
                              icon: Icons.diamond_outlined,
                              label: 'Top Selection',
                              onTap: () {
                                setState(() => _selectedCategory = 'Electronics');
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildKonfulonIconCircle(
                              color: const Color(0xFFFF3D57), // Coral Flame
                              icon: Icons.local_fire_department_rounded,
                              label: 'Best Sellers',
                              onTap: () => _scrollToKey(_bestSellersKey),
                            ),
                          ),
                          Expanded(
                            child: _buildKonfulonIconCircle(
                              color: const Color(0xFF2563EB), // Royal Store Blue
                              icon: Icons.storefront_rounded,
                              label: 'Store',
                              onTap: () => widget.onNavigateToExplore?.call(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 🏷️ C. CATEGORIES HEADER & FILTER CHIPS (Visible without scrolling in test viewport)
                    Row(
                      key: _categoriesKey,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        if (_selectedCategory != null)
                          GestureDetector(
                            onTap: () => setState(() => _selectedCategory = null),
                            child: const Text(
                              'Show All',
                              style: TextStyle(
                                color: Color(0xFFFF2D6F),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _getCategories().map((categoryName) {
                          final isSelected = (_selectedCategory == null && categoryName == 'All') ||
                              _selectedCategory?.toLowerCase() == categoryName.toLowerCase();
                          final meta = CategoryItem.getByName(categoryName);
                          final count = _getItemCountForCategory(categoryName);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = categoryName == 'All' ? null : categoryName;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFF2D6F) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFFF2D6F) : Colors.grey.shade200,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF2D6F).withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    meta.icon,
                                    size: 15,
                                    color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    categoryName,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.grey.shade600,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    if (currentCategoryItem != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFD4E2)),
                        ),
                        child: Row(
                          children: [
                            Icon(currentCategoryItem.icon, size: 15, color: const Color(0xFFFF2D6F)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentCategoryItem.description,
                                style: const TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // ⚡ D. SECONDARY PROMO BANNER (1500W Super Power Station)
                    GestureDetector(
                      onTap: () => widget.onNavigateToExplore?.call(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFE0F7FA),
                              Color(0xFFB2EBF2),
                              Color(0xFF80DEEA),
                            ],
                          ),
                          border: Border.all(color: const Color(0xFF4DD0E1), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00838F),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '1500W SUPER POWER STATION',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '360,000 mAh',
                                    style: TextStyle(
                                      color: Color(0xFFD32F2F),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '60W-100W PD Fast Charging • Solar Generator\nLED Flash Light • AC & DC Output',
                                    style: TextStyle(
                                      color: Color(0xFF004D40),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.power_rounded,
                                color: Color(0xFF00838F),
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 🏷️ E. PROMOTIONS WHITE CONTAINER CARD (Horizontal Deals Scroll)
                    Container(
                      key: _promotionsKey,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Promotions',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => widget.onNavigateToExplore?.call(),
                                child: Text(
                                  'See more',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Horizontal scroll of promo items
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: widget.products.take(6).map((product) {
                                final originalPrice = product.originalPrice ?? (product.price * 1.4);
                                return GestureDetector(
                                  onTap: () => widget.onProductTap(product),
                                  child: Container(
                                    width: 95,
                                    margin: const EdgeInsets.only(right: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Product Image Box
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            height: 88,
                                            width: 88,
                                            color: Colors.grey.shade100,
                                            child: Image.network(
                                              product.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Center(
                                                child: Icon(
                                                  Icons.image_not_supported_outlined,
                                                  color: Colors.grey,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),

                                        // LuxeCart Signature Price Capsule
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF2D6F),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '\$${product.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),

                                        // Slashed original price
                                        Text(
                                          '\$${originalPrice.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 9.5,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 🔥 F. BEST SELLERS HEADER
                    Row(
                      key: _bestSellersKey,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Best Sellers',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onNavigateToExplore?.call(),
                          child: Text(
                            'See more',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 🛍️ G. PRODUCT GRID
                    if (widget.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF2D6F),
                            strokeWidth: 3,
                          ),
                        ),
                      )
                    else ...[
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(28),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  widget.productsError != null
                                      ? 'Unable to load products.\n${widget.productsError}'
                                      : 'No products found in this category.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            final isFav = widget.favorites?.contains(product.id) ?? false;
                            final badge = product.badge ?? (index == 0 ? 'SALE' : 'NEW');
                            final badgeColor = badge.toUpperCase().contains('SALE')
                                ? const Color(0xFFFF2D6F)
                                : (badge.toUpperCase().contains('HOT')
                                    ? const Color(0xFFFF9800)
                                    : const Color(0xFF2979FF));

                            return GestureDetector(
                              onTap: () => widget.onProductTap(product),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                          child: Container(
                                            height: 140,
                                            width: double.infinity,
                                            color: Colors.grey.shade100,
                                            child: Image.network(
                                              product.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Center(
                                                child: Icon(
                                                  Icons.image_not_supported_outlined,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeColor,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              badge,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => widget.onFavoriteToggle?.call(product.id),
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.1),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                isFav ? Icons.favorite : Icons.favorite_border,
                                                size: 15,
                                                color: isFav
                                                    ? const Color(0xFFFF2D6F)
                                                    : const Color(0xFF1A1A1A),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.category.toUpperCase(),
                                                  style: TextStyle(
                                                    color: Colors.grey.shade400,
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.6,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  product.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12.5,
                                                    color: Color(0xFF1A1A1A),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    ...List.generate(
                                                      5,
                                                      (starIndex) => Icon(
                                                        Icons.star_rounded,
                                                        size: 12,
                                                        color: starIndex < product.rating.floor()
                                                            ? const Color(0xFFFFB300)
                                                            : Colors.grey.shade300,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      product.rating.toStringAsFixed(1),
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        color: Colors.grey.shade600,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  '\$${product.price.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 13.5,
                                                    color: Color(0xFF1A1A1A),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                if (product.originalPrice != null &&
                                                    product.originalPrice! > product.price)
                                                  Text(
                                                    '\$${product.originalPrice!.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      color: Colors.grey.shade400,
                                                      fontSize: 10.5,
                                                      decoration: TextDecoration.lineThrough,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKonfulonIconCircle({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.32),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
