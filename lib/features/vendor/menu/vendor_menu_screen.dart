import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/services/menu_service.dart';

class VendorMenuScreen extends StatefulWidget {
  const VendorMenuScreen({super.key});

  @override
  State<VendorMenuScreen> createState() => _VendorMenuScreenState();
}

class _VendorMenuScreenState extends State<VendorMenuScreen> {
  final _menuService = MenuService();
  final _auth = FirebaseAuth.instance;

  void _showAddDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Menu Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'Item Name (e.g. Nasi Lemak)'),
            ),
            TextField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (RM)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;
              final user = _auth.currentUser;

              if (name.isNotEmpty && price > 0 && user != null) {
                await _menuService.addMenuItem(user.uid, name, price);
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'low_stock':
        return Colors.orange;
      case 'out_of_stock':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Dish'),
      ),
      body: user == null
          ? const Center(child: Text('Not logged in.'))
          : StreamBuilder<List<MenuItemModel>>(
              stream: _menuService.getMenuItems(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(
                    child:
                        Text('No menu items added yet.\nTap + Add Dish below!'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('RM ${item.price.toStringAsFixed(2)}'),
                                ],
                              ),
                            ),

                            // Traffic Light Buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Green Button (Available)
                                IconButton(
                                  icon: Icon(
                                    Icons.circle,
                                    color: item.status == 'available'
                                        ? Colors.green
                                        : Colors.green.shade100,
                                    size: item.status == 'available' ? 28 : 20,
                                  ),
                                  onPressed: () =>
                                      _menuService.updateItemStatus(
                                          user.uid, item.itemId, 'available'),
                                ),
                                // Yellow Button (Low Stock)
                                IconButton(
                                  icon: Icon(
                                    Icons.circle,
                                    color: item.status == 'low_stock'
                                        ? Colors.orange
                                        : Colors.orange.shade100,
                                    size: item.status == 'low_stock' ? 28 : 20,
                                  ),
                                  onPressed: () =>
                                      _menuService.updateItemStatus(
                                          user.uid, item.itemId, 'low_stock'),
                                ),
                                // Red Button (Out of Stock)
                                IconButton(
                                  icon: Icon(
                                    Icons.circle,
                                    color: item.status == 'out_of_stock'
                                        ? Colors.red
                                        : Colors.red.shade100,
                                    size:
                                        item.status == 'out_of_stock' ? 28 : 20,
                                  ),
                                  onPressed: () =>
                                      _menuService.updateItemStatus(user.uid,
                                          item.itemId, 'out_of_stock'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.grey),
                                  onPressed: () => _menuService.deleteMenuItem(
                                      user.uid, item.itemId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
