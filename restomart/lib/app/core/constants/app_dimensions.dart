/// App-wide spacing, sizing, and border radius constants.
///
/// Ensures consistent spacing throughout the app.
class AppDimensions {
  AppDimensions._();

  // ── Spacing ───────────────────────────────────────────────────────
  static const double spacingXxs = 4.0;
  static const double spacingXs = 8.0;
  static const double spacingSm = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 20.0;
  static const double spacingXl = 24.0;
  static const double spacingXxl = 32.0;
  static const double spacing3xl = 40.0;
  static const double spacing4xl = 48.0;

  // ── Screen Padding ────────────────────────────────────────────────
  /// Horizontal padding for screen content (matches PDF's insets).
  static const double screenPaddingH = 24.0;

  /// Vertical padding for screen content.
  static const double screenPaddingV = 16.0;

  // ── Border Radius ─────────────────────────────────────────────────
  /// Small radius for tags, badges.
  static const double radiusSm = 8.0;

  /// Medium radius for cards, inputs.
  static const double radiusMd = 12.0;

  /// Large radius for buttons (matches PDF's fully rounded buttons).
  static const double radiusLg = 16.0;

  /// Extra large radius for bottom sheets, modals.
  static const double radiusXl = 24.0;

  /// Fully rounded for pills, avatar circles.
  static const double radiusFull = 28.0;

  // ── Button Sizes ──────────────────────────────────────────────────
  /// Height of primary full-width buttons (Login, Create Account, etc.).
  static const double buttonHeight = 56.0;

  /// Height of smaller action buttons (Add to cart).
  static const double buttonHeightSmall = 44.0;

  // ── Input Field ───────────────────────────────────────────────────
  /// Height of text input fields.
  static const double inputHeight = 56.0;

  /// Horizontal padding inside inputs.
  static const double inputPaddingH = 16.0;

  // ── Icon Sizes ────────────────────────────────────────────────────
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;

  // ── Bottom Navigation ─────────────────────────────────────────────
  static const double bottomNavHeight = 72.0;
  static const double bottomNavIconSize = 24.0;
  static const double bottomNavLogoSize = 56.0;

  // ── Product Card ──────────────────────────────────────────────────
  static const double productCardWidth = 180.0;
  static const double productCardImageHeight = 130.0;

  // ── Category Card ─────────────────────────────────────────────────
  static const double categoryCardWidth = 160.0;
  static const double categoryCardHeight = 150.0;

  // ── Logo ──────────────────────────────────────────────────────────
  static const double logoSizeSplash = 120.0;
  static const double logoSizeLogin = 100.0;
  static const double logoSizeAppBar = 40.0;
}
