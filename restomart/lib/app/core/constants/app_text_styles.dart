/// App-wide text style constants.
///
/// Uses Google Fonts (Poppins as primary, matching the PDF's clean sans-serif look).
/// All styles are defined here for consistency.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Font Family ───────────────────────────────────────────────────
// Font family: Poppins (via GoogleFonts)

  // ── Headings ──────────────────────────────────────────────────────

  /// Large heading — used for splash screen tagline.
  static TextStyle headingLarge = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Medium heading — screen titles like "Login to continue", "Create New Account".
  static TextStyle headingMedium = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Small heading — section titles like "Featured products", "Grocery Categories".
  static TextStyle headingSmall = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ── Body Text ─────────────────────────────────────────────────────

  /// Body large — input field text, product descriptions.
  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Body medium — general body text.
  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Body small — captions, hints, secondary info.
  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ── Button Text ───────────────────────────────────────────────────

  /// Primary button text — "Login", "Create Account", etc.
  static TextStyle buttonLarge = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.4,
  );

  /// Secondary / outlined button text — "Add to cart".
  static TextStyle buttonMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    height: 1.4,
  );

  // ── Labels & Links ────────────────────────────────────────────────

  /// Input field label.
  static TextStyle label = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Hint / placeholder text inside inputs.
  static TextStyle hint = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.4,
  );

  /// Clickable link text — "Forgot password?", "Create Account".
  static TextStyle link = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    height: 1.4,
  );

  // ── Price Styles ──────────────────────────────────────────────────

  /// Sale price.
  static TextStyle priceSale = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.priceSale,
    height: 1.4,
  );

  /// Original price (strikethrough).
  static TextStyle priceOriginal = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.priceOriginal,
    decoration: TextDecoration.lineThrough,
    height: 1.4,
  );

  // ── Special Styles ────────────────────────────────────────────────

  /// Splash screen main tagline.
  static TextStyle splashTitle = GoogleFonts.poppins(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.textOnPrimary,
    height: 1.3,
  );

  /// Splash screen subtitle.
  static TextStyle splashSubtitle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textOnPrimary.withValues(alpha: 0.85),
    height: 1.4,
  );

  /// Splash screen bottom tagline (on yellow bar).
  static TextStyle splashBottomTagline = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.3,
  );

  /// "OR" divider text.
  static TextStyle dividerText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
    height: 1.4,
  );

  /// Logo text "Resto" part.
  static TextStyle logoResto = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.accent,
    height: 1.2,
  );

  /// Logo text "Mart" part.
  static TextStyle logoMart = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );
}
