/// RestoMart — main entry point.
///
/// Initializes GetX, sets up theme, and registers routes.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/modules/cart/controllers/cart_controller.dart';
import 'app/modules/orders/controllers/orders_controller.dart';
import 'app/modules/favorites/controllers/favorites_controller.dart';
import 'app/core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase safely
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Initialize Push Notifications safely
  try {
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint('Push Notifications init error: $e');
  }

  // Initialize Global Controllers
  Get.put<CartController>(CartController(), permanent: true);
  Get.put<OrdersController>(OrdersController(), permanent: true);
  Get.put<FavoritesController>(FavoritesController(), permanent: true);

  // Lock orientation to portrait (mobile-first B2B app).
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const RestoMartApp());
}

class RestoMartApp extends StatelessWidget {
  const RestoMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'RestoMart',
      debugShowCheckedModeBanner: false,

      // Theme from the PDF design system.
      theme: AppTheme.lightTheme,

      // Routes.
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,

      // Default transition.
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
