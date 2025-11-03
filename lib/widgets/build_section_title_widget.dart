import 'package:flutter/material.dart';

/// 🔹 Widget de titre de section réutilisable
/// pour garder une cohérence visuelle dans toute l’app.
class BuildSectionTitleWidget extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? color;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;

  const BuildSectionTitleWidget({
    super.key,
    required this.title,
    this.icon,
    this.color = Colors.brown,
    this.fontSize = 20,
    this.fontWeight = FontWeight.bold,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = color ?? theme.colorScheme.primary;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: displayColor),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: displayColor,
            ),
          ),
        ],
      ),
    );
  }
}
