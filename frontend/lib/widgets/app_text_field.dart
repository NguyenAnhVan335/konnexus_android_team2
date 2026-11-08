import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ô nhập liệu dùng chung: nhãn phía trên, viền/bo góc lấy từ Theme.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.suffix,
    this.maxLength,
    this.showCounter = false,
    this.focusNode,
    this.readOnly = false,
    this.onTap,
    this.helperText,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int? maxLength;
  final bool showCounter;
  final FocusNode? focusNode;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? helperText;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(label!, style: AppTextStyles.label),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          minLines: minLines,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          enabled: enabled,
          maxLength: maxLength,
          focusNode: focusNode,
          readOnly: readOnly,
          onTap: onTap,
          autofillHints: autofillHints,
          style: const TextStyle(fontSize: 14.5),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            helperMaxLines: 2,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 19),
            suffixIcon: suffix,
            counterText: showCounter ? null : '',
          ),
        ),
      ],
    );
  }
}
