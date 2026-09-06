import '../../shared/profile_page.dart';
import '../../auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../shared/faq_screen.dart';
import '../../shared/about_screen.dart';
import '../../shared/logout_helper.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _authService = AuthService();
  final _geocoding = Geocoding();

  UserModel? _userModel;
  bool _isLoading = true;

  String _locationText = 'Tap to find your current area';
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      if (mounted) {
        setState(() {
          _userModel = userData;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLocation() async {
    if (!mounted || _isLoadingLocation) { return; }
    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) { return; }
      if (!serviceEnabled) {
        setState(() {
          _locationText = 'Location services are turned off.';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) { return; }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = 'Location permission not granted.';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));

      // FIXED: use _geocoding.placemarkFromCoordinates
      final placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 8));
      final address =
          _formatPlacemark(placemarks.isNotEmpty ? placemarks.first : null);

      if (mounted) {
        setState(() {
          _locationText = address;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationText = 'Unable to fetch location.';
          _isLoadingLocation = false;
        });
      }
    }
  }

  String _formatPlacemark(Placemark? p) {
    if (p == null) { return 'Location unavailable'; }
    final parts = [p.subLocality, p.locality, p.administrativeArea]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Location unavailable' : parts.join(', ');
  }

  void _showEditProfileDialog() {
    final nameController =
        TextEditingController(text: _userModel?.fullName ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final user = FirebaseAuth.instance.currentUser;
                          final newName = nameController.text.trim();
                          if (user == null || newName.isEmpty) { return; }

                          setDialogState(() => isSaving = true);
                          final error = await _authService.updateFullName(
                              user.uid, newName);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (error == null) {
                            await _loadUserData(); // refresh header card
                          }

                          if (!mounted) { return; }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error ?? 'Profile updated.'),
                              backgroundColor:
                                  error != null ? Colors.red : Colors.green,
                            ),
                          );
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newPassword = passwordController.text.trim();
                          if (newPassword.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Password must be 6+ characters.')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          final error =
                              await _authService.changePassword(newPassword);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (!mounted) { return; }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  error ?? 'Password changed successfully.'),
                              backgroundColor:
                                  error != null ? Colors.red : Colors.green,
                            ),
                          );
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) { return const Center(child: CircularProgressIndicator()); }
    final user = FirebaseAuth.instance.currentUser;
    final guest = user?.isAnonymous ?? true;
    final name = guest ? 'Guest' : _userModel?.fullName.isNotEmpty == true
        ? _userModel!.fullName : user?.displayName ?? 'Your profile';
    return ProfilePage(
      name: name, email: guest ? '' : _userModel?.email ?? user?.email ?? '',
      photoUrl: guest ? null : user?.photoURL,
      isVendor: false, isGuest: guest,
      canChangePassword: user?.providerData.any((provider) => provider.providerId == 'password') ?? false,
      location: _locationText, isLoadingLocation: _isLoadingLocation,
      onRefresh: _loadUserData,
      onLocation: _loadLocation,
      onEdit: _showEditProfileDialog,
      onPassword: _showChangePasswordDialog,
      onFaq: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const FaqScreen(isVendor: false))),
      onAbout: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
      onLogout: () => confirmAndLogout(context, _authService),
      onSignIn: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      
    );
  }
}
