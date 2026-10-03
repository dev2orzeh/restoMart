import 'dart:convert';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../modules/main/controllers/notifications_controller.dart';
import 'woocommerce_api_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Request permissions for iOS and newer Androids
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');
    } else {
      log('User declined or has not accepted permission');
    }

    // 2. Setup Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Initialize Local Notifications (for showing notifications while app is in foreground)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // For iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log("Notification clicked: ${response.payload}");
      },
    );

    // 4. Create an Android Notification Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'restomart_high_importance_channel', // id
      'RestoMart Alerts', // name
      description: 'Important notifications like order status updates.', // description
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 5. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Received a foreground message: ${message.notification?.title}');
      
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 6. Get the FCM Token
    try {
      String? token = await _firebaseMessaging.getToken();
      log("FCM Token: $token");
      if (token != null) {
        _syncTokenWithWooCommerce(token);
      }
    } catch (e) {
      log("Failed to get FCM token: $e");
    }

    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      log("FCM Token Refreshed: $newToken");
      _syncTokenWithWooCommerce(newToken);
    });
  }

  static void _syncTokenWithWooCommerce(String token) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WooCommerceApiService.syncDeviceToken(user.uid, token);
    }
  }

  // --- LOCAL NOTIFICATION HELPER ---
  static Future<void> showOrderSuccessNotification(String orderId) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'restomart_high_importance_channel',
      'RestoMart Alerts',
      channelDescription: 'Important notifications like order status updates.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecond, // unique ID
      title: 'Order Placed! 📝',
      body: 'Your order #$orderId has been successfully placed and is pending approval.',
      notificationDetails: platformDetails,
    );

    // Save to in-app notifications screen
    if (Get.isRegistered<NotificationsController>()) {
      Get.find<NotificationsController>().addNotification(
        title: 'Order Placed! 📝',
        description: 'Your order #$orderId has been successfully placed and is pending approval.',
        icon: Icons.check_circle,
        color: const Color(0xFF4CAF50),
      );
    }
  }

  static Future<void> showOrderStatusNotification(String orderId, String status) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'restomart_high_importance_channel',
      'RestoMart Alerts',
      channelDescription: 'Important notifications like order status updates.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    String title = 'Order Update';
    String body = 'Your order #$orderId is now $status.';
    IconData iconData = Icons.info;
    Color iconColor = const Color(0xFF2196F3);

    if (status.toLowerCase() == 'shipped') {
      title = 'Order Shipped! 🚚';
      body = 'Your order #$orderId is on its way.';
      iconData = Icons.local_shipping;
      iconColor = const Color(0xFFFF9800);
    } else if (status.toLowerCase() == 'delivered') {
      title = 'Order Delivered! ✅';
      body = 'Your order #$orderId has been delivered. Enjoy!';
      iconData = Icons.check_circle;
      iconColor = const Color(0xFF4CAF50);
    } else if (status.toLowerCase() == 'payment confirmed' || status.toLowerCase() == 'paid') {
      title = 'Payment Confirmed 💳';
      body = 'Payment for order #$orderId has been received.';
      iconData = Icons.payment;
      iconColor = const Color(0xFF4CAF50);
    }

    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecond, // unique ID
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );

    // Save to in-app notifications screen
    if (Get.isRegistered<NotificationsController>()) {
      Get.find<NotificationsController>().addNotification(
        title: title,
        description: body,
        icon: iconData,
        color: iconColor,
      );
    }
  }

  static Future<void> showLedgerPaymentNotification(double amount, double newBalance) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'restomart_high_importance_channel',
      'RestoMart Alerts',
      channelDescription: 'Important notifications like order status updates.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    final amountStr = amount.toStringAsFixed(0);
    final balanceStr = newBalance.toStringAsFixed(0);

    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecond, // unique ID
      title: 'Payment Recorded! 💰',
      body: 'We received your payment of Rs. $amountStr. New balance: Rs. $balanceStr.',
      notificationDetails: platformDetails,
    );

    // Save to in-app notifications screen
    if (Get.isRegistered<NotificationsController>()) {
      Get.find<NotificationsController>().addNotification(
        title: 'Payment Recorded! 💰',
        description: 'We received your payment of Rs. $amountStr. New balance: Rs. $balanceStr.',
        icon: Icons.account_balance_wallet,
        color: const Color(0xFF4CAF50),
      );
    }
  }
}
