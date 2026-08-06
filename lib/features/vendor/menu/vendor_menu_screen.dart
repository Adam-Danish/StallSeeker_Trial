import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/storage_service.dart';

class VendorMenuScreen extends StatefulWidget {
  const VendorMenuScreen({super.key});

  @override
  State<VendorMenuScreen> createState() => _VendorMenuScreenState();
}

class _VendorMenuScreenState extends State<VendorMenuScreen> {
  final _menuService = MenuService();
  final _storageService = StorageService();
  final _auth = FirebaseAuth.instance;

  // Shared by both Add and Edit -- existingItem is null when adding.
  void _showItemDialog({MenuItemModel? existingItem}) {
    final isEditing = existingItem != null;
    final nameController =
        TextEditingController(text: existingItem?.name ?? '');
    final priceController = TextEditingController(
        text:
            existingItem != null ? existingItem.price.toStringAsFixed(2) : '');
    File? pickedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Menu Item' : 'Add Menu Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final file = await _storageService.pickImage();
                  if (file != null) {
                    setDialogState(() {
                      pickedImage = file;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: pickedImage != null
                      ? Image.file(pickedImage!, fit: BoxFit.cover)
                      : (isEditing && existingItem.imageUrl.isNotEmpty)
                          ? Image.network(
                              existingItem.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child:
                                    Icon(Icons.add_a_photo, color: Colors.grey),
                              ),
                            )
                          : const Center(
                              child:
                                  Icon(Icons.add_a_photo, color: Colors.grey),
                            ),
                ),
              ),
              const SizedBox(height: 12),
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
              onPressed: isUploading
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final price =
                          double.tryParse(priceController.text.trim()) ?? 0.0;
                      final user = _auth.currentUser;

                      if (name.isEmpty || price <= 0 || user == null) return;

                      setDialogState(() {
                        isUploading = true;
                      });

                      if (isEditing) {
                        // Only re-upload if the vendor picked a new photo
                        // this time -- otherwise leave the existing one.
                        String? newImageUrl;
                        if (pickedImage != null) {
                          newImageUrl =
                              await _storageService.uploadMenuItemImage(
                                  user.uid, existingItem.itemId, pickedImage!);
                        }

                        await _menuService.updateMenuItem(
                          user.uid,
                          existingItem.itemId,
                          name,
                          price,
                          imageUrl: newImageUrl,
                        );
                      } else {
                        // Photo needs the item's ID in its filename, so
                        // generate the ID first if a photo was picked.
                        String? itemId;
                        String? imageUrl;
                        if (pickedImage != null) {
                          itemId = _menuService.newMenuItemId(user.uid);
                          imageUrl = await _storageService.uploadMenuItemImage(
                              user.uid, itemId, pickedImage!);
                        }

                        await _menuService.addMenuItem(
                          user.uid,
                          name,
                          price,
                          itemId: itemId,
                          imageUrl: imageUrl,
                        );
                      }

                      if (mounted) Navigator.pop(ctx);
                    },
              child: isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Save' : 'Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(),
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: item.imageUrl.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.fastfood,
                                              color: Colors.grey),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.fastfood,
                                            color: Colors.grey),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Colors.blueGrey),
                                  onPressed: () =>
                                      _showItemDialog(existingItem: item),
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
