/// Authentication controller.
///
/// Manages state for Login, Register, Forgot Password, OTP, and Reset Password.
/// Uses GetX reactive state (.obs) for clean state management.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../routes/app_routes.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../orders/controllers/orders_controller.dart';
import '../../checkout/controllers/address_controller.dart';
import '../../../core/services/woocommerce_api_service.dart';
import '../../../core/services/ledger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class AuthController extends GetxController {
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();

  final registerNameController = TextEditingController();
  final registerEmailController = TextEditingController();
  final registerPhoneController = TextEditingController();
  final registerPasswordController = TextEditingController();
  final registerConfirmPasswordController = TextEditingController();
  final registerRestaurantNameController = TextEditingController();
  final registerRestaurantAddressController = TextEditingController();
  final registerFormKey = GlobalKey<FormState>();

  // Forgot Password
  final forgotEmailController = TextEditingController();
  final forgotFormKey = GlobalKey<FormState>();

  // OTP
  final otpController = TextEditingController();

  // Reset Password
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final resetFormKey = GlobalKey<FormState>();

  // ── Reactive State ────────────────────────────────────────────────

  /// Whether the password field is obscured.
  final isPasswordVisible = false.obs;

  /// Whether the new password field is obscured.
  final isNewPasswordVisible = false.obs;

  /// Whether the confirm password field is obscured.
  final isConfirmPasswordVisible = false.obs;

  /// Loading state for async operations.
  final isLoading = false.obs;

  // ── Profile State ──────────────────────────────────────────────────
  final userName = ''.obs;
  final userEmail = ''.obs;
  final userPhone = ''.obs;
  final userAddress = ''.obs;
  final profileImagePath = ''.obs;
  final businessName = ''.obs;

  /// Selected gender for registration.
  final selectedGender = Rxn<String>();

  /// Selected date of birth for registration.
  final selectedDateOfBirth = Rxn<DateTime>();

  /// Terms & conditions accepted.
  final termsAccepted = false.obs;

  /// OTP timer remaining seconds.
  final otpTimerSeconds = 299.obs; // 4:59

  /// Masked email for OTP screen.
  final maskedEmail = ''.obs;

  // ── Password Validation State ─────────────────────────────────────

  final hasMinLength = false.obs;
  final hasUpperAndLower = false.obs;
  final hasNumberOrSymbol = false.obs;

  // ── Lifecycle ─────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _initGoogleSignIn();
    _loadUserProfile();

    // Listen to auth changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _loadUserProfile();
    });
  }

  void _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userName.value = user.displayName ?? '';
      userEmail.value = user.email ?? '';
      userPhone.value = user.phoneNumber ?? '';
      profileImagePath.value = (user.photoURL != null && user.photoURL!.startsWith('http')) ? user.photoURL! : '';
      businessName.value = '';

      // Try to load user photo and restaurant name from Firestore first
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['profileImagePath'] != null && (data['profileImagePath'] as String).isNotEmpty) {
            profileImagePath.value = data['profileImagePath'] as String;
          }
          if (data['businessName'] != null && (data['businessName'] as String).isNotEmpty) {
            businessName.value = data['businessName'] as String;
          } else if (data['restaurantName'] != null && (data['restaurantName'] as String).isNotEmpty) {
            businessName.value = data['restaurantName'] as String;
          }
        }
      } catch (e) {
        debugPrint('Error fetching user profile from Firestore: $e');
      }

      await _loadLocalProfileImage(user.uid);
    } else {
      // Clear profile when logged out
      userName.value = '';
      userEmail.value = '';
      userPhone.value = '';
      profileImagePath.value = '';
      businessName.value = '';
    }
  }

  Future<void> _loadLocalProfileImage(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Only load if not already set from Firestore or Google Photo
    if (profileImagePath.isEmpty) {
      final savedPath = prefs.getString('local_profile_image_$uid');
      if (savedPath != null && savedPath.isNotEmpty) {
        profileImagePath.value = savedPath;
      }
    }

    if (businessName.isEmpty) {
      final savedBusinessName = prefs.getString('local_business_name_$uid');
      if (savedBusinessName != null && savedBusinessName.isNotEmpty) {
        businessName.value = savedBusinessName;
      }
    }
  }

  Future<void> pickProfileImage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        // Read file bytes and convert to base64
        final bytes = await File(image.path).readAsBytes();
        final base64String = 'data:image/png;base64,${base64Encode(bytes)}';

        profileImagePath.value = base64String;

        // Save locally in SharedPreferences per UID
        if (uid != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('local_profile_image_$uid', base64String);

          try {
            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'profileImagePath': base64String,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (fsError) {
            debugPrint('Firestore photo update error: $fsError');
          }
        }

        Get.snackbar(
          'Profile Photo Updated',
          'Your profile photo has been updated successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade900,
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      Get.snackbar(
        'Error',
        'Could not select image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
      );
    }
  }

  Future<void> _initGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();
    } catch (e) {
      debugPrint('Google Sign-In Init Error: $e');
    }
  }

  @override
  void onClose() {
    super.onClose();
  }

  // ── Toggle Methods ────────────────────────────────────────────────

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void toggleTerms() {
    termsAccepted.value = !termsAccepted.value;
  }

  void setGender(String? gender) {
    selectedGender.value = gender;
  }

  void setDateOfBirth(DateTime? date) {
    selectedDateOfBirth.value = date;
  }

  // ── Password Validation ───────────────────────────────────────────

  void validatePassword(String password) {
    hasMinLength.value = password.length >= 8;
    hasUpperAndLower.value =
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]'));
    hasNumberOrSymbol.value =
        password.contains(RegExp(r'[0-9]')) ||
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  // ── Auth Actions ──────────────────────────────────────────────────

  /// Handle login via Firebase Email/Password
  Future<void> login() async {
    if (!(loginFormKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;

    try {
      final email = loginEmailController.text.trim();
      final password = loginPasswordController.text;

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Sync FCM token to WooCommerce
      final token = await FirebaseMessaging.instance.getToken();
      final user = FirebaseAuth.instance.currentUser;
      if (token != null && user != null) {
        WooCommerceApiService.syncDeviceToken(user.uid, token);
      }

      if (Get.isRegistered<CartController>()) {
        await Get.find<CartController>().reloadCartForUser();
      }

      // Show success bottom sheet
      _showSuccessBottomSheet(
        'Successful!',
        'You have successfully logged in.',
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Invalid email or password. Please try again.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No account found for this email. Please register.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is badly formatted.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      Get.snackbar(
        'Login Failed',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(), // Display the actual error so we know what went wrong
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle registration via Firebase Email/Password
  Future<void> register() async {
    if (!(registerFormKey.currentState?.validate() ?? false)) return;
    if (registerPasswordController.text !=
        registerConfirmPasswordController.text) {
      Get.snackbar(
        'Password Mismatch',
        'Passwords do not match. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
      return;
    }
    if (!hasMinLength.value || !hasNumberOrSymbol.value) {
      Get.snackbar(
        'Weak Password',
        'Password must be at least 8 characters and include a special character.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
      return;
    }
    if (!termsAccepted.value) {
      Get.snackbar(
        'Terms Required',
        'Please accept the Terms & Conditions to continue.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade50,
        colorText: Colors.orange.shade800,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    isLoading.value = true;

    try {
      final email = registerEmailController.text.trim();
      final name = registerNameController.text.trim();
      final password = registerPasswordController.text;

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user?.uid;
      final phone = registerPhoneController.text.trim();
      final restaurantName = registerRestaurantNameController.text.trim();
      final restaurantAddress = registerRestaurantAddressController.text.trim();

      if (uid != null) {
        // Update the user's display name
        await userCredential.user?.updateDisplayName(name);

        // 1. Save user details to Firestore 'users' collection
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'name': name,
          'email': email,
          'phone': phone,
          'restaurantName': restaurantName,
          'restaurantAddress': restaurantAddress,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 2. Ensure customer ledger account is created in 'ledger_accounts'
        await LedgerService.ensureAccountExists(
          uid: uid,
          name: name,
          email: email,
          phone: phone,
        );
      }

      _loadUserProfile();

      _showSuccessBottomSheet(
        'Successful!',
        'Your account is created successfully\nand ready now.',
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is badly formatted.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      Get.snackbar(
        'Registration Failed',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(), // Display the actual error so we know what went wrong
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Social Sign-In ────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user;
      if (user != null) {
        final name = user.displayName ?? 'Customer';
        final email = user.email ?? '';
        final phone = user.phoneNumber ?? '';

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await LedgerService.ensureAccountExists(
          uid: user.uid,
          name: name,
          email: email,
          phone: phone,
        );
      }

      Get.snackbar(
        'Success',
        'Signed in with Google successfully.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade800,
      );

      if (Get.isRegistered<CartController>()) {
        await Get.find<CartController>().reloadCartForUser();
      }

      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(AppRoutes.home);
    } on GoogleSignInException catch (e) {
      // Ignore cancellation exceptions
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return;
      }
      Get.snackbar(
        'Google Sign-In Failed',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Google Sign-In Failed',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithFacebook() async {
    isLoading.value = true;
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential = FacebookAuthProvider.credential(
          accessToken.tokenString,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);

        Get.snackbar(
          'Success',
          'Signed in with Facebook successfully.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade800,
        );

        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(AppRoutes.home);
      } else if (result.status == LoginStatus.cancelled) {
        // User canceled
      } else {
        Get.snackbar(
          'Facebook Sign-In Failed',
          result.message ?? 'Unknown error',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Facebook Sign-In Failed',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String verificationId = '';

  /// Handle forgot password — send Password Reset Email.
  Future<void> sendForgotPasswordEmail() async {
    if (!(forgotFormKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    final email = forgotEmailController.text.trim();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Get.snackbar(
        'Email Sent',
        'Password reset link has been sent to your email address.',
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade900,
        duration: const Duration(seconds: 4),
      );
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red.shade50);
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle OTP verification.
  Future<void> verifyOtp() async {
    final smsCode = otpController.text.trim();
    if (smsCode.length != 6) {
      // Firebase OTPs are typically 6 digits
      Get.snackbar('Invalid', 'Please enter the 6-digit OTP code.');
      return;
    }

    isLoading.value = true;

    try {
      // Create a PhoneAuthCredential with the code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Sign the user in (or link) with the credential
      await FirebaseAuth.instance.signInWithCredential(credential);

      Get.offAllNamed(AppRoutes.resetPassword);
    } catch (e) {
      Get.snackbar(
        'Invalid OTP',
        'The code you entered is incorrect or expired.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade50,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle password reset.
  Future<void> resetPassword() async {
    if (!(resetFormKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(newPasswordController.text);
      } else {
        throw Exception("No authenticated user found.");
      }

      Get.offAllNamed(AppRoutes.passwordSuccess);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reset password. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Navigation ────────────────────────────────────────────────────

  void goToRegister() => Get.toNamed(AppRoutes.register);
  void goToLogin() => Get.offAllNamed(AppRoutes.login);
  void goToForgotPassword() => Get.toNamed(AppRoutes.forgotPassword);
  void goToLoginFromSuccess() => Get.offAllNamed(AppRoutes.login);

  // ── Helpers ───────────────────────────────────────────────────────

  /// Mask email for OTP screen display: sa****le@gmail.com
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final name = parts[0];
    if (name.length <= 4) return email;

    final masked =
        '${name.substring(0, 2)}${'*' * (name.length - 4)}${name.substring(name.length - 2)}@${parts[1]}';
    return masked;
  }

  void _showSuccessBottomSheet(
    String title,
    String message, {
    bool toHome = true,
  }) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Get.back(); // close bottom sheet
                  if (toHome) {
                    Get.offAllNamed(AppRoutes.home);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Browse Home',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }

  // ── Logout ────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      isLoading.value = true;

      // 1. Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // 2. Safe sign out from Google
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('Google logout error: $e');
      }

      // 3. Safe sign out from Facebook
      try {
        await FacebookAuth.instance.logOut();
      } catch (e) {
        debugPrint('Facebook logout error: $e');
      }

      // 4. Clear user-specific state
      userName.value = '';
      userEmail.value = '';
      userPhone.value = '';
      profileImagePath.value = '';
      businessName.value = '';

      if (Get.isRegistered<AddressController>()) {
        Get.find<AddressController>().clearAll();
      }
      if (Get.isRegistered<CartController>()) {
        Get.find<CartController>().clearCartForLogout();
      }
      if (Get.isRegistered<OrdersController>()) {
        Get.find<OrdersController>().orders.clear();
      }

      // Reset login form fields
      loginEmailController.clear();
      loginPasswordController.clear();

      // Ensure open dialogs or overlays are dismissed
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      debugPrint('Logout error: $e');
      // Always fallback to login screen so user is never stuck
      Get.offAllNamed(AppRoutes.login);
    } finally {
      isLoading.value = false;
    }
  }
}
