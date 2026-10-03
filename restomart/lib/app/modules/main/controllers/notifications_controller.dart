import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationsController extends GetxController {
  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[
    {
      'title': 'Weekly Deal Alert!',
      'description': 'Mozzarella Cheese is now 12% off. Grab it before it\'s gone!',
      'time': '2h ago',
      'icon': Icons.local_offer,
      'color': const Color(0xFFFFC107),
      'isRead': false,
    },
    {
      'title': 'Order Update',
      'description': 'Your order #RM4S87 has been dispatched and is on the way.',
      'time': '5h ago',
      'icon': Icons.notifications,
      'color': const Color(0xFF3F51B5),
      'isRead': true,
    },
    {
      'title': 'Special Offer',
      'description': 'Get 20% OFF on Cooking Oils this weekend only!',
      'time': '1d ago',
      'icon': Icons.percent,
      'color': const Color(0xFFFFC107),
      'isRead': true,
    },
  ].obs;

  int get unreadCount => notifications.where((n) => n['isRead'] == false).length;

  void addNotification({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    notifications.insert(0, {
      'title': title,
      'description': description,
      'time': 'Just now',
      'icon': icon,
      'color': color,
      'isRead': false,
      'action': 'order_view', // tag it so we know it's clickable
    });
  }

  void markAllAsRead() {
    for (var i = 0; i < notifications.length; i++) {
      notifications[i]['isRead'] = true;
    }
    notifications.refresh();
  }

  void markAsRead(int index) {
    notifications[index]['isRead'] = true;
    notifications.refresh();
  }
}
