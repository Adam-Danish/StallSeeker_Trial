import 'package:flutter/material.dart';

/// The white pill action used by Edit Profile and page navigation.
class AppTopAction extends StatelessWidget {
  const AppTopAction(
      {super.key, required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  static const textStyle = TextStyle(fontSize: 17, color: Colors.black);

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onTap != null,
        label: icon == null ? null : label,
        child: Material(
          color: Colors.white,
          elevation: 4,
          shadowColor: const Color(0x14000000),
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: icon == null
                    ? Text(label,
                        textAlign: TextAlign.center,
                        style: textStyle.copyWith(
                            color:
                                onTap == null ? Colors.black38 : Colors.black))
                    : Icon(icon,
                        size: 22,
                        color: onTap == null ? Colors.black38 : Colors.black),
              ),
            ),
          ),
        ),
      );
}
