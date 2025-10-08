import 'package:flutter/material.dart';

class BuildCardWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget page;
  final double iconSize;
  final double fontSize;
  final Color iconColor;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final FontWeight fontWeight;
  final VoidCallback? onLongPress;

  const BuildCardWidget({
    Key? key,
    required this.icon,
    required this.label,
    required this.page,
    this.iconSize = 50,
    this.fontSize = 14,
    this.iconColor = Colors.deepPurple,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 12,
    this.fontWeight = FontWeight.bold,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      margin: const EdgeInsets.all(20),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Icon(icon, size: iconSize, color: iconColor),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}