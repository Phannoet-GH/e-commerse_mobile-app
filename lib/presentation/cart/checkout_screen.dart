import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/cart_item.dart';
import '../../data/models/user_address.dart';
import '../../providers/home_provider.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final List<UserAddress>? savedAddresses;
  final String? appliedPromoCode;
  final double discountAmount;
  final Function({required String shippingAddress, required String paymentMethod})? onPlaceOrderWithDetails;
  final VoidCallback? onPlaceOrder;
  final VoidCallback? onOrderCompleted;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    this.savedAddresses,
    this.appliedPromoCode,
    this.discountAmount = 0.0,
    this.onPlaceOrderWithDetails,
    this.onPlaceOrder,
    this.onOrderCompleted,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late String _selectedPayment;
  late String _selectedAddress;
  late String _recipientName;
  late List<UserAddress> _addresses;
  String _selectedDeliverySpeed = 'Standard';
  String? _promoCode;
  double _promoDiscount = 0.0;
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedPayment = 'Credit Card (•••• 4589)';
    _promoCode = widget.appliedPromoCode;
    _promoDiscount = widget.discountAmount;
    if (_promoCode != null) {
      _promoController.text = _promoCode!;
    }

    final initialList = (widget.savedAddresses != null && widget.savedAddresses!.isNotEmpty)
        ? widget.savedAddresses!
        : _defaultAddresses();
    _addresses = List<UserAddress>.from(initialList);
    if (_addresses.isEmpty) {
      _addresses = List<UserAddress>.from(_defaultAddresses());
    }
    final defaultAddr = _addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => _addresses.first,
    );
    _selectedAddress = defaultAddr.fullAddress;
    _recipientName = defaultAddr.recipientName;
  }

  @override
  void dispose() {
    _promoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<UserAddress> _defaultAddresses() {
    return const [
      UserAddress(
        id: 'addr_1',
        recipientName: 'Guest Shopper',
        street: '14 Market Street, Apt 4B',
        city: 'New York',
        state: 'NY',
        zipCode: '10001',
        country: 'United States',
        phone: '+1 (555) 234-5678',
        isDefault: true,
      ),
    ];
  }

  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
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
                        'Select Delivery Address',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddNewAddressDialog(setModalState),
                        icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFFFF2D6F)),
                        label: const Text(
                          'Add New',
                          style: TextStyle(color: Color(0xFFFF2D6F), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._addresses.map((addr) {
                    final isSelected = _selectedAddress == addr.fullAddress;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFF0F5) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFF2D6F) : Colors.grey.shade200,
                        ),
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(addr.recipientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (addr.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF2D6F),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'DEFAULT',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(addr.fullAddress, style: const TextStyle(fontSize: 12)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF2D6F))
                            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                        onTap: () {
                          setState(() {
                            _selectedAddress = addr.fullAddress;
                            _recipientName = addr.recipientName;
                          });
                          Navigator.of(ctx).pop();
                        },
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddNewAddressDialog(StateSetter setModalState) {
    final nameCtrl = TextEditingController(text: 'Emma Wills');
    final streetCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'New York');
    final stateCtrl = TextEditingController(text: 'NY');
    final zipCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Delivery Address', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Recipient Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: streetCtrl,
                decoration: InputDecoration(
                  labelText: 'Street Address',
                  hintText: 'e.g. 742 Evergreen Terrace',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityCtrl,
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: stateCtrl,
                      decoration: InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: zipCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'ZIP Code',
                  hintText: '10001',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (streetCtrl.text.trim().isNotEmpty) {
                final newAddr = UserAddress(
                  id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
                  recipientName: nameCtrl.text.trim(),
                  street: streetCtrl.text.trim(),
                  city: cityCtrl.text.trim().isEmpty ? 'New York' : cityCtrl.text.trim(),
                  state: stateCtrl.text.trim().isEmpty ? 'NY' : stateCtrl.text.trim(),
                  zipCode: zipCtrl.text.trim().isEmpty ? '10001' : zipCtrl.text.trim(),
                  phone: '+1 (555) 234-5678',
                );

                setState(() {
                  _addresses.add(newAddr);
                  _selectedAddress = newAddr.fullAddress;
                  _recipientName = newAddr.recipientName;
                });
                setModalState(() {});
                Navigator.of(dialogCtx).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2D6F)),
            child: const Text('Save & Select', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _applyPromoCode() {
    final code = _promoController.text.trim().toUpperCase();
    final subtotal = widget.cartItems.fold<double>(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );

    if (code == 'LUXE20') {
      setState(() {
        _promoCode = code;
        _promoDiscount = subtotal * 0.20;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promo LUXE20 applied: 20% OFF!'), backgroundColor: Color(0xFF2E7D32)),
      );
    } else if (code == 'SAVE10') {
      setState(() {
        _promoCode = code;
        _promoDiscount = 10.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promo SAVE10 applied: \$10 OFF!'), backgroundColor: Color(0xFF2E7D32)),
      );
    } else if (code == 'FREESHIP') {
      setState(() {
        _promoCode = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promo FREESHIP applied: Free Delivery!'), backgroundColor: Color(0xFF2E7D32)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Invalid promo code. Try "LUXE20" or "SAVE10"'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Future<void> _handlePlaceOrder() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      if (widget.onPlaceOrderWithDetails != null) {
        widget.onPlaceOrderWithDetails!(
          shippingAddress: _selectedAddress,
          paymentMethod: _selectedPayment,
        );
      } else if (widget.onPlaceOrder != null) {
        widget.onPlaceOrder!();
      } else {
        final order = context.read<HomeProvider>().placeOrder(
              shippingAddress: _selectedAddress,
              paymentMethod: _selectedPayment,
            );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => OrderSuccessScreen(
              order: order,
              onContinueShopping: () {
                Navigator.of(ctx).pop();
                context.read<HomeProvider>().setSelectedIndex(0);
              },
            ),
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order processing notice: $err'),
            backgroundColor: const Color(0xFF1E1E2F),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.cartItems.fold<double>(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
    final isFreeShipping = subtotal >= 100 || _promoCode == 'FREESHIP';
    final baseShipping = isFreeShipping ? 0.0 : 12.0;
    final shipping = _selectedDeliverySpeed == 'Express'
        ? (baseShipping + 15.0)
        : (_selectedDeliverySpeed == 'Same-Day' ? (baseShipping + 25.0) : baseShipping);
    final total = (subtotal - _promoDiscount + shipping).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Secure Checkout', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            // 0. Interactive Steps Progress Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StepBubble(number: '1', title: 'Address', isCompleted: true),
                  _StepDivider(isCompleted: true),
                  _StepBubble(number: '2', title: 'Delivery', isCompleted: true),
                  _StepDivider(isCompleted: true),
                  _StepBubble(number: '3', title: 'Payment', isCompleted: true),
                  _StepDivider(isCompleted: true),
                  _StepBubble(number: '4', title: 'Review', isActive: true),
                ],
              ),
            ),

            // 1. Shipping Address Card
            _CheckoutCard(
              title: 'Shipping Address',
              trailingAction: TextButton(
                onPressed: _showAddressPicker,
                child: const Text('Change', style: TextStyle(color: Color(0xFFFF2D6F), fontWeight: FontWeight.bold)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF0F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_outlined, color: Color(0xFFFF2D6F), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_recipientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 3),
                        Text(
                          _selectedAddress,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Delivery Speed Options
            _CheckoutCard(
              title: 'Delivery Speed',
              child: Column(
                children: [
                  _DeliverySpeedOption(
                    title: 'Standard Delivery (3-5 Days)',
                    subtitle: 'Eco-friendly ground fulfillment',
                    price: isFreeShipping ? 'Free' : '\$12.00',
                    selected: _selectedDeliverySpeed == 'Standard',
                    onTap: () => setState(() => _selectedDeliverySpeed = 'Standard'),
                  ),
                  const SizedBox(height: 8),
                  _DeliverySpeedOption(
                    title: 'Express Air Delivery (1-2 Days)',
                    subtitle: 'Priority air courier with real-time tracking',
                    price: isFreeShipping ? '+\$15.00' : '\$27.00',
                    selected: _selectedDeliverySpeed == 'Express',
                    onTap: () => setState(() => _selectedDeliverySpeed = 'Express'),
                  ),
                  const SizedBox(height: 8),
                  _DeliverySpeedOption(
                    title: 'Same-Day VIP Courier',
                    subtitle: 'Delivered to your door before 8 PM today',
                    price: isFreeShipping ? '+\$25.00' : '\$37.00',
                    selected: _selectedDeliverySpeed == 'Same-Day',
                    onTap: () => setState(() => _selectedDeliverySpeed = 'Same-Day'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Payment Methods
            _CheckoutCard(
              title: 'Payment Method',
              child: Column(
                children: [
                  _PaymentOption(
                    label: 'Visa Card •••• 4589',
                    icon: Icons.credit_card_rounded,
                    badge: 'DEFAULT',
                    selected: _selectedPayment.contains('Visa') || _selectedPayment.contains('Credit Card'),
                    onTap: () => setState(() => _selectedPayment = 'Credit Card (•••• 4589)'),
                  ),
                  const SizedBox(height: 8),
                  _PaymentOption(
                    label: 'PayPal Express',
                    icon: Icons.account_balance_wallet_outlined,
                    selected: _selectedPayment == 'PayPal',
                    onTap: () => setState(() => _selectedPayment = 'PayPal'),
                  ),
                  const SizedBox(height: 8),
                  _PaymentOption(
                    label: 'Apple Pay / Google Pay',
                    icon: Icons.phone_android_rounded,
                    selected: _selectedPayment.contains('Pay'),
                    onTap: () => setState(() => _selectedPayment = 'Apple / Google Pay'),
                  ),
                  const SizedBox(height: 8),
                  _PaymentOption(
                    label: 'Cash on Delivery (COD)',
                    icon: Icons.payments_outlined,
                    selected: _selectedPayment.contains('Cash'),
                    onTap: () => setState(() => _selectedPayment = 'Cash on Delivery'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Promo Voucher Box in Checkout
            _CheckoutCard(
              title: 'Promo Voucher',
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      decoration: InputDecoration(
                        hintText: 'e.g. LUXE20, SAVE10',
                        prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _applyPromoCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2D6F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. Order Summary Card
            _CheckoutCard(
              title: 'Order Summary (${widget.cartItems.length} items)',
              child: Column(
                children: [
                  ...widget.cartItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.product.imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Size: ${item.selectedSize} × ${item.quantity}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                      Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (_promoDiscount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Promo Discount (${_promoCode ?? ""})', style: const TextStyle(color: Color(0xFF2E7D32))),
                        Text(
                          '-\$${_promoDiscount.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Shipping', style: TextStyle(color: Colors.grey)),
                      Text(
                        shipping == 0 ? 'Free' : '\$${shipping.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: shipping == 0 ? const Color(0xFF2E7D32) : Colors.black87,
                          fontWeight: shipping == 0 ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handlePlaceOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2D6F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    'Place Order • \$${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }
}

class _StepBubble extends StatelessWidget {
  final String number;
  final String title;
  final bool isCompleted;
  final bool isActive;

  const _StepBubble({
    required this.number,
    required this.title,
    this.isCompleted = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted || isActive ? const Color(0xFFFF2D6F) : Colors.grey.shade400;

    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFFFF2D6F) : (isActive ? const Color(0xFFFFF0F5) : Colors.grey.shade100),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : Text(
                    number,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? const Color(0xFFFF2D6F) : Colors.grey,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCompleted || isActive ? FontWeight.bold : FontWeight.w500,
            color: isCompleted || isActive ? const Color(0xFF1A1A1A) : Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _StepDivider extends StatelessWidget {
  final bool isCompleted;

  const _StepDivider({this.isCompleted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 2,
      color: isCompleted ? const Color(0xFFFF2D6F) : Colors.grey.shade300,
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailingAction;

  const _CheckoutCard({required this.title, required this.child, this.trailingAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              ?trailingAction,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DeliverySpeedOption extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  const _DeliverySpeedOption({
    required this.title,
    this.subtitle,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0F5) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFF2D6F) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: selected ? const Color(0xFFFF2D6F) : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Text(subtitle!, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),
              ],
            ),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.label,
    required this.icon,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0F5) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFFF2D6F) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: selected ? const Color(0xFFFF2D6F) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 20, color: const Color(0xFF1A1A1A)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
