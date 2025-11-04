import 'package:flutter/material.dart';

/// Widget réutilisable pour une cellule éditable dans un tableau (ex: stock)
class BuildEditableCellWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmit;
  final bool enabled;
  final String? hintText;
  final Color? fillColor;
  final IconData? prefixIcon;

  const BuildEditableCellWidget({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.enabled = true,
    this.hintText,
    this.fillColor,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: enabled ? colorScheme.onSurface : Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor:
              fillColor ?? colorScheme.surfaceVariant.withOpacity(enabled ? 0.2 : 0.1),
          hintText: hintText,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 18, color: Colors.grey.shade600)
              : null,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: colorScheme.outline.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: colorScheme.primary.withOpacity(0.8),
              width: 1.5,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        onSubmitted: onSubmit,
      ),
    );
  }
}
