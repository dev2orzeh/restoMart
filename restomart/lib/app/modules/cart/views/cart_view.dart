import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/cart_controller.dart';
import '../controllers/templates_controller.dart';
import '../../checkout/views/checkout_view.dart';
import '../../main/views/all_products_view.dart';
import '../../../widgets/confirmation_dialog.dart';

class CartView extends StatelessWidget {
  CartView({super.key});

  final CartController cartController = Get.find<CartController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: Text(
          'My Cart',
          style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (cartController.cartItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.grey.shade300),
                const SizedBox(height: 24),
                Text(
                  'Your cart is empty',
                  style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add items to your cart to continue',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final double subtotal = cartController.totalPrice;
        final double discount = cartController.discountAmount.value;
        final double shipping = subtotal > 0 ? 150.0 : 0.0;
        final double total = (subtotal - discount + shipping) < 0 ? 0 : (subtotal - discount + shipping);

        return Column(
          children: [
            // ── Scrollable Content ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cart items
                    ...cartController.cartItems.map((item) => _buildCartItem(item)),
                    
                    // Add more items button
                    Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: () {
                          // Navigate back to home if we came from there, or push AllProductsView
                          Get.to(() => const AllProductsView());
                        },
                        icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF25258F), size: 18),
                        label: const Text('Add more items', style: TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold, fontSize: 13)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          backgroundColor: const Color(0xFF25258F).withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: const Color(0xFF25258F).withValues(alpha: 0.2)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Summary section at the end
                    _buildSummarySection(subtotal, discount, shipping, total),
                  ],
                ),
              ),
            ),

            // ── Proceed Button Bar ──────────────────────────────
            _buildProceedBar(total),
          ],
        );
      }),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imagePath.isEmpty
                  ? Icon(Icons.fastfood, color: Colors.grey.shade400, size: 36)
                  : item.imagePath.startsWith('http')
                      ? Image.network(item.imagePath, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.fastfood, color: Colors.grey.shade400, size: 36)))
                      : Image.asset(item.imagePath, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.fastfood, color: Colors.grey.shade400, size: 36))),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '1 Kg',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity Controls
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _quantityButton('–', () {
                            if (item.quantity > 1) {
                              cartController.updateQuantity(item, item.quantity - 1);
                            } else {
                              cartController.removeItem(item);
                            }
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          _quantityButton('+', () {
                            cartController.updateQuantity(item, item.quantity + 1);
                          }),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${(item.price * item.quantity).toInt()}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Delete Button
          GestureDetector(
            onTap: () async {
              final confirm = await Get.dialog<bool>(
                ConfirmationDialog(
                  title: 'Remove ${item.name}?',
                  cancelText: 'Cancel',
                  confirmText: 'Remove',
                  onConfirm: () => Get.back(result: true),
                ),
              );
              if (confirm == true) {
                cartController.removeItem(item);
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSummarySection(double subtotal, double discount, double shipping, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.black12),
        const SizedBox(height: 12),

        // Order Note
        SizedBox(
          height: 48,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Add order note (Optional)',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              prefixIcon: const Icon(Icons.receipt_long_outlined, color: Colors.black54, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: 1,
          ),
        ),

        const SizedBox(height: 12),
        const Divider(color: Colors.black12),
        const SizedBox(height: 12),

        // Promo Code
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: cartController.promoController,
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final code = cartController.promoController.text.trim();
                  if (code.isNotEmpty) {
                    // Show loading
                    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                    final success = await cartController.applyCoupon(code);
                    Get.back(); // close dialog
                    if (success) {
                      Get.snackbar('Success', 'Coupon applied successfully!', backgroundColor: Colors.green, colorText: Colors.white);
                    } else {
                      Get.snackbar('Error', 'Invalid or expired coupon code.', backgroundColor: Colors.red, colorText: Colors.white);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: const Color(0xFFFFC400),
                  foregroundColor: const Color(0xFF25258F),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
        
        if (cartController.appliedCouponCode.value != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                const SizedBox(width: 8),
                Text('Coupon applied: ${cartController.appliedCouponCode.value}', style: TextStyle(color: Colors.green.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    cartController.removeCoupon();
                    cartController.promoController.clear();
                  },
                  child: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // Calculations
        _buildCalcRow('Subtotal', 'Rs. ${subtotal.toInt()}'),
        if (discount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Discount', style: TextStyle(fontSize: 14, color: Colors.red.shade600)),
                Text('- Rs. ${discount.toInt()}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red.shade600)),
              ],
            ),
          ),
        const SizedBox(height: 10),
        _buildCalcRow('Shipping', 'Rs. ${shipping.toInt()}'),
        const SizedBox(height: 12),
        const Divider(color: Colors.black12),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            Text('Rs. ${total.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCalcRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  Widget _buildProceedBar(double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                final CartController cartController = Get.find<CartController>();

                if (cartController.cartItems.isEmpty) {
                  Get.snackbar(
                    'Cart is Empty',
                    'Please add products before checkout.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.shade600,
                    colorText: Colors.white,
                  );
                  return;
                }

                Get.to(() => const CheckoutView());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC400),
                foregroundColor: const Color(0xFF25258F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Proceed to Checkout • Rs. ${total.toInt()}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: Colors.black54),
              SizedBox(width: 4),
              Text('Secure checkout', style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}
