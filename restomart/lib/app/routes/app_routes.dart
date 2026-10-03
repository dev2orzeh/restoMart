/// Named route constants.
///
/// Every screen has a unique route name defined here.
/// GetX uses these for navigation.
class AppRoutes {
  AppRoutes._();

  // ── Auth ──────────────────────────────────────────────────────────
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String resetPassword = '/reset-password';
  static const String passwordSuccess = '/password-success';

  // ── Main ──────────────────────────────────────────────────────────
  static const String home = '/home';
  static const String categories = '/categories';
  static const String promotions = '/promotions';
  static const String notifications = '/notifications';
  static const String account = '/account';

  // ── Products ──────────────────────────────────────────────────────
  static const String productList = '/product-list';
  static const String productDetail = '/product-detail';
  static const String search = '/search';

  // ── Cart & Checkout ───────────────────────────────────────────────
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order-confirmation';

  // ── Orders ────────────────────────────────────────────────────────
  static const String orderHistory = '/order-history';
  static const String orderDetail = '/order-detail';
  static const String reorder = '/reorder';

  // ── Profile ───────────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
}
