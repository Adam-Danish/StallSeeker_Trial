import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';

class EditStallScreen extends StatefulWidget {
  const EditStallScreen({super.key});

  @override
  State<EditStallScreen> createState() => _EditStallScreenState();
}

class _EditStallScreenState extends State<EditStallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorService = VendorService();
  final _auth = FirebaseAuth.instance;

  final _stallNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _openingHoursController = TextEditingController();

  String _selectedCategory = 'Beverages';
  final List<String> _categories = [
    'Beverages',
    'Snacks & Desserts',
    'Malay Food',
    'Chinese Food',
    'Indian Food',
    'Western',
    'Noodles',
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _loadExistingVendorData();
  }

  // Fetch vendor info from Firestore to pre-fill the form
  Future<void> _loadExistingVendorData() async {
    final user = _auth.currentUser;
    if (user != null) {
      VendorModel? vendor = await _vendorService.getVendorProfile(user.uid);
      if (vendor != null) {
        _stallNameController.text = vendor.stallName;
        _descriptionController.text = vendor.description;
        _openingHoursController.text = vendor.openingHours;
        _isOpen = vendor.isOpen;
        if (_categories.contains(vendor.category)) {
          _selectedCategory = vendor.category;
        }
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Save updated stall profile to Firestore
  Future<void> _saveStallProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final vendor = VendorModel(
        vendorId: user.uid,
        stallName: _stallNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        openingHours: _openingHoursController.text.trim(),
        isOpen: _isOpen,
      );

      await _vendorService.saveVendorProfile(vendor);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stall profile saved successfully!')),
        );
        Navigator.pop(context); // Return to Dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _stallNameController.dispose();
    _descriptionController.dispose();
    _openingHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Stall Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Stall Name
                    TextFormField(
                      controller: _stallNameController,
                      decoration: const InputDecoration(
                        labelText: 'Stall Name',
                        hintText: 'e.g. Uncle John Drink Stall',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter stall name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Food Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your food/drinks offered...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter description'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Operating Hours
                    TextFormField(
                      controller: _openingHoursController,
                      decoration: const InputDecoration(
                        labelText: 'Opening Hours',
                        hintText: 'e.g. 8:00 AM - 5:00 PM',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter opening hours'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveStallProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
