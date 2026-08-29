import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/product.dart';
import '../../providers/home_provider.dart';

class DetailScreen extends StatefulWidget {
  final Product product;
  final List<Product>? allProducts;
  final VoidCallback onAddToCart;
  final VoidCallback onBack;
  final Function(Product)? onRelatedProductTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const DetailScreen({
    super.key,
    required this.product,
    this.allProducts,
    required this.onAddToCart,
    required this.onBack,
    this.onRelatedProductTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _quantity = 1;
  String? _selectedSize;
  String? _selectedColor;
  int _activeImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.product.sizes.isNotEmpty ? widget.product.sizes.first : null;
    _selectedColor = widget.product.colors.isNotEmpty ? widget.product.colors.first : null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showWishlistPicker(BuildContext context) {
    final homeProv = context.read<HomeProvider>();
    final wishlists = homeProv.wishlists;

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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No wishlist boards yet. Create one below!'),
                )
              else
                ...wishlists.map((w) {
                  final alreadyIn = w.productIds.contains(widget.product.id);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 38,
                      height: 38,
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
                              homeProv.addToWishlist(w.id, widget.product.id);
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
                  final controller = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('New Wishlist Board'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(hintText: 'e.g. Dream Wardrobe'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(dCtx).pop(), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            if (controller.text.trim().isNotEmpty) {
                              homeProv.createWishlist(
                                controller.text.trim(),
                                initialProductIds: [widget.product.id],
                              );
                              Navigator.of(dCtx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Created and added to "${controller.text.trim()}"!'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2D6F)),
                          child: const Text('Create'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, color: Color(0xFFFF2D6F), size: 18),
                label: const Text('Create New Wishlist Board', style: TextStyle(color: Color(0xFFFF2D6F), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
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

  void _showSizeGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Size Guide', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Standard International Sizing Guide:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              children: const [
                TableRow(
                  decoration: BoxDecoration(color: Color(0xFFF0F0F0)),
                  children: [
                    Padding(padding: EdgeInsets.all(6), child: Text('Size', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(6), child: Text('Chest (in)', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(6), child: Text('Waist (in)', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(padding: EdgeInsets.all(6), child: Text('S')),
                    Padding(padding: EdgeInsets.all(6), child: Text('36 - 38')),
                    Padding(padding: EdgeInsets.all(6), child: Text('29 - 31')),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(padding: EdgeInsets.all(6), child: Text('M')),
                    Padding(padding: EdgeInsets.all(6), child: Text('39 - 41')),
                    Padding(padding: EdgeInsets.all(6), child: Text('32 - 34')),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(padding: EdgeInsets.all(6), child: Text('L')),
                    Padding(padding: EdgeInsets.all(6), child: Text('42 - 44')),
                    Padding(padding: EdgeInsets.all(6), child: Text('35 - 37')),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(padding: EdgeInsets.all(6), child: Text('XL')),
                    Padding(padding: EdgeInsets.all(6), child: Text('45 - 47')),
                    Padding(padding: EdgeInsets.all(6), child: Text('38 - 40')),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFFFF2D6F), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _parseHexColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF1A1A1A);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images.isNotEmpty
        ? widget.product.images
        : [widget.product.imageUrl];
    final total = widget.product.price * _quantity;
    final relatedProducts = widget.allProducts
            ?.where((p) => p.id != widget.product.id && p.category == widget.product.category)
            .take(4)
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Image Carousel Header
                    Stack(
                      children: [
                        Container(
                          height: 340,
                          width: double.infinity,
                          color: Colors.white,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: images.length,
                            onPageChanged: (idx) => setState(() => _activeImageIndex = idx),
                            itemBuilder: (context, index) {
                              return Image.network(
                                images[index],
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Top Nav Bar
                        Positioned(
                          top: 14,
                          left: 16,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildCircleButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: widget.onBack,
                              ),
                              Row(
                                children: [
                                  if (widget.product.badge != null)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF2D6F),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        widget.product.badge!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  _buildCircleButton(
                                    icon: Icons.bookmark_add_outlined,
                                    iconColor: const Color(0xFF6C63FF),
                                    onTap: () => _showWishlistPicker(context),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildCircleButton(
                                    icon: widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                                    iconColor: widget.isFavorite ? const Color(0xFFFF2D6F) : const Color(0xFF1A1A1A),
                                    onTap: widget.onFavoriteToggle ?? () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Carousel Dots
                        if (images.length > 1)
                          Positioned(
                            bottom: 14,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                images.length,
                                (dotIndex) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: _activeImageIndex == dotIndex ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _activeImageIndex == dotIndex
                                        ? const Color(0xFFFF2D6F)
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // 2. Product Info Card
                    Container(
                      transform: Matrix4.translationValues(0, -16, 0),
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand & Category
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.product.brand.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.product.inStock ? 'In Stock' : 'Out of Stock',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Product Title
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Rating & Reviews Summary
                          Row(
                            children: [
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    Icons.star_rounded,
                                    size: 18,
                                    color: i < widget.product.rating.floor()
                                        ? const Color(0xFFFFC400)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.product.rating.toStringAsFixed(1),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${widget.product.reviewsCount} verified reviews)',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Price & Discount Tag
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '\$${widget.product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFF2D6F),
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (widget.product.originalPrice != null &&
                                  widget.product.originalPrice! > widget.product.price) ...[
                                Text(
                                  '\$${widget.product.originalPrice!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade400,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '-${(((widget.product.originalPrice! - widget.product.price) / widget.product.originalPrice!) * 100).round()}% OFF',
                                    style: const TextStyle(
                                      color: Color(0xFFFF2D6F),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Color Variants
                          if (widget.product.colors.isNotEmpty) ...[
                            const Text(
                              'Color',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: widget.product.colors.map((hex) {
                                final color = _parseHexColor(hex);
                                final isSelected = _selectedColor == hex;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedColor = hex),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFFF2D6F) : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Size Selection
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Select Size',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              GestureDetector(
                                onTap: _showSizeGuideDialog,
                                child: const Text(
                                  'Size Guide',
                                  style: TextStyle(
                                    color: Color(0xFFFF2D6F),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: widget.product.sizes.map((size) {
                              final isSelected = _selectedSize == size;
                              return ChoiceChip(
                                label: Text(size),
                                selected: isSelected,
                                selectedColor: const Color(0xFFFF2D6F),
                                backgroundColor: Colors.grey.shade100,
                                side: BorderSide.none,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.bold,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedSize = size);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 22),

                          // Description
                          const Text(
                            'Description',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.product.description,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Specifications
                          if (widget.product.specs.isNotEmpty) ...[
                            const Text(
                              'Product Specifications',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: widget.product.specs.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            entry.key,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            entry.value,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF1A1A1A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Customer Reviews
                          if (widget.product.customerReviews.isNotEmpty) ...[
                            const Text(
                              'Customer Reviews',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            ...widget.product.customerReviews.map((rev) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          rev.userName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          rev.date,
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: i < rev.rating.floor()
                                              ? const Color(0xFFFFC400)
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      rev.comment,
                                      style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                          ],

                          // Related Products Slider
                          if (relatedProducts.isNotEmpty) ...[
                            const Text(
                              'You May Also Like',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 190,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: relatedProducts.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final rel = relatedProducts[index];
                                  return GestureDetector(
                                    onTap: () => widget.onRelatedProductTap?.call(rel),
                                    child: Container(
                                      width: 140,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                            child: Image.network(
                                              rel.imageUrl,
                                              height: 100,
                                              width: 140,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  rel.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '\$${rel.price.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: Color(0xFFFF2D6F),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
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
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Sticky Bottom Action Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Quantity Stepper
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                          icon: const Icon(Icons.remove_rounded, size: 18),
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _quantity++),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Add to Cart Button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: widget.onAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF2D6F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_bag_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Add to Cart • \$${total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
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
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: iconColor ?? const Color(0xFF1A1A1A)),
      ),
    );
  }
}