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
import 'edit_stall_view.dart';
import 'stall_profile_draft.dart';
import '../../customer/vendor_details/vendor_details_screen.dart';

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
  VendorModel? _loadedVendor;
  String? _loadError;
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
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _loadError = 'Sign in again to edit your stall.';
      });
      return;
    }
    VendorModel? vendor = await _vendorService.getVendorProfile(user.uid);
    if (!mounted) return;
    _loadedVendor = vendor ??
        VendorModel(
            vendorId: user.uid,
            stallName: '',
            description: '',
            category: 'Beverages',
            openingHours: '');
    if (vendor != null) {
      _stallNameController.text = vendor.stallName;
      _descriptionController.text = vendor.description;
      _openingHoursController.text = vendor.openingHours;
      _weeklyHours = vendor.weeklyHours;
      _temporaryClosures = vendor.temporaryClosures;
      _phoneController.text = vendor.phoneNumber;
      _existingImageUrl = vendor.imageUrl;
      _selectedCategories
        ..clear()
        ..addAll(vendor.allCategories);
      if (_selectedCategories.isEmpty) _selectedCategories.add('Beverages');
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

      final vendor = _draftVendor(imageUrl: imageUrl);

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
      _loadError == null &&
      _loadedVendor != null &&
      (_pickedImage != null || _currentValues() != _initialValues);

  void _requestLeave() => _exitGuard.currentState?.requestLeave();

  VendorModel _draftVendor({String? imageUrl}) => buildStallProfileDraft(
        original: _loadedVendor!,
        name: _stallNameController.text,
        description: _descriptionController.text,
        phone: _phoneController.text,
        legacyHours: _openingHoursController.text,
        categories: _selectedCategories,
        hours: _weeklyHours,
        closures: _temporaryClosures,
        imageUrl: imageUrl,
      );

  void _preview() {
    if (_isLoading || _isSaving || _isPickingImage || _loadedVendor == null) {
      return;
    }
    if (_auth.currentUser?.uid != _loadedVendor!.vendorId) return;
    FocusScope.of(context).unfocus();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => VendorDetailsScreen(
                vendor: _draftVendor(),
                previewOnly: true,
                draftPreview: true,
                draftPhoto: _pickedImage)));
  }

  Widget _buildImagePicker() {
    final placeholder = const Center(
        child: Icon(Icons.storefront_outlined,
            size: 52, color: AppColors.primary));
    final image = _pickedImage != null
        ? Image.file(_pickedImage!,
            fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder)
        : _existingImageUrl.isNotEmpty
            ? Image.network(_existingImageUrl,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder)
            : placeholder;
    return LayoutBuilder(
        builder: (context, constraints) => SizedBox(
              height:
                  (constraints.maxWidth * 9 / 16).clamp(160, 260).toDouble(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                    color: AppColors.mint,
                    child: InkWell(
                      onTap: _isSaving || _isPickingImage ? null : _pickImage,
                      child: Stack(fit: StackFit.expand, children: [
                        image,
                        Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Center(
                                child: FilledButton.icon(
                                    onPressed: _isSaving || _isPickingImage
                                        ? null
                                        : _pickImage,
                                    style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.primary,
                                        minimumSize: const Size(48, 48),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 18, vertical: 12)),
                                    icon: const Icon(Icons.camera_alt_outlined,
                                        size: 20),
                                    label: Text(_isPickingImage
                                        ? 'Opening photos…'
                                        : 'Change photo')))),
                      ]),
                    )),
              ),
            ));
  }

  @override
  Widget build(BuildContext context) => UnsavedStallChangesGuard(
        key: _exitGuard,
        hasChanges: _hasUnsavedChanges,
        saving: _isSaving,
        onSave: _saveStallProfile,
        child: EditStallView(
          formKey: _formKey,
          nameController: _stallNameController,
          descriptionController: _descriptionController,
          phoneController: _phoneController,
          image: _buildImagePicker(),
          categoryOptions: _categories,
          selectedCategories: _selectedCategories,
          legacyHours: _openingHoursController.text,
          hours: _weeklyHours,
          closures: _temporaryClosures,
          loading: _isLoading,
          saving: _isSaving,
          pickingImage: _isPickingImage,
          newPhoto: _pickedImage != null,
          error: _loadError,
          onRetry: _loadExistingVendorData,
          onFormChanged: () => setState(() {}),
          onCancel: _requestLeave,
          onSave: _saveStallProfile,
          onPreview: _preview,
          onCategoryChanged: (category, selected) => setState(() {
            if (selected) {
              _selectedCategories.add(category);
            } else {
              _selectedCategories.remove(category);
            }
          }),
          onScheduleChanged: (hours, closures) => setState(() {
            _weeklyHours = hours;
            _temporaryClosures = closures;
          }),
        ),
      );
}
