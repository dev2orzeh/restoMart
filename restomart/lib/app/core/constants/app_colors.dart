/// App-wide color constants extracted from the RestoMart PDF design.
///
/// Primary palette: Deep indigo + golden yellow
/// These colors are used throughout the app for consistency.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Brand Colors ──────────────────────────────────────────
  /// Deep indigo/navy used for buttons, headers, app bars, and primary actions.
  static const Color primary = Color(0xFF2D2B7F);

  /// Slightly lighter shade of primary for hover/pressed states.
  static const Color primaryLight = Color(0xFF3D3B9F);

  /// Darker shade for status bar or deep backgrounds.
  static const Color primaryDark = Color(0xFF1D1B5F);

  // ── Accent / Secondary ────────────────────────────────────────────
  /// Golden yellow used for accents, badges, highlights, and the logo.
  static const Color accent = Color(0xFFF5A623);

  /// Lighter yellow for badges like discount starburst.
  static const Color accentLight = Color(0xFFFFD54F);

  /// Deep gold for text on yellow backgrounds.
  static const Color accentDark = Color(0xFFE8961C);

  // ── Background & Surface ──────────────────────────────────────────
  /// Main scaffold background.
  static const Color background = Color(0xFFF8F9FA);

  /// Card / surface background.
  static const Color surface = Color(0xFFFFFFFF);

  /// Slightly off-white for input fields, sections.
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // ── Text Colors ───────────────────────────────────────────────────
  /// Primary text (headings, body).
  static const Color textPrimary = Color(0xFF1A1A2E);

  /// Secondary text (subtitles, descriptions).
  static const Color textSecondary = Color(0xFF6B7280);

  /// Hint / placeholder text in inputs.
  static const Color textHint = Color(0xFF9CA3AF);

  /// Text on primary-colored backgrounds (white).
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Price Colors ──────────────────────────────────────────────────
  /// Sale / discounted price color (red).
  static const Color priceSale = Color(0xFFE53E3E);

  /// Original / strikethrough price color (grey).
  static const Color priceOriginal = Color(0xFF9CA3AF);

  // ── Status / Feedback ─────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Borders & Dividers ────────────────────────────────────────────
  /// Input field border color.
  static const Color border = Color(0xFFD1D5DB);

  /// Focused input field border.
  static const Color borderFocused = Color(0xFF2D2B7F);

  /// Divider / separator lines.
  static const Color divider = Color(0xFFE5E7EB);

  // ── Category Card ─────────────────────────────────────────────────
  /// Yellow border used on category cards (from PDF).
  static const Color categoryBorder = Color(0xFFF5A623);

  // ── Bottom Navigation ─────────────────────────────────────────────
  static const Color navBarBackground = Color(0xFFFFFFFF);
  static const Color navBarActive = Color(0xFF2D2B7F);
  static const Color navBarInactive = Color(0xFF9CA3AF);

  // ── Splash Screen Gradient ────────────────────────────────────────
  static const Color splashGradientTop = Color(0xFF2D2B7F);
  static const Color splashGradientBottom = Color(0xFF1D1B5F);
  static const Color splashAccentBar = Color(0xFFF5A623);
}
