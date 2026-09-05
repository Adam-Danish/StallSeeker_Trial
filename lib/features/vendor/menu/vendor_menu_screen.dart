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
  final _menu = MenuService();
  final _storage = StorageService();
  final _busyItems = <String>{};
  late Stream<List<MenuItemModel>> _items;
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  static const _statuses = {
    'available': ('Available', Colors.green),
    'low_stock': ('Low stock', Colors.orange),
    'out_of_stock': ('Sold out', Colors.red),
  };

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _items = _uid == null ? Stream.value(<MenuItemModel>[]) : _menu.getMenuItems(_uid);
  }

  void _error(String message) {
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }
  }

  Future<void> _status(MenuItemModel item, String status) async {
    if (_uid == null || _busyItems.contains(item.itemId) || item.status == status) { return; }
    setState(() => _busyItems.add(item.itemId));
    try {
      await _menu.updateItemStatus(_uid, item.itemId, status);
    } catch (_) {
      _error('Could not update stock. Please retry.');
    } finally {
      if (mounted) { setState(() => _busyItems.remove(item.itemId)); }
    }
  }

  Future<void> _delete(MenuItemModel item) async {
    if (_uid == null || _busyItems.contains(item.itemId)) { return; }
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete dish?'),
      content: Text('Delete ${item.name} from your menu? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
      ],
    ));
    if (confirmed != true || !mounted) { return; }
    setState(() => _busyItems.add(item.itemId));
    try { await _menu.deleteMenuItem(_uid, item.itemId); }
    catch (_) { _error('Could not delete this dish. Please retry.'); }
    finally { if (mounted) { setState(() => _busyItems.remove(item.itemId)); } }
  }

  Future<void> _edit([MenuItemModel? item]) async {
    if (_uid == null) { return; }
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, useSafeArea: true,
      isDismissible: false, enableDrag: false,
      builder: (_) => _MenuEditor(uid: _uid, item: item, menu: _menu, storage: _storage),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Menu & stock')),
    floatingActionButton: _uid == null ? null : FloatingActionButton.extended(
      onPressed: _edit, icon: const Icon(Icons.add), label: const Text('Add dish')),
    body: StreamBuilder<List<MenuItemModel>>(stream: _items, builder: (context, snapshot) {
      if (snapshot.hasError) { return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Could not load your menu.'),
        TextButton(onPressed: () => setState(_reload), child: const Text('Retry')),
      ])); }
      if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
      final items = snapshot.data ?? [];
      if (items.isEmpty) { return const Center(child: Text('Your menu is empty.\nTap Add dish to get started.', textAlign: TextAlign.center)); }
      return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final busy = _busyItems.contains(item.itemId);
          return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(
            padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 56, height: 56,
                  child: item.imageUrl.isEmpty ? const Icon(Icons.restaurant, size: 32)
                      : Image.network(item.imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, size: 32)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                  Text('RM ${item.price.toStringAsFixed(2)}'),
                ])),
                PopupMenuButton<String>(enabled: !busy, tooltip: 'Dish options', onSelected: (value) {
                  if (value == 'edit') { _edit(item); } else { _delete(item); }
                }, itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit dish')),
                  PopupMenuItem(value: 'delete', child: Text('Delete dish')),
                ]),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 4, children: _statuses.entries.map((entry) => ChoiceChip(
                label: Text(entry.value.$1),
                avatar: Icon(Icons.circle, size: 12, color: entry.value.$2),
                selected: item.status == entry.key,
                onSelected: busy ? null : (_) => _status(item, entry.key),
              )).toList()),
              if (busy) const LinearProgressIndicator(),
            ]),
          ));
        });
    }),
  );
}

class _MenuEditor extends StatefulWidget {
  const _MenuEditor({required this.uid, required this.item, required this.menu, required this.storage});
  final String uid;
  final MenuItemModel? item;
  final MenuService menu;
  final StorageService storage;
  @override
  State<_MenuEditor> createState() => _MenuEditorState();
}

class _MenuEditorState extends State<_MenuEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final String _itemId;
  File? _image;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? '');
    _price = TextEditingController(text: widget.item?.price.toStringAsFixed(2) ?? '');
    // Reuse the same ID on retries so an uncertain network result cannot duplicate a dish.
    _itemId = widget.item?.itemId ?? widget.menu.newMenuItemId(widget.uid);
  }
  @override
  void dispose() { _name.dispose(); _price.dispose(); super.dispose(); }

  Future<void> _pick() async {
    try {
      final image = await widget.storage.pickImage();
      if (mounted && image != null) { setState(() => _image = image); }
    } catch (_) {
      if (mounted) { setState(() => _error = 'Could not open your photos. Please retry.'); }
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) { return; }
    setState(() { _saving = true; _error = null; });
    try {
      String? imageUrl;
      if (_image != null) { imageUrl = await widget.storage.uploadMenuItemImage(widget.uid, _itemId, _image!); }
      if (widget.item == null) {
        await widget.menu.addMenuItem(widget.uid, _name.text.trim(), double.parse(_price.text.trim()),
            itemId: _itemId, imageUrl: imageUrl);
      } else {
        await widget.menu.updateMenuItem(widget.uid, _itemId, _name.text.trim(), double.parse(_price.text.trim()), imageUrl: imageUrl);
      }
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) { setState(() { _saving = false; _error = 'Could not save this dish. Your changes are still here. Please retry.'; }); }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.item == null ? 'Add dish' : 'Edit dish', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        if (_image != null) ClipRRect(borderRadius: BorderRadius.circular(12),
            child: Image.file(_image!, height: 140, fit: BoxFit.cover))
        else if (widget.item?.imageUrl.isNotEmpty == true)
          Image.network(widget.item!.imageUrl, height: 140, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.restaurant)),
        TextButton.icon(onPressed: _saving ? null : _pick, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Choose photo')),
        TextFormField(controller: _name, enabled: !_saving, maxLength: 80,
          decoration: const InputDecoration(labelText: 'Dish name'),
          validator: (value) => value == null || value.trim().isEmpty ? 'Enter a dish name.' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _price, enabled: !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Price', prefixText: 'RM '),
          validator: (value) {
            final text = value?.trim() ?? '';
            final price = double.tryParse(text);
            if (price == null || !price.isFinite || price <= 0 || !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
              return 'Enter a positive price with up to 2 decimal places.';
            }
            return null;
          }),
        if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 20),
        FilledButton(onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save dish')),
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
      ])),
    ),
  );
}
