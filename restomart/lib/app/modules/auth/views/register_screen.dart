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
import '../../../widgets/google_logo.dart';
import '../../checkout/views/location_picker_view.dart';
import '../controllers/auth_controller.dart';
import 'dart:convert';

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

                const SizedBox(height: AppDimensions.spacingLg),

                // ── Profile Photo Picker ─────────────────────────
                Center(
                  child: Stack(
                    children: [
                      Obx(() {
                        final imgBase64 = controller.registerProfileImagePath.value;
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF0F0FF),
                            border: Border.all(color: const Color(0xFF25258F), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: imgBase64.isNotEmpty
                                ? Image.memory(
                                    base64Decode(imgBase64.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '')),
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  )
                                : const Icon(
                                    Icons.person_rounded,
                                    size: 55,
                                    color: Color(0xFF25258F),
                                  ),
                          ),
                        );
                      }),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => controller.pickRegisterProfileImage(),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF25258F),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Add Profile Photo (Optional)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingLg),

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

                // ── Restaurant Address (Pick on Map) ───────────
                GestureDetector(
                  onTap: () async {
                    final result = await Get.to(() => const LocationPickerView());
                    if (result != null && result['address'] != null) {
                      controller.registerRestaurantAddressController.text = result['address'] as String;
                      controller.registerLatitude.value = (result['lat'] as num?)?.toDouble();
                      controller.registerLongitude.value = (result['lng'] as num?)?.toDouble();
                    }
                  },
                  child: AbsorbPointer(
                    child: CustomTextField(
                      controller: controller.registerRestaurantAddressController,
                      hintText: 'Select Address on Map',
                      prefixIcon: Icons.location_on_rounded,
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25258F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Map', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please select your address on map';
                        }
                        return null;
                      },
                    ),
                  ),
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
                  icon: const GoogleLogo(size: 22),
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
