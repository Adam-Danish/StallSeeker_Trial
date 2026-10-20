import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar(
      {super.key, required this.name, this.photoUrl, this.size = 100});

  final String name;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: photoUrl == null || photoUrl!.trim().isEmpty
              ? const ColoredBox(
                  color: AppColors.mint,
                  child: Icon(CupertinoIcons.person_fill,
                      size: 58, color: AppColors.primary),
                )
              : Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: AppColors.mint,
                    child: Icon(CupertinoIcons.person_fill,
                        size: 58, color: AppColors.primary),
                  ),
                ),
        ),
      );
}

class ProfileTopAction extends StatelessWidget {
  const ProfileTopAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: const Color(0x14000000),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: icon == null
                ? Text(label,
                    style: const TextStyle(fontSize: 17, color: Colors.black))
                : Icon(icon, size: 22, color: Colors.black),
          ),
        ),
      );
}
