// Centralized asset path references.
//
// All image/icon/font paths are defined here so we never hardcode
// paths throughout the codebase.
class AppAssets {
  AppAssets._();

  // ── Base Paths ────────────────────────────────────────────────────
  static const String _imagesBase = 'assets/images';
  // static const String _iconsBase = 'assets/icons'; // Uncomment when adding icon assets

  // ── Images ────────────────────────────────────────────────────────
  /// Splash screen product collage image.
  static const String splashProducts = '$_imagesBase/splash_products.jpeg';

  /// Logo image (placeholder — replace with client-provided PNG).
  // static const String logo = '$_imagesBase/logo.png';

  // ── Icons ─────────────────────────────────────────────────────────
  // Add SVG icons here as needed:
  // static const String iconCart = '$_iconsBase/cart.svg';
  // static const String iconSearch = '$_iconsBase/search.svg';
}
