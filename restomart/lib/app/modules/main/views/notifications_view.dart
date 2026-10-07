import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notifications_controller.dart';
import '../../orders/views/orders_view.dart';
import '../../ledger/views/ledger_view.dart';

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
            fontSize: 22,
          ),
        ),
        actions: [
          Obx(() {
            if (controller.notifications.isEmpty) return const SizedBox.shrink();
            return Row(
              children: [
                if (controller.unreadCount > 0)
                  TextButton.icon(
                    onPressed: controller.markAllAsRead,
                    icon: const Icon(Icons.done_all, size: 16, color: Color(0xFF25258F)),
                    label: const Text(
                      'Read All',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF25258F)),
                    ),
                  ),
                IconButton(
                  onPressed: controller.clearAll,
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  tooltip: 'Clear All',
                ),
                const SizedBox(width: 8),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25258F).withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_off_outlined,
                    size: 48,
                    color: Color(0xFF25258F),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Order status updates & khata payments will appear here.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notif = controller.notifications[index];
            final isRead = notif['isRead'] as bool? ?? false;

            return GestureDetector(
              onTap: () {
                controller.markAsRead(index);
                if (notif['action'] == 'ledger_view') {
                  Get.to(() => const LedgerView());
                } else if (notif['action'] == 'order_view') {
                  Get.to(() => const OrdersView());
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isRead ? Colors.white : const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isRead ? Colors.grey.shade200 : const Color(0x3325258F),
                    width: 1,
                  ),
                  boxShadow: [
                    if (!isRead)
                      BoxShadow(
                        color: const Color(0xFF25258F).withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: (notif['color'] as Color? ?? const Color(0xFF25258F)).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        notif['icon'] as IconData? ?? Icons.notifications,
                        color: notif['color'] as Color? ?? const Color(0xFF25258F),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notif['title'] as String? ?? '',
                                  style: TextStyle(
                                    color: isRead ? const Color(0xFF20283A) : const Color(0xFF1A1A60),
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                    fontSize: 14.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                notif['time'] as String? ?? '',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            notif['description'] as String? ?? '',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isRead)
                      Padding(
                        padding: const EdgeInsets.only(left: 10, top: 4),
                        child: Container(
                          width: 9,
                          height: 9,
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
