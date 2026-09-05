import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Shared account presentation. Callers keep their existing authentication,
/// editing, and location actions; this widget does not own account data.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.name, required this.email,
    required this.isVendor, required this.isGuest, required this.canChangePassword,
    required this.location, required this.isLoadingLocation, required this.onRefresh,
    required this.onLocation, required this.onEdit, required this.onPassword,
    required this.onFaq, required this.onAbout, required this.onLogout,
    required this.onSignIn, this.onEditStall});

  final String name;
  final String email;
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

  static const _ink = Color(0xFF17202D);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFEDF0F3);

  String get _initials {
    final words = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2);
    final initials = words.map((part) => String.fromCharCode(part.runes.first)).join().toUpperCase();
    return initials.isEmpty ? 'S' : initials;
  }

  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
        child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _muted))),
      Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line)),
        child: Column(children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 68, endIndent: 16, color: _line),
            children[i],
          ],
        ])),
    ],
  );

  Widget _action({required IconData icon, required String title, required String subtitle,
      required VoidCallback onTap, Color accent = AppColors.primary, Widget? trailing}) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    leading: Container(width: 40, height: 40,
      decoration: BoxDecoration(color: accent.withValues(alpha: .09), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: accent, size: 21)),
    title: Text(title, style: const TextStyle(fontSize: 14, color: _ink, fontWeight: FontWeight.w600)),
    subtitle: Padding(padding: const EdgeInsets.only(top: 3),
      child: Text(subtitle, style: const TextStyle(fontSize: 12, color: _muted))),
    trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20, color: _muted),
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF7F8FA),
    child: RefreshIndicator(onRefresh: onRefresh,
      child: ListView(physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
          Container(padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFFFFF2E9), borderRadius: BorderRadius.circular(24)),
            child: Column(children: [
              Container(width: 80, height: 80, alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD8C4), width: 3)),
                child: Text(_initials, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFFC64B22)))),
              const SizedBox(height: 14),
              Text(name, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink, height: 1.25)),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(email, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _muted)),
              ],
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isVendor ? Icons.storefront_outlined : Icons.person_outline_rounded,
                    size: 14, color: const Color(0xFFC64B22)),
                  const SizedBox(width: 5),
                  Text(isGuest ? 'Guest' : isVendor ? 'Vendor account' : 'Customer account',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFC64B22), fontWeight: FontWeight.w600)),
                ])),
              const SizedBox(height: 16),
              OutlinedButton.icon(onPressed: isGuest ? onSignIn : onEdit,
                style: OutlinedButton.styleFrom(backgroundColor: Colors.white,
                  foregroundColor: _ink, side: const BorderSide(color: Color(0xFFFFD8C4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: Icon(isGuest ? Icons.login_rounded : Icons.edit_outlined, size: 16),
                label: Text(isGuest ? 'Sign in to your account' : 'Edit profile')),
            ])),
          _section('Your area', [
            _action(icon: Icons.near_me_outlined, title: 'Current location', subtitle: location,
              accent: const Color(0xFF147D68), onTap: onLocation,
              trailing: isLoadingLocation
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, color: _muted, size: 20)),
          ]),
          if (!isGuest) _section(isVendor ? 'Account & business' : 'Account', [
            _action(icon: Icons.person_outline_rounded, title: 'Personal information',
              subtitle: 'Update your display name', onTap: onEdit),
            if (isVendor && onEditStall != null)
              _action(icon: Icons.storefront_outlined, title: 'My stall',
                subtitle: 'Photos, opening hours and stall information', onTap: onEditStall!),
            if (canChangePassword)
              _action(icon: Icons.lock_outline_rounded, title: 'Password & security',
                subtitle: 'Change your account password', onTap: onPassword, accent: const Color(0xFF6260BF)),
          ]),
          _section('Help & information', [
            _action(icon: Icons.help_outline_rounded, title: 'Help centre',
              subtitle: 'Answers to common questions', onTap: onFaq, accent: const Color(0xFF4774B8)),
            _action(icon: Icons.info_outline_rounded, title: 'About StallSeeker',
              subtitle: 'Get to know the app', onTap: onAbout, accent: const Color(0xFF4774B8)),
          ]),
          const SizedBox(height: 24),
          OutlinedButton.icon(onPressed: onLogout,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50),
              foregroundColor: const Color(0xFFB42318), side: const BorderSide(color: Color(0xFFF1D4D0)),
              backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            icon: const Icon(Icons.logout_rounded, size: 18), label: Text(isGuest ? 'Leave guest mode' : 'Log out')),
          const SizedBox(height: 18),
          const Text('StallSeeker', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
        ]),
    ),
  );
}
