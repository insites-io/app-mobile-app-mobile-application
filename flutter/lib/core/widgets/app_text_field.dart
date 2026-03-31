import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

/// App-styled text field with label. Used for forms across sign in, sign up, etc.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.placeholder,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.onChanged,
    this.suffixIcon,
  });

  final String label;
  final String? placeholder;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            suffixIcon: suffixIcon,
            hintText: placeholder ?? label,
          ),
        ),
      ],
    );
  }
}
