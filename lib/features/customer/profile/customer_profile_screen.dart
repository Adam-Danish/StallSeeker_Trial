import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _newPasswordController = TextEditingController();

  UserModel? _userModel;
  bool _isLoading = true;
  bool _isSavingName = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      if (mounted) {
        setState(() {
          _userModel = userData;
          _nameController.text = userData?.fullName ?? '';
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }

    setState(() => _isSavingName = true);

    final error = await _authService.updateFullName(user.uid, newName);

    if (mounted) {
      setState(() => _isSavingName = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Name updated.'),
          backgroundColor: error != null ? Colors.red : Colors.green,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text.trim();
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be 6+ characters.')),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    final error = await _authService.changePassword(newPassword);

    if (mounted) {
      setState(() => _isChangingPassword = false);
      if (error == null) {
        _newPasswordController.clear();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Password changed successfully.'),
          backgroundColor: error != null ? Colors.red : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Account info (read-only)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account Info',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text('Email: ${_userModel?.email ?? "N/A"}'),
                const SizedBox(height: 4),
                Text('Role: ${_userModel?.role ?? "N/A"}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Edit name
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Name',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSavingName ? null : _saveName,
                    child: _isSavingName
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Name'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Change password
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Change Password',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isChangingPassword ? null : _changePassword,
                    child: _isChangingPassword
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Change Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ),
      ],
    );
  }
}
