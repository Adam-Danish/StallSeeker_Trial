import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';

/// iOS-style grouped settings, with StallSeeker's existing account actions.
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
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
    this.customLocation = 'Manage your saved places',
  });

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

  static const background = AppColors.background;
  static const accent = AppColors.primary;
  static const muted = Color(0xFF8E8E93);
  static const divider = Color(0xFFE5E5E8);

  String get _initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }

  Widget _avatar() => ClipOval(
        child: SizedBox(
          width: 100,
          height: 100,
          child: photoUrl == null || photoUrl!.trim().isEmpty
              ? const ColoredBox(
                  color: Color(0xFFF3DED1),
                  child:
                      Icon(CupertinoIcons.person_fill, size: 60, color: accent),
                )
              : Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(_initial,
                        style: const TextStyle(fontSize: 45, color: accent)),
                  ),
                ),
        ),
      );

  Widget _header() {
    final contact = [
      if (phoneNumber?.trim().isNotEmpty == true) phoneNumber!.trim(),
      if (email.trim().isNotEmpty) email.trim(),
    ].join(' · ');
    return Column(children: [
      SizedBox(
        height: 116,
        child: Stack(alignment: Alignment.topCenter, children: [
          Positioned(top: 12, child: _avatar()),
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: Colors.white,
              shape: const StadiumBorder(),
              elevation: 5,
              shadowColor: const Color(0x18000000),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: isGuest ? onSignIn : onEdit,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
                  child: Text(isGuest ? 'Sign in' : 'Edit',
                      style:
                          const TextStyle(fontSize: 17, color: Colors.black)),
                ),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 9),
      Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.1,
          letterSpacing: -0.6,
          color: Colors.black,
        ),
      ),
      if (contact.isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(
          contact,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, height: 1.2, color: muted),
        ),
      ],
    ]);
  }

  Widget _group(List<Widget> rows) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.only(left: 60, right: 16),
                child: Divider(height: .5, thickness: .5, color: divider),
              ),
            rows[index],
          ],
        ]),
      );

  Widget _row(
    IconData icon,
    Color iconColor,
    String label,
    VoidCallback onTap, {
    String? value,
    String? subtitle,
    Widget? trailing,
  }) =>
      InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: iconColor == AppColors.primary
                      ? AppColors.logoGradient
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(Colors.white, iconColor, .78)!,
                            iconColor,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17,
                          height: 1.2,
                          letterSpacing: -0.2,
                          color: Colors.black),
                    ),
                    if (subtitle != null)
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: muted)),
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, color: muted)),
                ),
              ],
              const SizedBox(width: 8),
              trailing ??
                  const Icon(CupertinoIcons.chevron_right,
                      size: 17, color: Color(0xFFB6B6B8)),
            ]),
          ),
        ),
      );

  Widget _editAction() => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isGuest ? onSignIn : onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
            child: Row(children: [
              const Icon(CupertinoIcons.camera_on_rectangle,
                  color: accent, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  isGuest ? 'Sign in to edit profile' : 'Edit Profile',
                  style: const TextStyle(fontSize: 17, color: accent),
                ),
              ),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .28, .6],
              colors: [Colors.white, background, background],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 116),
                children: [
                  _header(),
                  const SizedBox(height: 45),
                  _editAction(),
                  const SizedBox(height: 24),
                  if (!isGuest) ...[
                    _group([
                      _row(
                          CupertinoIcons.person_crop_circle_fill,
                          const Color(0xFFFF5956),
                          'My Profile',
                          onPersonalInformation ?? onEdit),
                    ]),
                    const SizedBox(height: 24),
                  ],
                  if (bookingSection != null) ...[
                    bookingSection!,
                    const SizedBox(height: 24),
                  ],
                  _group([
                    _row(CupertinoIcons.location_solid, const Color(0xFF43CE72),
                        'Current Location', onLocation,
                        subtitle: location,
                        trailing: isLoadingLocation
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null),
                    if (onHomeLocation != null)
                      _row(CupertinoIcons.house_fill, AppColors.primary,
                          'Home location', onHomeLocation!),
                    if (onCustomLocation != null)
                      _row(CupertinoIcons.map_fill, AppColors.primaryLight,
                          'Custom pins', onCustomLocation!),
                    if (isVendor && onEditStall != null)
                      _row(CupertinoIcons.bag_fill, const Color(0xFFFFAE22),
                          'My Stall', onEditStall!),
                    if (onOrders != null)
                      _row(CupertinoIcons.square_list_fill,
                          const Color(0xFFFFAE22), 'My Bookings', onOrders!),
                  ]),
                  if (!isGuest) ...[
                    const SizedBox(height: 24),
                    _group([
                      _row(CupertinoIcons.bell_fill, const Color(0xFFFF5555),
                          'Notifications and Sounds', onNotificationSettings),
                      _row(CupertinoIcons.lock_fill, const Color(0xFF949499),
                          'Privacy Policy', onPrivacyPolicy),
                      _row(CupertinoIcons.doc_text_fill,
                          const Color(0xFF42C96D), 'Terms of Use', onTerms),
                      if (canChangePassword)
                        _row(
                            CupertinoIcons.padlock_solid,
                            AppColors.primaryLight,
                            'Change password',
                            onPassword),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  _group([
                    _row(CupertinoIcons.question_circle_fill,
                        const Color(0xFFAD55E8), 'Help & FAQ', onFaq),
                    _row(CupertinoIcons.info_circle_fill,
                        const Color(0xFF8288EF), 'About StallSeeker', onAbout),
                  ]),
                  if (!isGuest) ...[
                    const SizedBox(height: 24),
                    _group([
                      _row(CupertinoIcons.trash_fill, const Color(0xFFFF5956),
                          'Delete account', onDeleteAccount),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  _group([
                    _row(
                        CupertinoIcons.square_arrow_right,
                        const Color(0xFF949499),
                        isGuest ? 'Leave guest mode' : 'Logout',
                        onLogout),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
}
