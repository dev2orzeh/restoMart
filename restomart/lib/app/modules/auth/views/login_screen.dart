/// Login Screen — matches PDF Page 4 exactly.
///
/// Layout from the PDF:
/// - RestoMart logo (centered, top)
/// - "Login to continue" heading
/// - Email field (with mail icon)
/// - Password field (with lock icon + visibility toggle)
/// - "Forgot password?" link (right-aligned)
/// - "Login" primary button
/// - "OR" divider
/// - "Sign in with Google" button
/// - "Sign in with Facebook" button
/// - "Don't have an account? Create Account" at bottom
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/restomart_logo.dart';
import '../../../widgets/social_login_button.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Light status bar for white background.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH,
          ),
          child: Form(
            key: controller.loginFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.spacing3xl),

                // ── Logo ──────────────────────────────────────────
                const Center(
                  child: RestoMartLogo(
                    size: AppDimensions.logoSizeLogin,
                    showText: true,
                    martColor: AppColors.primary,
                  ),
                ),

                const SizedBox(height: AppDimensions.spacing3xl),

                // ── Title ─────────────────────────────────────────
                Text(
                  AppStrings.loginTitle,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingXl),

                // ── Email Field ───────────────────────────────────
                CustomTextField(
                  controller: controller.loginEmailController,
                  hintText: AppStrings.loginEmailHint,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value.trim())) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimensions.spacingMd),

                // ── Password Field ────────────────────────────────
                Obx(() => CustomTextField(
                      controller: controller.loginPasswordController,
                      hintText: AppStrings.loginPasswordHint,
                      obscureText: !controller.isPasswordVisible.value,
                      suffixIcon: IconButton(
                        onPressed: controller.togglePasswordVisibility,
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.primary,
                          size: AppDimensions.iconMd,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    )),

                const SizedBox(height: AppDimensions.spacingXs),

                // ── Forgot Password ───────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: controller.goToForgotPassword,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      AppStrings.forgotPassword,
                      style: AppTextStyles.link.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingXl),

                // ── Login Button ──────────────────────────────────
                Obx(() => PrimaryButton(
                      text: AppStrings.loginButton,
                      onPressed: controller.login,
                      isLoading: controller.isLoading.value,
                    )),

                const SizedBox(height: AppDimensions.spacingLg),

                // ── OR Divider ────────────────────────────────────
                const _OrDivider(),

                const SizedBox(height: AppDimensions.spacingLg),

                // ── Google Sign In ────────────────────────────────
                SocialLoginButton(
                  text: AppStrings.signInGoogle,
                  icon: Image.network(
                    'https://www.google.com/favicon.ico',
                    width: 24,
                    height: 24,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.g_mobiledata,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                  onPressed: controller.signInWithGoogle,
                ),



                const SizedBox(height: AppDimensions.spacingXxl),

                // ── Create Account Link ───────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.noAccount,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.goToRegister,
                        child: Text(
                          AppStrings.createAccount,
                          style: AppTextStyles.link.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingXl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "OR" divider with horizontal lines on both sides.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
          ),
          child: Text(AppStrings.or, style: AppTextStyles.dividerText),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}
