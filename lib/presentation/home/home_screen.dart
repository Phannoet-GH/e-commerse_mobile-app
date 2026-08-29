import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/category_item.dart';
import '../../data/models/product.dart';
import '../../providers/session_provider.dart';
import '../notifications/notifications_screen.dart';

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
  int _currentBannerIndex = 0;
  late Timer _bannerTimer;

  static const List<Map<String, dynamic>> _defaultBannerSlides = [
    {
      'tag': 'LIMITED EDITION',
      'tagColor': Color(0xFFFFC400),
      'title': "Summer '26\nCollection",
      'badge': 'UP TO 40% OFF',
      'category': 'Apparel',
      'fallbackImage':
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'tag': 'NEW ARRIVAL',
      'tagColor': Color(0xFF00E676),
      'title': "Urban Streetwear\nEssentials",
      'badge': 'HOT DROP',
      'category': 'Apparel',
      'fallbackImage':
          'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'tag': 'LUXURY TIMEPIECES',
      'tagColor': Color(0xFF40C4FF),
      'title': "Sapphire Chrono\nWatch Edition",
      'badge': 'VIP EXCLUSIVE',
      'category': 'Accessories',
      'fallbackImage':
          'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'tag': 'RESORT LINEN',
      'tagColor': Color(0xFFFFAB40),
      'title': "Breezy Riviera\nVacation Fit",
      'badge': 'NEW SEASON',
      'category': 'Apparel',
      'fallbackImage':
          'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'tag': 'SIGNATURE LEATHER',
      'tagColor': Color(0xFFFF4081),
      'title': "Handcrafted Luxe\nLeather Goods",
      'badge': 'BESTSELLER',
      'category': 'Accessories',
      'fallbackImage':
          'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?auto=format&fit=crop&w=1200&q=80',
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

    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_bannerController.hasClients) return;
      final nextIndex = (_currentBannerIndex + 1) % 5;
      _bannerController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _bannerTimer.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  List<String> _getCategories() {
    final categories = {'All'};
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

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: const Color(0xFFFF2D6F),
          onRefresh: widget.onRefresh ?? () async {},
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 110.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Mobile Head Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Avatar & Greeting / Welcome Info
                    Expanded(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (!isSignedIn) {
                                sessionProv?.openSignIn();
                              }
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: isSignedIn
                                      ? [const Color(0xFFFF2D6F), const Color(0xFF6C63FF)]
                                      : [const Color(0xFF1E1E2F), const Color(0xFF33334D)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSignedIn
                                        ? const Color(0x33FF2D6F)
                                        : const Color(0x22000000),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isSignedIn && userName.isNotEmpty
                                    ? Text(
                                        userName[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person_outline_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!isSignedIn) {
                                  sessionProv?.openSignIn();
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1A1A1A),
                                      letterSpacing: -0.4,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Head Bar Action Buttons
                    Row(
                      children: [
                        _buildTopIconButton(
                          icon: Icons.search_rounded,
                          onTap: () => widget.onNavigateToExplore?.call(),
                          tooltip: 'Search',
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildTopIconButton(
                              icon: Icons.notifications_none_rounded,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                );
                              },
                              tooltip: 'Notifications',
                            ),
                            if (widget.notificationCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF2D6F),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    '${widget.notificationCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildTopIconButton(
                              icon: Icons.shopping_bag_outlined,
                              onTap: widget.onCartTap,
                              tooltip: 'Cart',
                            ),
                            if (widget.cartCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF2D6F),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    '${widget.cartCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Hero Banner Slider (5 Luxury Product Slides with Auto-Play & Indicators)
                SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(26),
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF2D6F).withValues(alpha: 0.22),
                                      blurRadius: 22,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // 1. Full-bleed Background Product / Fashion Image
                                    Image.network(
                                      slide['image'] as String,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.centerRight,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF1E1E2F),
                                              Color(0xFF2C2440),
                                              Color(0xFFFF2D6F),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // 2. Multi-stop Dark Gradient Overlay for Maximum Text Readability
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            const Color(0xFF0F0E17).withValues(alpha: 0.94),
                                            const Color(0xFF1E1E2F).withValues(alpha: 0.82),
                                            const Color(0xFF2C2440).withValues(alpha: 0.40),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.45, 0.72, 1.0],
                                        ),
                                      ),
                                    ),

                                    // 3. Subtle bottom vignette gradient
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.45),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.45],
                                        ),
                                      ),
                                    ),

                                    // 4. Floating Top Right Discount / Season Tag
                                    Positioned(
                                      top: 16,
                                      right: 16,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.45),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.25),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFF2D6F),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              slide['badge'] as String,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // 5. Left Content: Tag, Title & Action Button
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: slide['tagColor'] as Color,
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (slide['tagColor'] as Color).withValues(alpha: 0.35),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              slide['tag'] as String,
                                              style: const TextStyle(
                                                color: Color(0xFF1A1A1A),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            slide['title'] as String,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                              height: 1.12,
                                              letterSpacing: -0.3,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black45,
                                                  blurRadius: 10,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ElevatedButton(
                                            onPressed: () => widget.onNavigateToExplore?.call(),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: const Color(0xFF1A1A1A),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 18,
                                                vertical: 9,
                                              ),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              elevation: 4,
                                              shadowColor: Colors.black26,
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Shop Now',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(width: 6),
                                                Icon(Icons.arrow_forward_rounded, size: 14),
                                              ],
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

                      // 6. Luxury Dynamic Page Indicator Dots (Pill for Active, Dots for Inactive)
                      Positioned(
                        bottom: 12,
                        right: 18,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (dotIndex) {
                            final isActive = dotIndex == _currentBannerIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isActive ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFFF2D6F)
                                    : Colors.white.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF2D6F).withValues(alpha: 0.5),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Category Header & Rich Filter Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
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
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

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
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFF2D6F) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF2D6F) : Colors.grey.shade200,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF2D6F).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                meta.icon,
                                size: 18,
                                color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                categoryName,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey.shade600,
                                    fontSize: 10,
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

                // Category Tagline Info Banner (when category is selected)
                if (currentCategoryItem != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFD4E2)),
                    ),
                    child: Row(
                      children: [
                        Icon(currentCategoryItem.icon, size: 18, color: const Color(0xFFFF2D6F)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentCategoryItem.description,
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // 4. Flash Sale Banner with Live Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFD4E2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF2D6F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'FLASH SALE',
                                  style: TextStyle(
                                    color: Color(0xFFFF2D6F),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E2F),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _formatDuration(_timeLeft),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Up to 40% off selected items — use code LUXE20',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => widget.onNavigateToExplore?.call(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'View all',
                          style: TextStyle(
                            color: Color(0xFFFF2D6F),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory == null
                          ? 'Trending Products (${widget.products.length})'
                          : '$_selectedCategory Collection (${filtered.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    TextButton(
                      onPressed: () => widget.onNavigateToExplore?.call(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          color: Color(0xFFFF2D6F),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 6. Product Grid
                if (widget.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF2D6F)),
                    ),
                  )
                else if (widget.productsError != null && filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'Unable to load products.\n${widget.productsError}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
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
                      childAspectRatio: 0.64,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      final isFav = widget.favorites?.contains(product.id) ?? false;
                      final badge = product.badge ?? (index == 0 ? 'SALE' : 'NEW');
                      final badgeColor = badge.toUpperCase().contains('SALE')
                          ? const Color(0xFFFF2D6F)
                          : (badge.toUpperCase().contains('HOT')
                              ? const Color(0xFFFF9800)
                              : const Color(0xFF6C63FF));

                      return GestureDetector(
                        onTap: () => widget.onProductTap(product),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(18),
                                    ),
                                    child: Container(
                                      height: 145,
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
                                        horizontal: 8,
                                        vertical: 4,
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
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          isFav ? Icons.favorite : Icons.favorite_border,
                                          size: 16,
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
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            product.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
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
                                                  size: 13,
                                                  color: starIndex < product.rating.floor()
                                                      ? const Color(0xFFFFC400)
                                                      : Colors.grey.shade300,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                product.rating.toStringAsFixed(1),
                                                style: TextStyle(
                                                  fontSize: 10,
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
                                              fontSize: 14,
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
                                                fontSize: 11,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF1A1A1A)),
        ),
      ),
    );
  }
}