/// Registration Screen — matches PDF Page 3.
///
/// Fields: Full Name, Email, Phone Number, Gender (dropdown),
/// Date of Birth (date picker), Terms & Conditions checkbox,
/// Create Account button, social sign-up, and login link.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/social_login_button.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends GetView<AuthController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH,
          ),
          child: Form(
            key: controller.registerFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.spacingMd),

                // ── Back Button ─────────────────────────────────
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.primary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),

                const SizedBox(height: AppDimensions.spacingLg),

                // ── Title ───────────────────────────────────────
                Text(
                  AppStrings.registerTitle,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingXl),

                // ── Full Name ───────────────────────────────────
                CustomTextField(
                  controller: controller.registerNameController,
                  hintText: AppStrings.fullName,
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimensions.spacingMd),

                // ── Email Field ───────────────────────────────────
                CustomTextField(
                  controller: controller.registerEmailController,
                  hintText: 'Email',
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

                // ── Phone Number ────────────────────────────────
                // ── Phone Number Field ────────────────────────────
                CustomTextField(
                  controller: controller.registerPhoneController,
                  hintText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimensions.spacingMd),

                // ── Restaurant Name ────────────────────────────
                CustomTextField(
                  controller: controller.registerRestaurantNameController,
                  hintText: 'Restaurant / Business Name',
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your restaurant name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimensions.spacingMd),

                // ── Restaurant Address ────────────────────────────
                CustomTextField(
                  controller: controller.registerRestaurantAddressController,
                  hintText: 'Restaurant Address (e.g. Gulberg III, Lahore)',
                  keyboardType: TextInputType.streetAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your restaurant address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimensions.spacingMd),

                // ── Password ────────────────────────────────────
                Obx(() => CustomTextField(
                      controller: controller.registerPasswordController,
                      hintText: 'Password',
                      obscureText: !controller.isPasswordVisible.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: AppDimensions.iconMd,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                      onChanged: controller.validatePassword,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    )),

                const SizedBox(height: AppDimensions.spacingSm),

                // ── Password Validation Checklist ──────────────────
                Obx(() => Column(
                      children: [
                        _buildValidationRow(
                          AppStrings.passwordReq8Chars,
                          controller.hasMinLength.value,
                        ),
                        const SizedBox(height: 4),
                        _buildValidationRow(
                          AppStrings.passwordReqSymbol,
                          controller.hasNumberOrSymbol.value,
                        ),
                      ],
                    )),

                const SizedBox(height: AppDimensions.spacingMd),

                // ── Confirm Password ────────────────────────────
                Obx(() => CustomTextField(
                      controller: controller.registerConfirmPasswordController,
                      hintText: AppStrings.confirmPassword,
                      obscureText: !controller.isConfirmPasswordVisible.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isConfirmPasswordVisible.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: AppDimensions.iconMd,
                        ),
                        onPressed: controller.toggleConfirmPasswordVisibility,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != controller.registerPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    )),

                const SizedBox(height: AppDimensions.spacingMd),

                // ── Gender Dropdown ─────────────────────────────
                Obx(() => DropdownButtonFormField<String>(
                      initialValue: controller.selectedGender.value,
                      hint: Text(AppStrings.gender, style: AppTextStyles.hint),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.textHint,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.inputPaddingH,
                          vertical: 16,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: controller.setGender,
                    )),

                const SizedBox(height: AppDimensions.spacingMd),

                // ── Date of Birth ───────────────────────────────
                Obx(() => CustomTextField(
                      hintText: controller.selectedDateOfBirth.value != null
                          ? '${controller.selectedDateOfBirth.value!.day}/${controller.selectedDateOfBirth.value!.month}/${controller.selectedDateOfBirth.value!.year}'
                          : AppStrings.dateOfBirth,
                      readOnly: true,
                      suffixIcon: IconButton(
                        onPressed: () => _pickDate(context),
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.textSecondary,
                          size: AppDimensions.iconMd,
                        ),
                      ),
                      onTap: () => _pickDate(context),
                    )),

                const SizedBox(height: AppDimensions.spacingMd),

                // ── Terms & Conditions ──────────────────────────
                Obx(() => Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: controller.termsAccepted.value,
                            onChanged: (_) => controller.toggleTerms(),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingXs),
                        Text(
                          AppStrings.termsPrefix,
                          style: AppTextStyles.bodySmall,
                        ),
                        GestureDetector(
                          onTap: () {
                            // TODO: Navigate to Terms & Conditions
                          },
                          child: Text(
                            AppStrings.termsLink,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )),

                const SizedBox(height: AppDimensions.spacingXl),

                // ── Create Account Button ───────────────────────
                Obx(() => PrimaryButton(
                      text: AppStrings.createAccount,
                      onPressed: controller.register,
                      isLoading: controller.isLoading.value,
                    )),

                const SizedBox(height: AppDimensions.spacingLg),

                // ── OR Divider ──────────────────────────────────
                _buildOrDivider(),

                const SizedBox(height: AppDimensions.spacingLg),

                // ── Social Sign Up ──────────────────────────────
                SocialLoginButton(
                  text: AppStrings.signUpGoogle,
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



                const SizedBox(height: AppDimensions.spacingXl),

                // ── Already have account? ───────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.alreadyHaveAccount,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Text(
                          AppStrings.login,
                          style: AppTextStyles.link.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingXxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
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

  void _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.setDateOfBirth(picked);
    }
  }

  Widget _buildValidationRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : AppColors.textSecondary,
          size: 16,
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: isValid ? Colors.green : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
