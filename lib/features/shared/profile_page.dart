import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Grouped settings layout inspired by the supplied references.
class ProfilePage extends StatelessWidget {
  const ProfilePage(
      {super.key,
      required this.name,
      required this.email,
      this.photoUrl,
      this.phoneNumber,
      required this.isVendor,
      required this.isGuest,
      required this.canChangePassword,
      required this.location,
      required this.isLoadingLocation,
      required this.onRefresh,
      required this.onLocation,
      required this.onEdit,
      required this.onPassword,
      required this.onFaq,
      required this.onAbout,
      required this.onLogout,
      required this.onSignIn,
      required this.onNotificationSettings,
      required this.onPrivacyPolicy,
      required this.onTerms,
      required this.onDeleteAccount,
      this.onEditStall,
      this.onOrders,
      this.bookingSection,
      this.onPersonalInformation,
      this.onHomeLocation,
      this.onCustomLocation,
      this.homeLocation = 'Choose or save your home pin',
      this.customLocation = 'Manage your saved places'});

  final String name;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;
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
  final VoidCallback onNotificationSettings;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onTerms;
  final VoidCallback onDeleteAccount;
  final VoidCallback? onEditStall;
  final VoidCallback? onOrders;
  final Widget? bookingSection;
  final VoidCallback? onPersonalInformation;
  final VoidCallback? onHomeLocation;
  final VoidCallback? onCustomLocation;
  final String homeLocation;
  final String customLocation;

  static const background = Color(0xFFF3F2F8);
  static const _muted = Color(0xFF929294);
  static const _divider = Color(0xFFE7E7EA);

  // The avatar must never receive the full display name.
  String get _firstWord {
    final words =
        name.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.isEmpty ? 'Guest' : words.first;
  }

  Widget _fallbackPhoto() => Container(
      color: const Color(0xFFFFE8DB),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(9),
      child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(_firstWord,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC64B22)))));

  Widget _avatar() => ClipOval(
      child: SizedBox(
          width: 64,
          height: 64,
          child: photoUrl == null || photoUrl!.trim().isEmpty
              ? _fallbackPhoto()
              : Image.network(photoUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : _fallbackPhoto(),
                  errorBuilder: (_, __, ___) => _fallbackPhoto())));

  Widget _group(String label, List<Widget> rows) => Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
            child: Text(label,
                style: const TextStyle(
                    color: _muted, fontSize: 12, fontWeight: FontWeight.w400))),
        Material(
            clipBehavior: Clip.antiAlias,
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: Column(children: [
              for (var index = 0; index < rows.length; index++) ...[
                if (index > 0)
                  const Divider(height: .5, thickness: .5, color: _divider),
                rows[index],
              ],
            ])),
      ]));

  Widget _row(IconData icon, String label, VoidCallback onTap,
          {String? subtitle, Widget? trailing}) =>
      InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 49),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(children: [
              Icon(icon, color: _muted, size: 22),
              const SizedBox(width: 18),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Color(0xFF1C1C1E),
                          fontSize: 17,
                          height: 1.2,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.3,
                            color: _muted,
                            letterSpacing: 0)),
                  ],
                ],
              )),
              const SizedBox(width: 12),
              trailing ??
                  const Icon(CupertinoIcons.chevron_right,
                      color: Color(0xFFA5A5A7), size: 16),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: background,
        child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              children: [
                Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          _avatar(),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        height: 1.2,
                                        color: Color(0xFF1C1C1E),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0)),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(email,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: _muted,
                                          letterSpacing: 0)),
                                ],
                                if (isVendor &&
                                    phoneNumber?.isNotEmpty == true) ...[
                                  const SizedBox(height: 4),
                                  Text(phoneNumber!,
                                      style: const TextStyle(
                                          fontSize: 14, color: _muted)),
                                ],
                                const SizedBox(height: 8),
                                TextButton(
                                    onPressed: isGuest ? onSignIn : onEdit,
                                    style: TextButton.styleFrom(
                                        backgroundColor: background,
                                        foregroundColor: Colors.black,
                                        minimumSize: const Size(0, 32),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 7),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    child: Text(
                                        isGuest ? 'Sign in' : 'Edit Profile',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0))),
                              ])),
                          const SizedBox(width: 4),
                          IconButton(
                              tooltip: isGuest ? 'Sign in' : 'Edit profile',
                              onPressed: isGuest ? onSignIn : onEdit,
                              icon: const Icon(CupertinoIcons.chevron_right,
                                  color: Color(0xFFA5A5A7), size: 17),
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 48),
                              padding: EdgeInsets.zero),
                        ]))),
                if (bookingSection != null) bookingSection!,
                _group('LOCATION', [
                  _row(CupertinoIcons.location, 'Current location', onLocation,
                      subtitle: location,
                      trailing: isLoadingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : null),
                  if (onHomeLocation != null)
                    _row(CupertinoIcons.house, 'Home location', onHomeLocation!,
                        subtitle: homeLocation),
                  if (onCustomLocation != null)
                    _row(CupertinoIcons.map, 'Custom pins', onCustomLocation!,
                        subtitle: customLocation),
                ]),
                if (!isGuest)
                  _group(isVendor ? 'ACCOUNT & STALL' : 'ACCOUNT', [
                    _row(CupertinoIcons.person, 'Personal information',
                        onPersonalInformation ?? onEdit),
                    if (isVendor && onEditStall != null)
                      _row(Icons.storefront_outlined, 'My stall', onEditStall!),
                    if (onOrders != null)
                      _row(Icons.receipt_long_outlined, 'My bookings',
                          onOrders!),
                    if (canChangePassword)
                      _row(CupertinoIcons.lock, 'Change password', onPassword),
                    if (!isVendor)
                      _row(CupertinoIcons.bell, 'Notification settings',
                          onNotificationSettings),
                  ]),
                _group('ABOUT', [
                  _row(CupertinoIcons.question_circle, 'Help & FAQ', onFaq),
                  _row(CupertinoIcons.info, 'About StallSeeker', onAbout),
                  _row(
                      CupertinoIcons.shield, 'Privacy policy', onPrivacyPolicy),
                  _row(CupertinoIcons.doc_text, 'Terms of use', onTerms),
                ]),
                if (!isGuest)
                  _group('ACCOUNT ACTIONS', [
                    _row(CupertinoIcons.trash, 'Delete account',
                        onDeleteAccount),
                  ]),
                const SizedBox(height: 32),
                Material(
                    clipBehavior: Clip.antiAlias,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: _row(CupertinoIcons.square_arrow_right,
                        isGuest ? 'Leave guest mode' : 'Logout', onLogout,
                        trailing: const SizedBox.shrink())),
                const SizedBox(height: 40),
                const Icon(Icons.storefront_outlined, size: 36, color: _muted),
                const SizedBox(height: 10),
                const Text('StallSeeker',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: _muted, letterSpacing: 0)),
              ],
            )),
      );
}
