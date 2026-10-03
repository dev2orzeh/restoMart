// Splash Screen — uses the exact PDF Page 1 image as a full-screen background.
//
// This ensures the splash looks pixel-perfect to the PDF design.
// After 3 seconds, navigates to the Login screen.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure the controller is initialized (triggers onInit → navigation).
    // ignore: unnecessary_statements
    controller;

    // Light status bar icons on dark background.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splash1.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
