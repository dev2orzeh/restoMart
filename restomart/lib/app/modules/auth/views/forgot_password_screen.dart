/// Forgot Password Screen — matches PDF Page 5.
///
/// - "Enter your e-mail" heading
/// - "Let's reset your password" subtitle
/// - Email field with validation check icon
/// - "Send" button
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends GetView<AuthController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH,
          ),
          child: Form(
            key: controller.forgotFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.spacingMd),

                // ── Back Button ─────────────────────────────────
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),

                const SizedBox(height: AppDimensions.spacingXxl),

                // ── Title ───────────────────────────────────────
                Text(
                  AppStrings.forgotPasswordTitle,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingXs),

                // ── Subtitle ────────────────────────────────────
                Text(
                  AppStrings.forgotPasswordSubtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingXxl),

                // ── Phone Field ─────────────────────────────────
                CustomTextField(
                  controller: controller.forgotEmailController, // Still using this controller for now, will repurpose
                  hintText: 'Enter your phone number (e.g. +923001234567)',
                  prefixIcon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                  suffixIcon: GetBuilder<AuthController>(builder: (c) {
                    // Show golden check when phone is valid.
                    final phone = c.forgotEmailController.text.trim();
                    if (phone.length >= 10) {
                      return const Icon(
                        Icons.check_circle,
                        color: AppColors.accent,
                        size: AppDimensions.iconLg,
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!RegExp(r'^\+[1-9]\d{9,14}$').hasMatch(value.trim())) {
                      return 'Must include country code (e.g. +923001234567)';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    // Trigger rebuild for the suffix icon.
                    controller.update();
                  },
                ),

                const SizedBox(height: AppDimensions.spacingXl),

                // ── Send Button ─────────────────────────────────
                Obx(() => PrimaryButton(
                      text: AppStrings.send,
                      onPressed: controller.sendForgotPasswordOtp,
                      isLoading: controller.isLoading.value,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
