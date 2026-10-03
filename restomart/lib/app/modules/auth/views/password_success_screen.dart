/// Password Changed Successfully Screen — matches PDF Page 8.
///
/// - Yellow starburst badge with white checkmark (centered)
/// - "Your password has been changed successfully!" message
/// - "Continue" button → navigates to Login
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/primary_button.dart';
import '../controllers/auth_controller.dart';

class PasswordSuccessScreen extends GetView<AuthController> {
  const PasswordSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ── Success Badge ─────────────────────────────────
              const _SuccessBadge(),

              const SizedBox(height: AppDimensions.spacingXxl),

              // ── Success Message ───────────────────────────────
              Text(
                AppStrings.passwordChangedTitle,
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // ── Continue Button ───────────────────────────────
              PrimaryButton(
                text: AppStrings.continueText,
                onPressed: controller.goToLoginFromSuccess,
              ),

              const SizedBox(height: AppDimensions.spacing3xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Golden starburst badge with white checkmark — matches PDF Page 8.
class _SuccessBadge extends StatefulWidget {
  const _SuccessBadge();

  @override
  State<_SuccessBadge> createState() => _SuccessBadgeState();
}

class _SuccessBadgeState extends State<_SuccessBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentLight,
              AppColors.accent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x40F5A623),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.check,
          color: AppColors.textOnPrimary,
          size: 56,
        ),
      ),
    );
  }
}
