/// OTP Verification Screen — matches PDF Page 6.
///
/// - "OTP Verification" heading
/// - Masked email display
/// - 5-digit OTP input boxes
/// - Countdown timer (04:59)
/// - "Resend Code" link
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/auth_controller.dart';

class OtpVerificationScreen extends GetView<AuthController> {
  const OtpVerificationScreen({super.key});

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
                AppStrings.otpTitle,
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

              const SizedBox(height: AppDimensions.spacing3xl),

              // ── OTP Input Boxes ─────────────────────────────
              const _OtpInputRow(),

              const SizedBox(height: AppDimensions.spacingXl),

              // ── Timer ───────────────────────────────────────
              Center(
                child: Obx(() {
                  final minutes = controller.otpTimerSeconds.value ~/ 60;
                  final seconds = controller.otpTimerSeconds.value % 60;
                  return Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }),
              ),

              const Spacer(),

              // ── Resend Code ─────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Resend OTP
                    controller.otpTimerSeconds.value = 299;
                  },
                  child: Text(
                    AppStrings.resendCode,
                    style: AppTextStyles.link.copyWith(
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXxl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row of 5 individual OTP digit input boxes.
class _OtpInputRow extends StatefulWidget {
  const _OtpInputRow();

  @override
  State<_OtpInputRow> createState() => _OtpInputRowState();
}

class _OtpInputRowState extends State<_OtpInputRow> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late Timer _timer;
  final _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    // Start countdown timer.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_authController.otpTimerSeconds.value > 0) {
        _authController.otpTimerSeconds.value--;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Combine all digits.
    final otp = _controllers.map((c) => c.text).join();
    _authController.otpController.text = otp;

    // Auto-verify when all 6 digits entered.
    if (otp.length == 6) {
      _authController.verifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 50,
          height: 60,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: AppTextStyles.headingSmall,
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: const BorderSide(
                  color: AppColors.borderFocused,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (value) => _onChanged(index, value),
          ),
        );
      }),
    );
  }
}
