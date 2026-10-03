/// Splash screen controller.
///
/// Handles the initial loading logic:
/// - Show splash for a brief duration (brand impression).
/// - Check if user is already authenticated.
/// - Navigate to Login or Home accordingly.
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateAfterDelay();
  }

  /// Wait 3 seconds for brand impression, then navigate.
  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    _checkAuthAndNavigate();
  }

  // Check authentication status and route accordingly.
  //
  // TODO: Replace with actual auth check once auth service is built.
  // For now, always navigates to Login.
  // When auth is ready, check stored JWT token here and route to
  // AppRoutes.home if valid.
  void _checkAuthAndNavigate() {
    try {
      FirebaseAuth.instance.authStateChanges().first.then((user) {
        if (user != null) {
          Get.offAllNamed(AppRoutes.home);
        } else {
          Get.offAllNamed(AppRoutes.login);
        }
      }).catchError((e) {
        Get.offAllNamed(AppRoutes.login);
      });
    } catch (e) {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
