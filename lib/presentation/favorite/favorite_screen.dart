import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/product.dart';
import '../../data/models/wishlist_board.dart';
import '../../providers/home_provider.dart';

class FavoriteScreen extends StatefulWidget {
  final List<Product> allProducts;
  final Set<int> favorites;
  final Function(Product)? onProductTap;
  final Function(int)? onRemoveFavorite;
  final Function(Product)? onAddToCart;
  final Function(List<Product>)? onAddAllToCart;

  const FavoriteScreen({
    super.key,
    required this.allProducts,
    required this.favorites,
    this.onProductTap,
    this.onRemoveFavorite,
    this.onAddToCart,
    this.onAddAllToCart,
  });

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  int _activeSegment = 0; // 0 = Favorites (❤️), 1 = Wishlists (📋)

  void _showCreateWishlistDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedIcon = '✨';

    final icons = ['✨', '☀️', '🎁', '🏖️', '👔', '🎧', '💎', '👟'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create Wishlist Board',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(modalContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Select Board Icon:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: icons.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final ic = icons[i];
                        final isSel = ic == selectedIcon;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => selectedIcon = ic);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFFFF0F5) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? const Color(0xFFFF2D6F) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(ic, style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Wishlist Title',
                      hintText: 'e.g. Dream Outfits, Summer Vacation',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.bookmark_border_rounded, color: Color(0xFFFF2D6F)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add notes for this collection...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          context.read<HomeProvider>().createWishlist(
                                nameController.text.trim(),
                                description: descController.text.trim(),
                                icon: selectedIcon,
                              );
                          Navigator.of(modalContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Wishlist "${nameController.text.trim()}" created!'),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2D6F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Create Wishlist',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  void _showAddToWishlistDialog(BuildContext context, Product product) {
    final wishlists = context.read<HomeProvider>().wishlists;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Save to Wishlist Board',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(modalContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (wishlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No wishlist boards yet. Create one first!',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                ...wishlists.map((w) {
                  final alreadyIn = w.productIds.contains(product.id);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text(w.icon, style: const TextStyle(fontSize: 18))),
                    ),
                    title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${w.productIds.length} items', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    trailing: alreadyIn
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                        : TextButton(
                            onPressed: () {
                              context.read<HomeProvider>().addToWishlist(w.id, product.id);
                              Navigator.of(modalContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added to "${w.name}"!'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            },
                            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF2D6F))),
                          ),
                  );
                }),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(modalContext).pop();
                  _showCreateWishlistDialog(context);
                },
                icon: const Icon(Icons.add_rounded, color: Color(0xFFFF2D6F), size: 18),
                label: const Text('Create New Wishlist Board', style: TextStyle(color: Color(0xFFFF2D6F), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Color(0xFFFF2D6F)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProducts = widget.allProducts.where((p) => widget.favorites.contains(p.id)).toList();
    final wishlists = context.watch<HomeProvider>().wishlists;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Saved & Wishlists', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_activeSegment == 1)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFFF2D6F)),
              tooltip: 'New Wishlist Board',
              onPressed: () => _showCreateWishlistDialog(context),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Segment Switcher (Favorites vs Wishlists)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Segment 0: Favorites
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _activeSegment = 0);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeSegment == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _activeSegment == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                size: 16,
                                color: _activeSegment == 0 ? const Color(0xFFFF2D6F) : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Favorites (${favoriteProducts.length})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _activeSegment == 0 ? FontWeight.bold : FontWeight.w600,
                                  color: _activeSegment == 0 ? const Color(0xFF1A1A1A) : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Segment 1: Wishlists
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _activeSegment = 1);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeSegment == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _activeSegment == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bookmark_added_rounded,
                                size: 16,
                                color: _activeSegment == 1 ? const Color(0xFF6C63FF) : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Wishlists (${wishlists.length})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _activeSegment == 1 ? FontWeight.bold : FontWeight.w600,
                                  color: _activeSegment == 1 ? const Color(0xFF1A1A1A) : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab Content
            Expanded(
              child: _activeSegment == 0
                  ? _buildFavoritesTab(favoriteProducts)
                  : _buildWishlistsTab(wishlists),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: FAVORITES VIEW
  // -------------------------------------------------------------
  Widget _buildFavoritesTab(List<Product> favoriteProducts) {
    if (favoriteProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 40,
                color: Color(0xFFFF2D6F),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No favorite items yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the ❤️ heart icon on any product to like and save it!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: favoriteProducts.length,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = favoriteProducts[index];
              return GestureDetector(
                onTap: () => widget.onProductTap?.call(product),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade100,
                          child: Image.network(
                            product.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.brand.toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFFFF2D6F),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
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
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.bookmark_add_outlined, color: Color(0xFF6C63FF), size: 20),
                            onPressed: () => _showAddToWishlistDialog(context, product),
                            tooltip: 'Save to Wishlist Board',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                            onPressed: () => widget.onRemoveFavorite?.call(product.id),
                            tooltip: 'Remove',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Add All to Cart Bottom Action
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => widget.onAddAllToCart?.call(favoriteProducts),
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text(
                'Move All Favorites to Cart',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2D6F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: WISHLIST BOARDS VIEW
  // -------------------------------------------------------------
  Widget _buildWishlistsTab(List<WishlistBoard> wishlists) {
    if (wishlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF0EFFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_outline_rounded,
                size: 40,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No wishlist boards yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Create curated boards like "Summer Vacation" or "Gift Ideas"!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showCreateWishlistDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create Your First Wishlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: wishlists.length,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final board = wishlists[index];
        final boardProducts = widget.allProducts.where((p) => board.productIds.contains(p.id)).toList();
        final totalValue = boardProducts.fold<double>(0.0, (sum, p) => sum + p.price);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text(board.icon, style: const TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            board.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                          ),
                          Text(
                            '${board.productIds.length} items • \$${totalValue.toStringAsFixed(2)} total',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!board.isDefault)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 18),
                      onPressed: () {
                        context.read<HomeProvider>().deleteWishlist(board.id);
                      },
                    ),
                ],
              ),
              if (board.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  board.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 12),

              // Product Thumbnails Preview
              if (boardProducts.isNotEmpty)
                SizedBox(
                  height: 65,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: boardProducts.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final prod = boardProducts[i];
                      return GestureDetector(
                        onTap: () => widget.onProductTap?.call(prod),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 65,
                            height: 65,
                            color: Colors.grey.shade100,
                            child: Image.network(
                              prod.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('Board is empty. Add products from store!', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ),
                ),

              const SizedBox(height: 12),
              // Board Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: boardProducts.isNotEmpty
                          ? () {
                              context.read<HomeProvider>().addWishlistToCart(board);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added ${boardProducts.length} items from "${board.name}" to cart!'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.shopping_bag_outlined, size: 15),
                      label: const Text('Add Board to Cart', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
