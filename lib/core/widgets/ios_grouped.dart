import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 32,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .26),
          gradient: color == AppColors.primary
              ? AppColors.logoGradient
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(Colors.white, color, .78)!,
                    color,
                  ],
                ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * .65,
        ),
      );
}

class AppGroupedCard extends StatelessWidget {
  const AppGroupedCard({
    super.key,
    required this.children,
    this.dividerIndent = 60,
  });

  final List<Widget> children;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: .5,
                  thickness: .5,
                  indent: dividerIndent,
                  endIndent: 16,
                  color: AppColors.border,
                ),
              children[i],
            ],
          ],
        ),
      );
}
