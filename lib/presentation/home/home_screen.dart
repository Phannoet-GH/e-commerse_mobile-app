import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/category_item.dart';
import '../../data/models/product.dart';
import '../../providers/home_provider.dart';
import '../../providers/session_provider.dart';
import '../account/address_manager_screen.dart';
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
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
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
    String userName = '';
    String addressTitle = 'Deliver to Home';
    SessionProvider? sessionProv;
    try {
      final session = context.watch<SessionProvider>();
      sessionProv = session;
      isSignedIn = session.isSignedIn;
      if (session.isSignedIn && session.userName.trim().isNotEmpty) {
        userName = session.userName.trim().split(' ').first;
      }
      final homeProv = context.watch<HomeProvider>();
      if (homeProv.addresses.isNotEmpty) {
        final def = homeProv.addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => homeProv.addresses.first,
        );
        addressTitle = '${def.street}, ${def.city}';
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSignedIn
                                      ? '${_getGreeting()}, $userName'
                                      : 'Welcome to LuxeCart',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                if (isSignedIn)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const AddressManagerScreen(),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.location_on_rounded,
                                          size: 13,
                                          color: Color(0xFFFF2D6F),
                                        ),
                                        const SizedBox(width: 3),
                                        Flexible(
                                          child: Text(
                                            addressTitle,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: () => sessionProv?.openSignIn(),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Sign In for VIP Deals & Perks',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFFF2D6F),
                                          ),
                                        ),
                                        SizedBox(width: 3),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 10,
                                          color: Color(0xFFFF2D6F),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
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

                // 2. Hero Banner
                Container(
                  width: double.infinity,
                  height: 185,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E1E2F),
                        Color(0xFF2C2440),
                        Color(0xFFFF2D6F),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2D6F).withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'LIMITED EDITION',
                                style: TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Summer '26\nCollection",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: () => widget.onNavigateToExplore?.call(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1A1A1A),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
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