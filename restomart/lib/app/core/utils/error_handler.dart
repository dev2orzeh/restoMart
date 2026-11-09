/// Centralized Error Handler for RestoMart
///
/// Provides unified, user-friendly error handling for:
/// - Network / connectivity failures (SocketException, TimeoutException)
/// - Firebase Auth errors (wrong-password, user-not-found, etc.)
/// - Firestore / API failures
/// - Generic unexpected errors
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppErrorHandler {
  /// Converts any thrown error into a user-readable string.
  static String getErrorMessage(dynamic error) {
    if (error is SocketException || error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (error is TimeoutException || error.toString().contains('TimeoutException')) {
      return 'The request timed out. Your internet may be slow. Please try again.';
    }
    if (error is FirebaseAuthException) {
      return _firebaseAuthMessage(error);
    }
    if (error.toString().contains('network-request-failed') ||
        error.toString().contains('NETWORK_ERROR')) {
      return 'Network error. Please check your internet connection.';
    }
    if (error.toString().contains('permission-denied')) {
      return 'Permission denied. Please log in and try again.';
    }
    if (error.toString().contains('not-found')) {
      return 'The requested data was not found. Please refresh and try again.';
    }
    if (error.toString().contains('unavailable')) {
      return 'The service is temporarily unavailable. Please try again later.';
    }
    if (error.toString().contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (error.toString().contains('unauthenticated')) {
      return 'Your session has expired. Please log in again.';
    }
    // Generic fallback
    return 'Something went wrong. Please try again.';
  }

  /// Firebase Auth specific messages.
  static String _firebaseAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please register first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'weak-password':
        return 'The password is too weak. Use at least 8 characters with a symbol.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few minutes and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'requires-recent-login':
        return 'For security, please log out and log in again to continue.';
      case 'expired-action-code':
        return 'The link has expired. Please request a new one.';
      case 'invalid-action-code':
        return 'The link is invalid. It may have already been used.';
      default:
        return e.message ?? 'An authentication error occurred. Please try again.';
    }
  }

  static const EdgeInsets _defaultTopMargin = EdgeInsets.only(top: 54, left: 16, right: 16);
  static const EdgeInsets _defaultBottomMargin = EdgeInsets.only(bottom: 24, left: 16, right: 16);

  /// Shows an error snackbar with safe-area spacing and modern floating card design.
  static void showError(String title, dynamic error, {SnackPosition position = SnackPosition.TOP}) {
    final message = getErrorMessage(error);
    _showSnackbar(title, message, isError: true, position: position);
  }

  /// Shows a success snackbar with safe-area spacing and modern floating card design.
  static void showSuccess(String title, String message, {SnackPosition position = SnackPosition.TOP}) {
    _showSnackbar(title, message, isError: false, position: position);
  }

  /// Shows a warning / notice snackbar cleanly below the status bar.
  static void showWarning(String title, String message, {SnackPosition position = SnackPosition.TOP}) {
    if (Get.isSnackbarOpen) return;
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: const Color(0xFFFFFBEB),
      colorText: const Color(0xFF92400E),
      borderColor: const Color(0xFFFDE68A),
      borderWidth: 1.0,
      margin: position == SnackPosition.TOP ? _defaultTopMargin : _defaultBottomMargin,
      borderRadius: 14,
      duration: const Duration(seconds: 4),
      icon: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFFDE68A),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 20),
      ),
      shouldIconPulse: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Shows an info notice snackbar.
  static void showInfo(String title, String message, {SnackPosition position = SnackPosition.TOP}) {
    if (Get.isSnackbarOpen) return;
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: const Color(0xFF1E293B),
      colorText: Colors.white,
      margin: position == SnackPosition.TOP ? _defaultTopMargin : _defaultBottomMargin,
      borderRadius: 14,
      duration: const Duration(seconds: 4),
      icon: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
      ),
      shouldIconPulse: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  /// Shows an "offline" snackbar — used when no internet is detected.
  static void showOfflineError() {
    if (Get.isSnackbarOpen) return;
    Get.snackbar(
      'No Internet Connection',
      'Please check your Wi-Fi or mobile data and try again.',
      snackPosition: SnackPosition.TOP,
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: const Color(0xFF0F172A),
      colorText: Colors.white,
      margin: _defaultTopMargin,
      borderRadius: 14,
      duration: const Duration(seconds: 4),
      icon: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
      ),
      shouldIconPulse: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  /// Shows a slow network warning.
  static void showSlowNetworkWarning() {
    if (Get.isSnackbarOpen) return;
    Get.snackbar(
      'Slow Connection',
      'Your internet seems slow. Loading may take longer than usual.',
      snackPosition: SnackPosition.TOP,
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: const Color(0xFFD97706),
      colorText: Colors.white,
      margin: _defaultTopMargin,
      borderRadius: 14,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4, color: Colors.white),
      shouldIconPulse: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  /// Determines if an error is a network error.
  static bool isNetworkError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('network-request-failed') ||
        error.toString().contains('NETWORK_ERROR') ||
        error.toString().contains('Failed host lookup');
  }

  static void _showSnackbar(String title, String message,
      {required bool isError, SnackPosition position = SnackPosition.TOP}) {
    if (Get.isSnackbarOpen) return;
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: isError ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
      colorText: isError ? const Color(0xFF991B1B) : const Color(0xFF065F46),
      borderColor: isError ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
      borderWidth: 1.0,
      margin: position == SnackPosition.TOP ? _defaultTopMargin : _defaultBottomMargin,
      borderRadius: 14,
      duration: const Duration(seconds: 4),
      icon: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isError ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
          color: isError ? const Color(0xFFDC2626) : const Color(0xFF059669),
          size: 20,
        ),
      ),
      shouldIconPulse: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
