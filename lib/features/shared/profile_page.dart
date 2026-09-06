import 'package:flutter/material.dart';

/// Grouped settings layout inspired by the supplied references.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.name, required this.email,
    this.photoUrl, required this.isVendor, required this.isGuest,
    required this.canChangePassword, required this.location,
    required this.isLoadingLocation, required this.onRefresh,
    required this.onLocation, required this.onEdit, required this.onPassword,
    required this.onFaq, required this.onAbout, required this.onLogout,
    required this.onSignIn, this.onEditStall});

  final String name;
  final String email;
  final String? photoUrl;
  final bool isVendor;
  final bool isGuest;
  final bool canChangePassword;
  final String location;
  final bool isLoadingLocation;
  final Future<void> Function() onRefresh;
  final VoidCallback onLocation;
  final VoidCallback onEdit;
  final VoidCallback onPassword;
  final VoidCallback onFaq;
  final VoidCallback onAbout;
  final VoidCallback onLogout;
  final VoidCallback onSignIn;
  final VoidCallback? onEditStall;

  static const _background = Color(0xFFF2F2F7);
  static const _muted = Color(0xFF8E8E93);
  static const _divider = Color(0xFFE5E5EA);

  // The avatar must never receive the full display name.
  String get _firstWord {
    final words = name.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.isEmpty ? 'Guest' : words.first;
  }

  Widget _fallbackPhoto() => Container(color: const Color(0xFFFFE8DB), alignment: Alignment.center,
    padding: const EdgeInsets.all(9),
    child: FittedBox(fit: BoxFit.scaleDown, child: Text(_firstWord,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFC64B22)))));

  Widget _avatar() => ClipOval(child: SizedBox(width: 64, height: 64,
    child: photoUrl == null || photoUrl!.trim().isEmpty ? _fallbackPhoto()
        : Image.network(photoUrl!, fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null ? child : _fallbackPhoto(),
            errorBuilder: (_, __, ___) => _fallbackPhoto())));

  Widget _group(String label, List<Widget> rows) => Padding(padding: const EdgeInsets.only(top: 28),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        child: Text(label, style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w400))),
      Container(clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const Divider(height: .5, thickness: .5, color: _divider),
            rows[index],
          ],
        ])),
    ]));

  Widget _row(IconData icon, String label, VoidCallback onTap, {String? subtitle, Widget? trailing}) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    leading: Icon(icon, color: _muted, size: 24),
    title: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: 0)),
    subtitle: subtitle == null ? null : Padding(padding: const EdgeInsets.only(top: 3),
      child: Text(subtitle, style: const TextStyle(fontSize: 14, color: _muted, letterSpacing: 0))),
    trailing: trailing ?? const Icon(Icons.chevron_right, color: Color(0xFFAEAEB2), size: 22),
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) => ColoredBox(color: _background,
    child: RefreshIndicator(onRefresh: onRefresh, child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40), children: [
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            _avatar(), const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0)),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(fontSize: 14, color: _muted, letterSpacing: 0)),
              ],
              const SizedBox(height: 8),
              TextButton(onPressed: isGuest ? onSignIn : onEdit,
                style: TextButton.styleFrom(backgroundColor: _background, foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(isGuest ? 'Sign in' : 'Edit Profile', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0))),
            ])),
            const SizedBox(width: 4),
            IconButton(tooltip: isGuest ? 'Sign in' : 'Edit profile',
              onPressed: isGuest ? onSignIn : onEdit,
              icon: const Icon(Icons.chevron_right, color: Color(0xFFAEAEB2)),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 48), padding: EdgeInsets.zero),
          ])),
        _group('LOCATION', [
          _row(Icons.location_on_outlined, 'Current location', onLocation, subtitle: location,
            trailing: isLoadingLocation
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right, color: Color(0xFFAEAEB2))),
        ]),
        if (!isGuest) _group(isVendor ? 'ACCOUNT & STALL' : 'ACCOUNT', [
          _row(Icons.person_outline_rounded, 'Personal information', onEdit),
          if (isVendor && onEditStall != null) _row(Icons.storefront_outlined, 'My stall', onEditStall!),
          if (canChangePassword) _row(Icons.lock_outline_rounded, 'Change password', onPassword),
        ]),
        _group('ABOUT', [
          _row(Icons.help_outline_rounded, 'Help & FAQ', onFaq),
          _row(Icons.info_outline_rounded, 'About StallSeeker', onAbout),
        ]),
        const SizedBox(height: 28),
        Container(clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: _row(Icons.logout_rounded, isGuest ? 'Leave guest mode' : 'Logout', onLogout,
            trailing: const SizedBox.shrink())),
        const SizedBox(height: 36),
        const Icon(Icons.storefront_outlined, size: 32, color: Color(0xFFAEAEB2)),
        const SizedBox(height: 8),
        const Text('StallSeeker', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _muted, letterSpacing: 0)),
      ],
    )),
  );
}
