import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/push_notification_service.dart';

class NotificationsController extends GetxController {
  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  StreamSubscription<QuerySnapshot>? _notifSub;
  static final Set<String> _notifiedDocIds = {};

  int get unreadCount => notifications.where((n) => n['isRead'] == false).length;

  @override
  void onInit() {
    super.onInit();
    _listenToFirestoreNotifications();

    // Re-listen when auth state changes (login/logout)
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _listenToFirestoreNotifications();
    });
  }

  void _listenToFirestoreNotifications() {
    _notifSub?.cancel();
    notifications.clear();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true);

    _notifSub = ref.snapshots().listen((snapshot) {
      final List<Map<String, dynamic>> loadedList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final docId = doc.id;
        final isRead = data['isRead'] as bool? ?? false;
        final notified = data['notified'] as bool? ?? false;
        final title = data['title'] as String? ?? 'Notification';
        final description = data['description'] as String? ?? '';
        final action = data['action'] as String? ?? 'order_view';
        final type = data['type'] as String? ?? 'general';

        // Check if creation date is within the last 3 minutes
        bool isRecent = false;
        if (data['createdAt'] is Timestamp) {
          final DateTime d = (data['createdAt'] as Timestamp).toDate();
          isRecent = DateTime.now().difference(d).inSeconds < 180;
        }

        // Choose icon & color based on type
        IconData iconData = Icons.notifications;
        Color iconColor = const Color(0xFF3F51B5);

        if (type == 'ledger_payment') {
          iconData = Icons.account_balance_wallet;
          iconColor = const Color(0xFF4CAF50);
        } else if (type == 'order_status') {
          iconData = Icons.local_shipping;
          iconColor = const Color(0xFFFF9800);
        } else if (type == 'deal') {
          iconData = Icons.local_offer;
          iconColor = const Color(0xFFFFC107);
        }

        // Trigger push notification popup ONLY if newly arrived, unread, recent, and not yet notified
        if (!isRead && !notified && isRecent && !_notifiedDocIds.contains(docId)) {
          _notifiedDocIds.add(docId);
          doc.reference.update({'notified': true}).catchError((_) {});

          if (type == 'ledger_payment') {
            final double amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final double bal = (data['newBalance'] as num?)?.toDouble() ?? 0.0;
            PushNotificationService.showLedgerPaymentNotification(amt, bal);
          } else if (type == 'order_status') {
            final String oId = data['orderId'] as String? ?? '';
            final String st = data['status'] as String? ?? 'Updated';
            PushNotificationService.showOrderStatusNotification(oId, st);
          }
        }

        // Format time display
        String timeStr = 'Just now';
        if (data['createdAt'] is Timestamp) {
          final DateTime d = (data['createdAt'] as Timestamp).toDate();
          final Duration diff = DateTime.now().difference(d);
          if (diff.inMinutes < 1) {
            timeStr = 'Just now';
          } else if (diff.inMinutes < 60) {
            timeStr = '${diff.inMinutes}m ago';
          } else if (diff.inHours < 24) {
            timeStr = '${diff.inHours}h ago';
          } else {
            timeStr = '${diff.inDays}d ago';
          }
        }

        loadedList.add({
          'id': docId,
          'title': title,
          'description': description,
          'time': timeStr,
          'icon': iconData,
          'color': iconColor,
          'isRead': isRead,
          'action': action,
        });
      }

      notifications.value = loadedList;
    }, onError: (e) {
      debugPrint('Firestore notification subscription error: $e');
    });
  }

  void addNotification({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    String? action,
  }) {
    notifications.insert(0, {
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'description': description,
      'time': 'Just now',
      'icon': icon,
      'color': color,
      'isRead': false,
      'action': action ?? 'order_view',
    });

    // Also persist to Firestore if user logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': title,
        'description': description,
        'action': action ?? 'order_view',
        'type': 'general',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      }).catchError((e) => debugPrint('Error writing notification to Firestore: $e'));
    }
  }

  void markAllAsRead() async {
    for (var i = 0; i < notifications.length; i++) {
      notifications[i]['isRead'] = true;
    }
    notifications.refresh();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snap.docs) {
        doc.reference.update({'isRead': true});
      }
    }
  }

  void markAsRead(int index) async {
    if (index >= 0 && index < notifications.length) {
      notifications[index]['isRead'] = true;
      final docId = notifications[index]['id'] as String?;
      notifications.refresh();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && docId != null && !docId.startsWith('local_')) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(docId)
            .update({'isRead': true})
            .catchError((e) => debugPrint('Error marking notif read: $e'));
      }
    }
  }

  void clearAll() async {
    notifications.clear();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();

      for (var doc in snap.docs) {
        doc.reference.delete();
      }
    }
  }

  @override
  void onClose() {
    _notifSub?.cancel();
    super.onClose();
  }
}
