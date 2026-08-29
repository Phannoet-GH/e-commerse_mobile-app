import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_address.dart';
import '../../providers/home_provider.dart';

class AddressManagerScreen extends StatelessWidget {
  const AddressManagerScreen({super.key});

  void _showAddEditAddressDialog(BuildContext context, {UserAddress? existing}) {
    final nameCtrl = TextEditingController(text: existing?.recipientName ?? '');
    final streetCtrl = TextEditingController(text: existing?.street ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');
    final stateCtrl = TextEditingController(text: existing?.state ?? '');
    final zipCtrl = TextEditingController(text: existing?.zipCode ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    bool isDefault = existing?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null ? 'Add New Address' : 'Edit Address',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Recipient Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: streetCtrl,
                      decoration: const InputDecoration(labelText: 'Street Address & Apt'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cityCtrl,
                            decoration: const InputDecoration(labelText: 'City'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: stateCtrl,
                            decoration: const InputDecoration(labelText: 'State'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: zipCtrl,
                            decoration: const InputDecoration(labelText: 'Zip Code'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Set as Default Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      value: isDefault,
                      activeThumbColor: const Color(0xFFFF2D6F),
                      onChanged: (val) => setModalState(() => isDefault = val),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty || streetCtrl.text.trim().isEmpty) return;
                          final address = UserAddress(
                            id: existing?.id ?? 'addr_${DateTime.now().millisecondsSinceEpoch}',
                            recipientName: nameCtrl.text.trim(),
                            street: streetCtrl.text.trim(),
                            city: cityCtrl.text.trim().isEmpty ? 'New York' : cityCtrl.text.trim(),
                            state: stateCtrl.text.trim().isEmpty ? 'NY' : stateCtrl.text.trim(),
                            zipCode: zipCtrl.text.trim().isEmpty ? '10001' : zipCtrl.text.trim(),
                            phone: phoneCtrl.text.trim().isEmpty ? '+1 (555) 000-0000' : phoneCtrl.text.trim(),
                            isDefault: isDefault,
                          );

                          if (existing == null) {
                            context.read<HomeProvider>().addAddress(address);
                          } else {
                            context.read<HomeProvider>().updateAddress(address);
                          }
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2D6F)),
                        child: Text(existing == null ? 'Save Address' : 'Update Address', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final addresses = homeProvider.addresses;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Shipping Addresses', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No addresses saved yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final addr = addresses[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: addr.isDefault ? const Color(0xFFFF2D6F) : Colors.grey.shade200,
                      width: addr.isDefault ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(addr.recipientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              if (addr.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'DEFAULT',
                                    style: TextStyle(
                                      color: Color(0xFFFF2D6F),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                                onPressed: () => _showAddEditAddressDialog(context, existing: addr),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                onPressed: () => homeProvider.deleteAddress(addr.id),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(addr.fullAddress, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Phone: ${addr.phone}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      if (!addr.isDefault) ...[
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => homeProvider.setDefaultAddress(addr.id),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          child: const Text('Set as Default', style: TextStyle(color: Color(0xFFFF2D6F), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _showAddEditAddressDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2D6F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 20),
                SizedBox(width: 8),
                Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
