import 'unsaved_stall_changes_guard.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/stall_categories.dart';
import '../../../core/models/stall_schedule.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/vendor_phone.dart';
import 'stall_schedule_editor.dart';

class EditStallScreen extends StatefulWidget {
  const EditStallScreen({super.key});

  @override
  State<EditStallScreen> createState() => _EditStallScreenState();
}

class _EditStallScreenState extends State<EditStallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorService = VendorService();
  final _storageService = StorageService();
  final _auth = FirebaseAuth.instance;

  final _stallNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _phoneController = TextEditingController();

  final _selectedCategories = <String>{'Beverages'};
  String? _initialValues;
  final _exitGuard = GlobalKey<UnsavedStallChangesGuardState>();
  final List<String> _categories = stallCategories;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingImage = false;
  bool _isOpen = false;
  Map<int, List<StallHoursInterval>> _weeklyHours = {};
  List<TemporaryClosure> _temporaryClosures = [];

  // Existing photo URL loaded from Firestore, and a newly picked local
  // file (not yet uploaded) if the vendor chose a new photo this session.
  String _existingImageUrl = '';
  File? _pickedImage;

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
      if (!mounted) return;
      if (vendor != null) {
        _stallNameController.text = vendor.stallName;
        _descriptionController.text = vendor.description;
        _openingHoursController.text = vendor.openingHours;
        _weeklyHours = vendor.weeklyHours;
        _temporaryClosures = vendor.temporaryClosures;
        _phoneController.text = vendor.phoneNumber;
        _isOpen = vendor.isOpen;
        _existingImageUrl = vendor.imageUrl;
        _selectedCategories
          ..clear()
          ..addAll(vendor.allCategories);
        if (_selectedCategories.isEmpty) _selectedCategories.add('Beverages');
      }
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _initialValues = _currentValues();
    });
  }

  Future<void> _pickImage() async {
    if (_isSaving || _isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final file = await _storageService.pickImage();
      if (file != null && mounted) {
        setState(() => _pickedImage = file);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not open your photos. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  // Save updated stall profile to Firestore
  Future<void> _saveStallProfile() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose at least one food category.')));
      return;
    }
    if (_isLoading ||
        _isSaving ||
        _isPickingImage ||
        _formKey.currentState?.validate() != true) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Only upload if the vendor picked a new photo this session.
      // Otherwise keep whatever URL was already saved.
      String imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        imageUrl =
            await _storageService.uploadStallImage(user.uid, _pickedImage!);
      }

      final vendor = VendorModel(
        vendorId: user.uid,
        stallName: _stallNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategories.isEmpty ? '' : _selectedCategories.first,
        categories: _selectedCategories.toList(),
        openingHours: _openingHoursController.text.trim(),
        isOpen: _isOpen,
        imageUrl: imageUrl,
        phoneNumber: normalizeVendorPhone(_phoneController.text) ?? '',
        weeklyHours: _weeklyHours,
        temporaryClosures: _temporaryClosures,
      );

      await _vendorService.saveVendorProfile(vendor);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stall profile saved successfully!')),
        );
        _exitGuard.currentState?.close();
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
    _phoneController.dispose();
    super.dispose();
  }

  String _currentValues() => jsonEncode({
        'name': _stallNameController.text,
        'description': _descriptionController.text,
        'phone': _phoneController.text,
        'hours': _openingHoursController.text,
        'categories': _selectedCategories.toList()..sort(),
        'weeklyHours': serializeWeeklyHours(_weeklyHours),
        'closures': _temporaryClosures
            .map((closure) => [
                  closure.start.toUtc().millisecondsSinceEpoch,
                  closure.end.toUtc().millisecondsSinceEpoch,
                ])
            .toList(),
      });

  bool get _hasUnsavedChanges =>
      !_isLoading &&
      (_pickedImage != null || _currentValues() != _initialValues);

  void _requestLeave() => _exitGuard.currentState?.requestLeave();

  Widget _buildImagePicker() {
    Widget imageContent;
    if (_pickedImage != null) {
      imageContent = Image.file(_pickedImage!, fit: BoxFit.cover);
    } else if (_existingImageUrl.isNotEmpty) {
      imageContent = Image.network(
        _existingImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.storefront, size: 48, color: Colors.grey),
      );
    } else {
      imageContent = const Icon(Icons.storefront, size: 48, color: Colors.grey);
    }

    return Semantics(
      label: 'Choose stall photo',
      button: true,
      child: InkWell(
        onTap: _isSaving || _isPickingImage ? null : _pickImage,
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(26),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageContent,
            ),
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedStallChangesGuard(
        key: _exitGuard,
        hasChanges: _hasUnsavedChanges,
        saving: _isSaving,
        onSave: _saveStallProfile,
        child: Scaffold(
          appBar: AppBar(
            leadingWidth: 88,
            leading: TextButton(
              onPressed: _isSaving ? null : _requestLeave,
              child: const Text('Cancel'),
            ),
            title: const Text('Edit stall'),
            actions: [
              TextButton(
                onPressed: _isLoading || _isSaving || _isPickingImage
                    ? null
                    : _saveStallProfile,
                child: Text(_isSaving ? 'Saving…' : 'Done'),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    onChanged: () => setState(() {}),
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        // Stall Photo
                        _buildImagePicker(),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _isSaving || _isPickingImage
                                ? null
                                : _pickImage,
                            icon:
                                const Icon(Icons.add_photo_alternate_outlined),
                            label: Text(_isPickingImage
                                ? 'Opening photos…'
                                : _pickedImage != null ||
                                        _existingImageUrl.isNotEmpty
                                    ? 'Change photo'
                                    : 'Add stall photo'),
                          ),
                        ),
                        const Text(
                            'This photo appears on your stall and dashboard.',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                        if (_pickedImage != null)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text('New photo selected. Tap Done to save.',
                                style: TextStyle(
                                    color: AppColors.primary, fontSize: 13)),
                          ),
                        const SizedBox(height: 16),

                        // Stall Name
                        TextFormField(
                          controller: _stallNameController,
                          decoration: const InputDecoration(
                            labelText: 'Stall Name',
                            hintText: 'e.g. Uncle John Drink Stall',
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Enter stall name'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        Text('Food categories',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final category in {
                            ..._categories,
                            ..._selectedCategories
                          })
                            FilterChip(
                                label: Text(category),
                                selected:
                                    _selectedCategories.contains(category),
                                onSelected: _isSaving
                                    ? null
                                    : (selected) => setState(() {
                                          if (selected) {
                                            _selectedCategories.add(category);
                                          } else {
                                            _selectedCategories
                                                .remove(category);
                                          }
                                        })),
                        ]),
                        const SizedBox(height: 16),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Describe your food/drinks offered...',
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Enter description'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        if (_openingHoursController.text.isNotEmpty &&
                            _weeklyHours.isEmpty)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                  'Previous hours: ${_openingHoursController.text}. Set your weekly hours below.')),
                        StallScheduleEditor(
                            hours: _weeklyHours,
                            closures: _temporaryClosures,
                            onChanged: (hours, closures) => setState(() {
                                  _weeklyHours = hours;
                                  _temporaryClosures = closures;
                                })),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Business phone number',
                            hintText: 'e.g. 012-345 6789',
                          ),
                          validator: (value) =>
                              normalizeVendorPhone(value ?? '') == null
                                  ? 'Enter a valid Malaysian phone number.'
                                  : null,
                        ),
                        const SizedBox(height: 24),

                        if (_isSaving) const LinearProgressIndicator(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ));
  }
}
