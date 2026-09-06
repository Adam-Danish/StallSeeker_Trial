import '../../shared/profile_page.dart';
import '../../shared/edit_profile_screen.dart';
import '../../shared/personal_information_screen.dart';
import '../../shared/change_password_screen.dart';
import '../../shared/notification_settings_screen.dart';
import '../../shared/legal_screen.dart';
import '../../shared/delete_account_screen.dart';
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

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => EditProfileScreen(
        name: _userModel?.fullName ?? user?.displayName ?? '',
        email: _userModel?.email ?? user?.email ?? '')));
    if (saved == true && mounted) {
      await _loadUserData();
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.'))); }
    }
  }

  Future<void> _personalInformation() async {
    final user = FirebaseAuth.instance.currentUser;
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => PersonalInformationScreen(
        name: _userModel?.fullName ?? user?.displayName ?? '',
        email: _userModel?.email ?? user?.email ?? '',
        isVendor: false)));
    if (mounted) { await _loadUserData(); }
  }

  void _changePassword() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangePasswordScreen(
        email: _userModel?.email ?? FirebaseAuth.instance.currentUser?.email ?? '')));
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
      onEdit: _editProfile,
      onPersonalInformation: _personalInformation,
      onPassword: _changePassword,
      onFaq: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const FaqScreen(isVendor: false))),
      onAbout: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
      onNotificationSettings: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
      onPrivacyPolicy: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const LegalScreen(page: LegalPage.privacy))),
      onTerms: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const LegalScreen(page: LegalPage.terms))),
      onDeleteAccount: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const DeleteAccountScreen())),
      onLogout: () => confirmAndLogout(context, _authService),
      onSignIn: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      
    );
  }
}
