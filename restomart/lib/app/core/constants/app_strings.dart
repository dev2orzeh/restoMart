/// App-wide string constants.
///
/// Keeps all user-facing strings in one place for easy editing
/// and potential future localization.
class AppStrings {
  AppStrings._();

  // ── App Info ──────────────────────────────────────────────────────
  static const String appName = 'RestoMart';
  static const String appTagline = 'Supplying Success';
  static const String appSubtagline = 'Fast Food, Packaging, and More...';
  static const String appBottomTagline =
      'Your One-Stop Solution for Food\nand Packaging Essentials';

  // ── Auth — Login ──────────────────────────────────────────────────
  static const String loginTitle = 'Login to continue';
  static const String loginEmailHint = 'john@gmail.com';
  static const String loginPasswordHint = 'Password';
  static const String loginButton = 'Login';
  static const String forgotPassword = 'Forgot password?';
  static const String noAccount = "Don't have an account? ";
  static const String createAccount = 'Create Account';
  static const String or = 'OR';
  static const String signInGoogle = 'Sign in  with Google';
  static const String signInFacebook = 'Sign in  with Facebook';

  // ── Auth — Registration ───────────────────────────────────────────
  static const String registerTitle = 'Create New Account';
  static const String fullName = 'Full Name';
  static const String email = 'Email';
  static const String phoneNumber = 'Phone Number';
  static const String gender = 'Gender';
  static const String dateOfBirth = 'Date of Birth';
  static const String termsPrefix = 'I have read the ';
  static const String termsLink = 'Terms & Conditions';
  static const String signUpGoogle = 'Sign up  with Google';
  static const String signUpFacebook = 'Sign up  with Facebook';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String login = 'Login';

  // ── Auth — Forgot Password ────────────────────────────────────────
  static const String forgotPasswordTitle = 'Enter your phone number';
  static const String forgotPasswordSubtitle = "Let's reset your password";
  static const String send = 'Send';

  // ── Auth — OTP ────────────────────────────────────────────────────
  static const String otpTitle = 'OTP Verification';
  static const String otpSubtitle =
      'Please check your email. We sent you a code to your email ';
  static const String resendCode = 'Resend Code';

  // ── Auth — Reset Password ─────────────────────────────────────────
  static const String resetPasswordTitle = 'Enter a new password';
  static const String newPassword = 'New Password';
  static const String confirmNewPassword = 'Confirm New Password';
  static const String confirmPassword = 'Confirm Password';
  static const String passwordReq8Chars = 'At least 8 characters';
  static const String passwordReqCase =
      'Both uppercase and lowercase characters';
  static const String passwordReqSymbol = 'At least one number or symbol';

  // ── Auth — Success ────────────────────────────────────────────────
  static const String passwordChangedTitle =
      'Your password has been\nchanged successfully!';
  static const String continueText = 'Continue';

  // ── Currency ──────────────────────────────────────────────────────
  static const String currency = 'Rs.';
}
