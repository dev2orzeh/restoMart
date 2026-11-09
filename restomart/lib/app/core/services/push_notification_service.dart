import 'dart:convert';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../modules/main/controllers/notifications_controller.dart';
import '../../modules/ledger/views/ledger_view.dart';
import '../../modules/orders/views/orders_view.dart';
import 'woocommerce_api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Handling a background message: ${message.messageId}");

  final prefs = await SharedPreferences.getInstance();
  final isEnabled = prefs.getBool('notifications_enabled') ?? true;
  if (!isEnabled) {
    log("User has disabled notifications toggle. Suppressing background alert.");
    return;
  }

  final FlutterLocalNotificationsPlugin localPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);
  await localPlugin.initialize(settings: initSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'restomart_high_importance_channel',
    'RestoMart Alerts',
    description: 'Important notifications like order status updates.',
    importance: Importance.max,
  );

  await localPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final title = message.notification?.title ?? message.data['title'] ?? 'RestoMart Update';
  final body = message.notification?.body ?? message.data['body'] ?? message.data['description'] ?? 'You have a new update regarding your order.';

  await localPlugin.show(
    id: message.hashCode,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'restomart_high_importance_channel',
        'RestoMart Alerts',
        channelDescription: 'Important notifications like order status updates.',
        icon: '@mipmap/launcher_icon',
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
      ),
    ),
    payload: message.data['action'] ?? 'order_view',
  );
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Request permissions for iOS and newer Androids (including Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional) {
      log('User granted notification permission');
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('notifications_enabled')) {
        await prefs.setBool('notifications_enabled', true);
      }
    } else {
      log('User declined or has not accepted permission');
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('notifications_enabled')) {
        await prefs.setBool('notifications_enabled', false);
      }
    }

    // 2. Setup Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Initialize Local Notifications (for showing notifications while app is in foreground)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    // For iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log("Notification clicked: ${response.payload}");
        if (response.payload == 'ledger_view') {
          Get.to(() => const LedgerView());
        } else if (response.payload == 'order_view') {
          Get.to(() => const OrdersView());
        }
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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      log('Received a foreground message: ${message.notification?.title}');
      
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('notifications_enabled') ?? true;
      if (!isEnabled) {
        log('Notification toggle is OFF, suppressing notification display');
        return;
      }
      
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
              icon: '@mipmap/launcher_icon',
              importance: Importance.max,
              priority: Priority.high,
              visibility: NotificationVisibility.public,
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
        _syncTokenWithFirebase(token);
      }
    } catch (e) {
      log("Failed to get FCM token: $e");
    }

    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      log("FCM Token Refreshed: $newToken");
      _syncTokenWithFirebase(newToken);
    });
  }

  static void _syncTokenWithFirebase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WooCommerceApiService.syncDeviceToken(user.uid, token);
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        log("FCM Token saved to Firestore for user ${user.uid}");
      } catch (e) {
        log("Failed to save FCM token to Firestore: $e");
      }
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
      icon: '@mipmap/launcher_icon',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecond, // unique ID
      title: 'Order Placed! 📝',
      body: 'Your order #$orderId has been successfully placed and is pending approval.',
      notificationDetails: platformDetails,
      payload: 'order_view',
    );

    // Save to in-app notifications screen
    if (Get.isRegistered<NotificationsController>()) {
      Get.find<NotificationsController>().addNotification(
        title: 'Order Placed! 📝',
        description: 'Your order #$orderId has been successfully placed and is pending approval.',
        icon: Icons.check_circle,
        color: const Color(0xFF4CAF50),
        action: 'order_view',
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
      icon: '@mipmap/launcher_icon',
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
    } else if (status.toLowerCase() == 'cancelled') {
      title = 'Order Cancelled ❌';
      body = 'Your order #$orderId has been cancelled.';
      iconData = Icons.cancel;
      iconColor = const Color(0xFFF44336);
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
      payload: 'order_view',
    );

    // Save to in-app notifications screen
    if (Get.isRegistered<NotificationsController>()) {
      Get.find<NotificationsController>().addNotification(
        title: title,
        description: body,
        icon: iconData,
        color: iconColor,
        action: 'order_view',
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
      payload: 'ledger_view',
    );

    // Save to in-app notifications screen
    if (Get.isRegistered<NotificationsController>()) {
      Get.find<NotificationsController>().addNotification(
        title: 'Payment Recorded! 💰',
        description: 'We received your payment of Rs. $amountStr. New balance: Rs. $balanceStr.',
        icon: Icons.account_balance_wallet,
        color: const Color(0xFF4CAF50),
        action: 'ledger_view',
      );
    }
  }

  static Future<void> showLedgerDebitNotification(double amount, double newBalance, String desc) async {
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
      title: 'New Khata Entry 📖',
      body: '$desc recorded (Rs. $amountStr). Outstanding balance: Rs. $balanceStr.',
      notificationDetails: platformDetails,
      payload: 'ledger_view',
    );

    // Save to in-app notifications screen
    if (Get.isRegistered<NotificationsController>()) {
      Get.find<NotificationsController>().addNotification(
        title: 'New Khata Entry 📖',
        description: '$desc recorded (Rs. $amountStr). Outstanding balance: Rs. $balanceStr.',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF3F51B5),
        action: 'ledger_view',
      );
    }
  }
}
