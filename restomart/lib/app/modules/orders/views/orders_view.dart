import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/orders_controller.dart';
import '../../../core/services/pdf_invoice_service.dart';
import 'order_tracking_view.dart';

class OrdersView extends StatelessWidget {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    // Make sure controller is initialized
    final ordersController = Get.isRegistered<OrdersController>()
        ? Get.find<OrdersController>()
        : Get.put(OrdersController(), permanent: true);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'My Orders',
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (ordersController.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 24),
                Text(
                  'No orders yet',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your past orders will appear here',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: ordersController.orders.length,
          itemBuilder: (context, index) {
            final order = ordersController.orders[index];
            return _buildOrderCard(order, ordersController);
          },
        );
      }),
    );
  }

  Widget _buildOrderCard(OrderModel order, OrdersController controller) {
    return GestureDetector(
      onTap: () => Get.to(() => OrderTrackingView(order: order)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              if (order.status.value.toLowerCase().contains('deliver')) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Order Delivered Successfully!',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Obx(() {
                  final statusStr = order.status.value.toLowerCase();
                  final isCancelled = statusStr.contains('cancel');
                  final isDelivered = statusStr.contains('deliver') || statusStr.contains('complet');
                  
                  Color bgColor;
                  Color textColor;
                  
                  if (isCancelled) {
                    bgColor = Colors.red.shade50;
                    textColor = Colors.red.shade700;
                  } else if (isDelivered) {
                    bgColor = Colors.green.shade50;
                    textColor = Colors.green.shade700;
                  } else {
                    bgColor = Colors.blue.shade50;
                    textColor = Colors.blue.shade700;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status.value,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(order.date),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const Divider(height: 24),
            Text(
              '${order.items.length} Items',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...order.items
                .take(2)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          '${item.quantity}x ',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(color: Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (order.items.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${order.items.length - 2} more items',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${order.total.toInt()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Obx(() {
                  final statusStr = order.status.value.toLowerCase();
                  final isCancelled = statusStr.contains('cancel');
                  final isDelivered = statusStr.contains('deliver') || statusStr.contains('complet');
                  
                  return Wrap(
                    spacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: (isCancelled || isDelivered) ? null : () {
                          Get.to(() => OrderTrackingView(order: order));
                        },
                        icon: Icon(
                          Icons.my_location,
                          size: 16,
                          color: (isCancelled || isDelivered) ? Colors.grey : AppColors.primary,
                        ),
                        label: Text(
                          'Track',
                          style: TextStyle(
                            color: (isCancelled || isDelivered) ? Colors.grey : AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: isCancelled ? null : () async {
                          Get.snackbar(
                            'Generating Invoice',
                            'Please wait while your PDF is being generated...',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.blue.shade50,
                            colorText: Colors.blue.shade800,
                            icon: Icon(
                              Icons.picture_as_pdf,
                              color: Colors.blue.shade800,
                            ),
                            duration: const Duration(seconds: 2),
                          );

                          // Generate and Download PDF
                          await PdfInvoiceService.generateAndPrintInvoice(order);
                        },
                        icon: Icon(
                          Icons.download,
                          size: 16,
                          color: isCancelled ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                        label: Text(
                          'Invoice',
                          style: TextStyle(
                            color: isCancelled ? Colors.grey.shade400 : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => controller.reorder(order),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text(
                          'Re-order',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
