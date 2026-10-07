import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/orders_controller.dart';
import '../../../core/services/pdf_invoice_service.dart';

class OrderTrackingView extends StatelessWidget {
  final OrderModel order;

  const OrderTrackingView({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
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
          'Track Order',
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order ID & Status Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Amount: Rs. ${order.total.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Get.snackbar(
                              'Generating Invoice',
                              'Please wait while your PDF is being generated...',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.blue.shade50,
                              colorText: Colors.blue.shade800,
                              icon: Icon(Icons.picture_as_pdf, color: Colors.blue.shade800),
                              duration: const Duration(seconds: 2),
                            );
                            await PdfInvoiceService.generateAndPrintInvoice(order);
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Invoice'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (Get.isRegistered<OrdersController>()) {
                              Get.find<OrdersController>().reorder(order);
                            }
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reorder'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Visual Tracking Timeline
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Obx(() {
                final liveOrder = Get.find<OrdersController>().orders.firstWhere(
                  (o) => o.id == order.id,
                  orElse: () => order,
                );
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Status',
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (liveOrder.status.value.toLowerCase().contains('cancelled'))
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.cancel, color: Colors.red.shade700, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'Order Cancelled',
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      _buildTrackingTimeline(liveOrder.status.value),
                      const SizedBox(height: 24),
                      if (liveOrder.status.value.toLowerCase().contains('delivered') || liveOrder.status.value.toLowerCase().contains('completed'))
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                'Order Successfully Delivered!',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              final st = liveOrder.status.value.toLowerCase();
                              if (st.contains('shipped')) {
                                Get.snackbar(
                                  'Cannot Cancel',
                                  'Order cannot be cancelled after it has been shipped.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.orange.shade50,
                                  colorText: Colors.orange.shade900,
                                );
                                return;
                              }

                              final timeSinceOrder = DateTime.now().difference(liveOrder.date);
                              if (timeSinceOrder.inMinutes > 30) {
                                Get.snackbar(
                                  'Cancellation Timeout',
                                  'Orders can only be cancelled within 30 minutes of placing them. Please contact support.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.orange.shade50,
                                  colorText: Colors.orange.shade900,
                                  duration: const Duration(seconds: 4),
                                );
                                return;
                              }
                              Get.defaultDialog(
                                title: 'Cancel Order?',
                                middleText:
                                    'Are you sure you want to request cancellation for this order? This action cannot be undone.',
                                textConfirm: 'Yes, Cancel',
                                textCancel: 'No',
                                confirmTextColor: AppColors.primary,
                                buttonColor: AppColors.accent,
                                cancelTextColor: AppColors.primary,
                                onConfirm: () {
                                  Get.back(); // close dialog
                                  Get.find<OrdersController>().cancelOrder(order.id);
                                  Get.snackbar(
                                    'Cancellation Requested',
                                    'Your order has been successfully cancelled.',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red.shade50,
                                    colorText: Colors.red.shade900,
                                  );
                                },
                              );
                            },
                            child: const Text(
                              'Request Cancellation',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
              );
            }),
          ),

            const SizedBox(height: 24),

            // Items
            Text(
              'Items Ordered',
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...order.items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: item.imagePath.startsWith('http')
                        ? Image.network(item.imagePath, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image))
                        : Image.asset(item.imagePath, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Qty: ${item.quantity}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${(item.price * item.quantity).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingTimeline(String currentStatus) {
    // Basic mapping for visual timeline
    int currentStep = 0;
    String status = currentStatus.toLowerCase();
    if (status.contains('processing') || status.contains('accepted')) {
      currentStep = 1;
    } else if (status.contains('shipped') || status.contains('way')) {
      currentStep = 2;
    } else if (status.contains('delivered') || status.contains('completed')) {
      currentStep = 3;
    }

    final steps = [
      {'title': 'Order Placed', 'icon': Icons.inventory_2_outlined},
      {'title': 'Processing', 'icon': Icons.access_time},
      {'title': 'Shipped', 'icon': Icons.local_shipping_outlined},
      {'title': 'Delivered', 'icon': Icons.check_circle_outline},
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        bool isActive = index <= currentStep;
        bool isLast = index == steps.length - 1;

        return Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Left Line
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 0
                          ? Colors.transparent
                          : (isActive
                                ? const Color(0xFF4C4DDC)
                                : Colors.grey.shade300),
                    ),
                  ),
                  // Circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF4C4DDC)
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      steps[index]['icon'] as IconData,
                      color: isActive ? Colors.white : Colors.grey.shade500,
                      size: 20,
                    ),
                  ),
                  // Right Line
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isLast
                          ? Colors.transparent
                          : (index < currentStep
                                ? const Color(0xFF4C4DDC)
                                : Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                steps[index]['title'] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? const Color(0xFF4C4DDC)
                      : Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}
