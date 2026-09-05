import 'package:flutter/material.dart';
import 'clay_container.dart';

class ClayTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const ClayTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final fieldBg = isDark ? const Color(0xFF131A29) : const Color(0xFFF1F5F9);

    return ClayContainer(
      isRecessed: true,
      depth: 8.0,
      borderRadius: 18.0,
      color: fieldBg,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        maxLength: maxLength,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          labelText: labelText,
          labelStyle: TextStyle(color: hintColor, fontSize: 13, fontWeight: FontWeight.w500),
          hintText: hintText,
          hintStyle: TextStyle(color: hintColor.withValues(alpha: 0.6), fontSize: 14),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
