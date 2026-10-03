/// Custom text field matching the PDF's input design.
///
/// Rounded border, optional leading icon (mail, lock), optional
/// suffix icon (visibility toggle, validation check), and hint text.
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../core/constants/app_text_styles.dart';

class CustomTextField extends StatelessWidget {
  final String? hintText;
  final String? labelText;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    this.hintText,
    this.labelText,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      focusNode: focusNode,
      style: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        hintStyle: AppTextStyles.hint,
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(
                  left: AppDimensions.inputPaddingH,
                  right: AppDimensions.spacingXs,
                ),
                child: Icon(
                  prefixIcon,
                  color: AppColors.primary,
                  size: AppDimensions.iconMd,
                ),
              )
            : null,
        prefixIconConstraints: prefixIcon != null
            ? const BoxConstraints(minWidth: 48, minHeight: 0)
            : null,
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(
                  right: AppDimensions.spacingXs,
                ),
                child: suffixIcon,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.inputPaddingH,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.textHint, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}
