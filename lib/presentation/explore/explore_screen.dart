import 'package:flutter/material.dart';

import '../../data/models/category_item.dart';
import '../../data/models/product.dart';

enum SortOption { featured, priceLowHigh, priceHighLow, topRated }

class ExploreScreen extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onProductTap;
  final Function(int)? onFavoriteToggle;
  final Set<int>? favorites;
  final List<String>? searchHistory;
  final Function(String)? onSearchPerformed;
  final Function(String)? onRemoveSearchQuery;

  const ExploreScreen({
    super.key,
    required this.products,
    required this.onProductTap,
    this.onFavoriteToggle,
    this.favorites,
    this.searchHistory,
    this.onSearchPerformed,
    this.onRemoveSearchQuery,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  SortOption _sortOption = SortOption.featured;
  RangeValues _priceRange = const RangeValues(0, 500);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getAllCategories() {
    final set = <String>{'All'};
    for (final p in widget.products) {
      set.add(p.category);
    }
    return set.toList();
  }

  int _getItemCountForCategory(String category) {
    if (category == 'All') return widget.products.length;
    return widget.products
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .length;
  }

  List<Product> _filteredProducts(String query) {
    final value = query.trim().toLowerCase();
    var list = widget.products.where((product) {
      final matchesCategory = _selectedCategory == null ||
          _selectedCategory == 'All' ||
          product.category.toLowerCase() == _selectedCategory!.toLowerCase();

      if (!matchesCategory) return false;

      if (product.price < _priceRange.start || product.price > _priceRange.end) {
        return false;
      }

      if (value.isEmpty) return true;

      final haystack = [
        product.name,
        product.brand,
        product.category,
        product.description,
      ].join(' ').toLowerCase();

      return haystack.contains(value);
    }).toList();

    // Sorting
    switch (_sortOption) {
      case SortOption.priceLowHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.topRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.featured:
        break;
    }

    return list;
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final categories = _getAllCategories();
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter & Sort',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCategory = null;
                            _sortOption = SortOption.featured;
                            _priceRange = const RangeValues(0, 500);
                          });
                          setState(() {});
                        },
                        child: const Text(
                          'Reset All',
                          style: TextStyle(color: Color(0xFFFF2D6F), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Sort Options
                  const Text(
                    'Sort By',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSortChip(SortOption.featured, 'Featured', setModalState),
                      _buildSortChip(SortOption.priceLowHigh, 'Price: Low to High', setModalState),
                      _buildSortChip(SortOption.priceHighLow, 'Price: High to Low', setModalState),
                      _buildSortChip(SortOption.topRated, 'Top Rated', setModalState),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Price Range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Price Range',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${_priceRange.start.round()} - \$${_priceRange.end.round()}',
                        style: const TextStyle(
                          color: Color(0xFFFF2D6F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 500,
                    divisions: 50,
                    activeColor: const Color(0xFFFF2D6F),
                    inactiveColor: Colors.grey.shade200,
                    onChanged: (values) {
                      setModalState(() => _priceRange = values);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 14),

                  // Category Filter
                  const Text(
                    'Category',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = (_selectedCategory == null && cat == 'All') ||
                          _selectedCategory?.toLowerCase() == cat.toLowerCase();
                      final meta = CategoryItem.getByName(cat);

                      return ChoiceChip(
                        avatar: Icon(meta.icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF1A1A1A)),
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFF2D6F),
                        backgroundColor: Colors.grey.shade100,
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedCategory = selected ? (cat == 'All' ? null : cat) : null;
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2D6F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(SortOption option, String label, StateSetter setModalState) {
    final isSelected = _sortOption == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFFF2D6F),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setModalState(() => _sortOption = option);
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _filteredProducts(_searchController.text);
    final recentSearches = widget.searchHistory ?? ['Hoodie', 'Sneakers', 'Watch', 'Headphones'];
    final trendingTags = _buildTrendingTags(widget.products);
    final categories = _getAllCategories();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Search Bar & Filter Button
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (val) {
                                if (val.trim().isNotEmpty) {
                                  widget.onSearchPerformed?.call(val.trim());
                                }
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: 'Search products, brands, categories...',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              child: const Icon(Icons.close, size: 18, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _openFilterBottomSheet,
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: (_selectedCategory != null || _sortOption != SortOption.featured)
                            ? const Color(0xFFFF2D6F)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: (_selectedCategory != null || _sortOption != SortOption.featured)
                            ? Colors.white
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Category Quick Chips Bar (All, Apparel, Accessories, Footwear, Electronics, Bags, Jewelry)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = (_selectedCategory == null && cat == 'All') ||
                        _selectedCategory?.toLowerCase() == cat.toLowerCase();
                    final meta = CategoryItem.getByName(cat);
                    final count = _getItemCountForCategory(cat);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = (cat == 'All') ? null : cat;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFF2D6F) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF2D6F) : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              meta.icon,
                              size: 16,
                              color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '($count)',
                              style: TextStyle(
                                color: isSelected ? Colors.white70 : Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Recent & Trending (Show when search is empty and no category selected)
              if (_searchController.text.isEmpty && _selectedCategory == null) ...[
                if (recentSearches.isNotEmpty) ...[
                  const Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recentSearches
                        .map(
                          (item) => GestureDetector(
                            onTap: () {
                              _searchController.text = item;
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.history_rounded, size: 14, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                ],
                const Text(
                  'Trending Categories',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: trendingTags
                      .map(
                        (tag) => GestureDetector(
                          onTap: () {
                            final category = tag.replaceAll('#', '');
                            setState(() {
                              _selectedCategory = _selectedCategory == category ? null : category;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedCategory == tag.replaceAll('#', '')
                                  ? const Color(0xFFFF2D6F)
                                  : const Color(0xFFFFF0F5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedCategory == tag.replaceAll('#', '')
                                    ? const Color(0xFFFF2D6F)
                                    : const Color(0xFFFFD4E2),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: _selectedCategory == tag.replaceAll('#', '')
                                    ? Colors.white
                                    : const Color(0xFFFF2D6F),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
              ],

              // 4. Results Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    filteredProducts.isEmpty
                        ? 'No products found'
                        : (_selectedCategory == null ? 'All Products (${filteredProducts.length})' : '$_selectedCategory (${filteredProducts.length})'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (_selectedCategory != null || _searchController.text.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = null;
                          _searchController.clear();
                          _priceRange = const RangeValues(0, 500);
                          _sortOption = SortOption.featured;
                        });
                      },
                      child: const Text(
                        'Reset Filters',
                        style: TextStyle(color: Color(0xFFFF2D6F), fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // 5. Products Grid
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 14),
                            const Text(
                              'No products match your search',
                              style: TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try checking spelling or clearing filters',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 110),
                        itemCount: filteredProducts.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.65,
                        ),
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final badge = product.badge ?? 'NEW';
                          final badgeColor = _badgeColorFor(badge);
                          final isFav = widget.favorites?.contains(product.id) ?? false;

                          return GestureDetector(
                            onTap: () => widget.onProductTap(product),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
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
                                        child: Image.network(
                                          product.image,
                                          height: 130,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              height: 130,
                                              width: double.infinity,
                                              color: Colors.grey.shade100,
                                              child: const Icon(
                                                Icons.image_not_supported_outlined,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        left: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: badgeColor,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            badge,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: GestureDetector(
                                          onTap: () => widget.onFavoriteToggle?.call(product.id),
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.08),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              isFav ? Icons.favorite : Icons.favorite_border,
                                              size: 16,
                                              color: isFav
                                                  ? const Color(0xFFFF2D6F)
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
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
                                                  color: Colors.grey.shade500,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                product.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0xFF1A1A1A),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    '\$${product.price.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF1A1A1A),
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  if (product.originalPrice != null &&
                                                      product.originalPrice! > product.price)
                                                    Text(
                                                      '\$${product.originalPrice!.toStringAsFixed(0)}',
                                                      style: TextStyle(
                                                        color: Colors.grey.shade400,
                                                        fontSize: 10,
                                                        decoration: TextDecoration.lineThrough,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star_rounded,
                                                      size: 13, color: Color(0xFFFFC400)),
                                                  Text(
                                                    product.rating.toStringAsFixed(1),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _buildTrendingTags(List<Product> products) {
    final tags = <String>[];
    for (final product in products) {
      if (!tags.contains('#${product.category}')) {
        tags.add('#${product.category}');
      }
      if (tags.length >= 6) break;
    }
    return tags;
  }

  Color _badgeColorFor(String badge) {
    if (badge.toUpperCase().contains('SALE')) {
      return const Color(0xFFFF2D6F);
    } else if (badge.toUpperCase().contains('HOT')) {
      return const Color(0xFFFF9800);
    } else {
      return const Color(0xFF6C63FF);
    }
  }
}
