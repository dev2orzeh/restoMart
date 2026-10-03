import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notifications_controller.dart';
import '../../orders/views/orders_view.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationsController controller = Get.find<NotificationsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return const Center(child: Text('No notifications yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notif = controller.notifications[index];
            final isRead = notif['isRead'] as bool? ?? false;

            return GestureDetector(
              onTap: () {
                controller.markAsRead(index);
                if (notif['action'] == 'order_view') {
                  Get.to(() => const OrdersView());
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isRead ? Colors.white : const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isRead ? Colors.grey.shade200 : const Color(0xFF25258F).withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    if (!isRead)
                      BoxShadow(
                        color: const Color(0xFF25258F).withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: notif['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        notif['icon'] as IconData,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                notif['title'] as String,
                                style: TextStyle(
                                  color: isRead ? const Color(0xFF20283A) : const Color(0xFF25258F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                notif['time'] as String,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notif['description'] as String,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isRead)
                      Padding(
                        padding: const EdgeInsets.only(left: 10, top: 2),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935), // Red dot
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
