import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/cart_item.dart';
import '../../providers/session_provider.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final Function(int)? onIncrement;
  final Function(int)? onDecrement;
  final Function(int)? onRemove;
  final VoidCallback? onClearCart;
  final String? appliedPromoCode;
  final double discountAmount;
  final Function(String)? onApplyPromoCode;
  final VoidCallback? onRemovePromoCode;
  final VoidCallback? onCheckout;

  const CartScreen({
    super.key,
    required this.cartItems,
    this.onIncrement,
    this.onDecrement,
    this.onRemove,
    this.onClearCart,
    this.appliedPromoCode,
    this.discountAmount = 0.0,
    this.onApplyPromoCode,
    this.onRemovePromoCode,
    this.onCheckout,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final text = _promoController.text.trim();
    if (text.isEmpty) return;
    widget.onApplyPromoCode?.call(text);
    _promoController.clear();
  }

  void _confirmClearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Cart?'),
        content: const Text('Are you sure you want to remove all items from your shopping bag?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onClearCart?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2D6F)),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.cartItems.fold<double>(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
    final shipping = widget.cartItems.isEmpty
        ? 0.0
        : ((subtotal >= 100 || widget.appliedPromoCode == 'FREESHIP') ? 0.0 : 12.0);
    final total = (subtotal - widget.discountAmount + shipping).clamp(0.0, double.infinity);

    SessionProvider? session;
    try {
      session = context.watch<SessionProvider>();
    } catch (_) {}
    final isSignedIn = session?.isSignedIn ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Shopping Cart', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (widget.cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
              onPressed: _confirmClearCart,
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: widget.cartItems.isEmpty
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isSignedIn) ...[
                      // 🛍️ LuxeCart Login Auth Gate for Guest Cart
                      _buildLuxeCartMiniEmblem(),
                      const SizedBox(height: 16),
                      const Text(
                        'Please Login to View Cart',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in with your LuxeCart account to view your saved items, sync devices, and checkout.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => session?.openSignIn(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF2D6F),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 2,
                            shadowColor: const Color(0x55FF2D6F),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => session?.openRegister(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF2D6F), width: 1.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFF2D6F)),
                          ),
                        ),
                      ),
                    ] else ...[
                      // 🛒 Clean "Cart is Empty" for Authenticated Members
                      Container(
                        width: 86,
                        height: 86,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEBEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 42,
                          color: Color(0xFFE53935),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Your Cart is Empty',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Explore our curated catalog and add items you love!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unauthenticated Guest Alert Banner
                  if (!isSignedIn)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFC1CC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.lock_outline_rounded, color: Color(0xFFFF2D6F), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Sign In or Sign Up Required',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E1E2F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You can browse products and add items, but you need an account to proceed to checkout and track delivery.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    onPressed: () => session?.openSignIn(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF2D6F),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: OutlinedButton(
                                    onPressed: () => session?.openRegister(),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFFF2D6F)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFFF2D6F))),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  // Free Shipping Dynamic Threshold Progress Card
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: subtotal >= 100
                            ? [const Color(0xFFE8F5E9), const Color(0xFFDCEDC8)]
                            : [const Color(0xFFFFF0F5), const Color(0xFFFFE4E6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: subtotal >= 100 ? const Color(0xFFA5D6A7) : const Color(0xFFFFC1CC),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              subtotal >= 100 ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
                              size: 18,
                              color: subtotal >= 100 ? const Color(0xFF2E7D32) : const Color(0xFFFF2D6F),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                subtotal >= 100
                                    ? '🎉 You unlocked FREE VIP Shipping!'
                                    : 'Add \$${(100 - subtotal).toStringAsFixed(2)} more for FREE VIP Shipping',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: subtotal >= 100 ? const Color(0xFF2E7D32) : const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (subtotal / 100.0).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: Colors.white.withValues(alpha: 0.8),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              subtotal >= 100 ? const Color(0xFF2E7D32) : const Color(0xFFFF2D6F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cart Items List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
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
                                  item.product.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.product.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => widget.onRemove?.call(index),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Size: ${item.selectedSize} • Color: ${item.selectedColor}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Color(0xFFFF2D6F),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                      // Quantity Stepper
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => widget.onDecrement?.call(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                child: const Icon(Icons.remove, size: 16),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text(
                                                '${item.quantity}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => widget.onIncrement?.call(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                child: const Icon(Icons.add, size: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Voucher / Promo Code Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.confirmation_number_outlined, size: 18, color: Color(0xFFFF2D6F)),
                            SizedBox(width: 8),
                            Text(
                              'Promo Voucher',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (widget.appliedPromoCode != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Code "${widget.appliedPromoCode}" Applied',
                                      style: const TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: widget.onRemovePromoCode,
                                  child: const Text(
                                    'Remove',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    controller: _promoController,
                                    textCapitalization: TextCapitalization.characters,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter code (e.g. LUXE20)',
                                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: _applyCoupon,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E1E2F),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: const Text('Apply', style: TextStyle(fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order Cost Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                            Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (widget.discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Promo Discount', style: TextStyle(color: Color(0xFF2E7D32))),
                              Text(
                                '-\$${widget.discountAmount.toStringAsFixed(2)}',
                                style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated Shipping', style: TextStyle(color: Colors.grey)),
                            Text(
                              shipping == 0 ? 'Free' : '\$${shipping.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: shipping == 0 ? const Color(0xFF2E7D32) : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFFFF2D6F),
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Proceed to Checkout Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: widget.onCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2D6F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0x66FF2D6F),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Proceed to Checkout • \$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 110),
                ],
              ),
            ),
    );
  }

  Widget _buildLuxeCartMiniEmblem() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF2D6F).withValues(alpha: 0.10),
              ),
            ),
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF2D6F).withValues(alpha: 0.18),
              ),
            ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF2D6F),
                    Color(0xFFE01E5A),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2D6F).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.shopping_bag_rounded,
                  size: 26,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'LuxeCart',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: Color(0xFF1A1A1A),
          ),
        ),
        Text(
          'CURATED LUXURY & MODERN ESSENTIALS',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
