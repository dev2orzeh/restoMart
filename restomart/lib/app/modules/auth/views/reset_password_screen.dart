/// Reset Password Screen — matches PDF Page 7.
///
/// - "Enter a new password" heading
/// - Masked email subtitle
/// - New Password field with visibility toggle
/// - Confirm Password field with visibility toggle
/// - Password requirements checklist (live validation)
/// - "Confirm Password" button
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../controllers/auth_controller.dart';

class ResetPasswordScreen extends GetView<AuthController> {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH,
          ),
          child: Form(
            key: controller.resetFormKey,
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
                  AppStrings.resetPasswordTitle,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingXs),

                // ── Subtitle ────────────────────────────────────
                Obx(() => RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          const TextSpan(text: AppStrings.otpSubtitle),
                          TextSpan(
                            text: controller.maskedEmail.value,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: AppDimensions.spacingXxl),

                // ── New Password Label ──────────────────────────
                Text(
                  AppStrings.newPassword,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXs),

                // ── New Password Field ──────────────────────────
                Obx(() => CustomTextField(
                      controller: controller.newPasswordController,
                      prefixIcon: Icons.lock_outline,
                      obscureText: !controller.isNewPasswordVisible.value,
                      suffixIcon: IconButton(
                        onPressed: controller.toggleNewPasswordVisibility,
                        icon: Icon(
                          controller.isNewPasswordVisible.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.primary,
                          size: AppDimensions.iconMd,
                        ),
                      ),
                      onChanged: controller.validatePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new password';
                        }
                        return null;
                      },
                    )),

                const SizedBox(height: AppDimensions.spacingMd),

                // ── Confirm Password Label ──────────────────────
                Text(
                  AppStrings.confirmNewPassword,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXs),

                // ── Confirm Password Field ──────────────────────
                Obx(() => CustomTextField(
                      controller: controller.confirmPasswordController,
                      prefixIcon: Icons.lock_outline,
                      obscureText: !controller.isConfirmPasswordVisible.value,
                      suffixIcon: IconButton(
                        onPressed: controller.toggleConfirmPasswordVisibility,
                        icon: Icon(
                          controller.isConfirmPasswordVisible.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.primary,
                          size: AppDimensions.iconMd,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != controller.newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    )),

                const SizedBox(height: AppDimensions.spacingLg),

                // ── Password Requirements ───────────────────────
                Obx(() => Column(
                      children: [
                        _PasswordRequirement(
                          text: AppStrings.passwordReq8Chars,
                          isMet: controller.hasMinLength.value,
                        ),
                        const SizedBox(height: AppDimensions.spacingXs),
                        _PasswordRequirement(
                          text: AppStrings.passwordReqCase,
                          isMet: controller.hasUpperAndLower.value,
                        ),
                        const SizedBox(height: AppDimensions.spacingXs),
                        _PasswordRequirement(
                          text: AppStrings.passwordReqSymbol,
                          isMet: controller.hasNumberOrSymbol.value,
                        ),
                      ],
                    )),

                const SizedBox(height: AppDimensions.spacingXxl),

                // ── Confirm Button ──────────────────────────────
                Obx(() => PrimaryButton(
                      text: AppStrings.confirmPassword,
                      onPressed: controller.resetPassword,
                      isLoading: controller.isLoading.value,
                    )),

                const SizedBox(height: AppDimensions.spacingXxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Single password requirement row with check/cross icon.
class _PasswordRequirement extends StatelessWidget {
  final String text;
  final bool isMet;

  const _PasswordRequirement({
    required this.text,
    required this.isMet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_outline : Icons.cancel_outlined,
          size: 18,
          color: isMet ? AppColors.success : AppColors.textHint,
        ),
        const SizedBox(width: AppDimensions.spacingXs),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: isMet ? AppColors.success : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
