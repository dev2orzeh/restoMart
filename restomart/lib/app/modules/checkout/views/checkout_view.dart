import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_text_styles.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../orders/controllers/orders_controller.dart';
import '../controllers/address_controller.dart';
import 'location_picker_view.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/services/email_service.dart';
import '../../../core/services/pdf_invoice_service.dart';
import '../../../core/services/ledger_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../orders/views/orders_view.dart';
import '../../../core/services/woocommerce_api_service.dart';
import '../../../widgets/custom_text_field.dart';
class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  String selectedPayment = 'Cash on delivery';
  int currentStep = 1; // 1=Personal, 2=Payment, 3=Confirmation
  String? _orderNumber;
  bool isPlacingOrder = false;
  
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController(text: 'Karachi Kitchen');
  final TextEditingController _nameController = TextEditingController(text: 'Muhammad Ali');
  final TextEditingController _phoneController = TextEditingController(text: '+92 321 1655556');
  final AddressController addressController = Get.put(AddressController());
  
  bool _isEditingPersonalInfo = false;

  @override
  void dispose() {
    _instructionsController.dispose();
    _storeNameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _generateOrderNumber() {
    final random = Random();
    final number = random.nextInt(90000) + 10000;
    return 'RM-$number';
  }

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final double subtotal = cartController.totalPrice;
    final double shipping = subtotal > 0 ? 150.0 : 0.0;
    final double total = subtotal + shipping;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () {
            if (currentStep > 1 && currentStep < 3) {
              setState(() => currentStep--);
            } else {
              Get.back();
            }
          },
        ),
        title: Text(
          currentStep == 3 ? 'Order Confirmed' : 'Checkout',
          style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: currentStep == 3
          ? _buildConfirmationScreen()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Progress Bar ─────────────────────────────────
                  _buildProgressBar(),
                  const SizedBox(height: 32),

                  if (currentStep == 1) ...[
                    // ── STEP 1: Personal Info + Address ──────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Personal Information', style: AppTextStyles.headingMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(_isEditingPersonalInfo ? Icons.check : Icons.edit, color: const Color(0xFF25258F)),
                          onPressed: () {
                            setState(() {
                              _isEditingPersonalInfo = !_isEditingPersonalInfo;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _storeNameController,
                      hintText: 'Store Name',
                      prefixIcon: Icons.store,
                      readOnly: !_isEditingPersonalInfo,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _nameController,
                      hintText: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      readOnly: !_isEditingPersonalInfo,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneController,
                      hintText: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      readOnly: !_isEditingPersonalInfo,
                    ),
                    const SizedBox(height: 24),

                    // ── Delivery Address ─────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Delivery Address', style: AppTextStyles.headingMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () async {
                            final result = await Get.to(() => const LocationPickerView());
                            if (result != null) {
                              addressController.addAddress(
                                'New Location',
                                result['address'] as String,
                              );
                            }
                          },
                          child: const Text('+ Add New', style: TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Column(
                          children: List.generate(addressController.savedAddresses.length, (index) {
                            final addr = addressController.savedAddresses[index];
                            final isSelected = addressController.selectedAddressIndex.value == index;
                            return GestureDetector(
                              onTap: () => addressController.selectAddress(index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF0F0FF) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF25258F) : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: isSelected ? const Color(0xFF25258F) : Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(addr['label']!, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                        if (index == 0) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFF25258F), borderRadius: BorderRadius.circular(8)),
                                            child: const Text('Default', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(addr['address']!, style: AppTextStyles.label.copyWith(color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF25258F), size: 22),
                            ],
                          ),
                        ),
                      );
                    }))),
                    const SizedBox(height: 24),

                    // ── Your Order Summary ───────────────────────
                    Text('Your Order', style: AppTextStyles.headingMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          ...List.generate(cartController.cartItems.length, (index) {
                            final item = cartController.cartItems[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: index < cartController.cartItems.length - 1 ? 12 : 0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: item.imagePath.isEmpty
                                        ? Container(width: 48, height: 48, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey))
                                        : item.imagePath.startsWith('http')
                                            ? Image.network(item.imagePath, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 48, height: 48, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)))
                                            : Image.asset(item.imagePath, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 48, height: 48, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text('x${item.quantity}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                  Text('Rs. ${(item.price * item.quantity).toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Special Instructions (Optional)', style: AppTextStyles.headingMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _instructionsController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Please pack sauces separately',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 80),
                  ],

                  if (currentStep == 2) ...[
                    // ── STEP 2: Payment Method ───────────────────
                    Text('Payment Method', style: AppTextStyles.headingMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildPaymentOption(Icons.money, 'Cash on delivery', Colors.deepOrange),
                    const SizedBox(height: 12),
                    _buildPaymentOption(Icons.account_balance, 'Bank Transfer', Colors.deepOrange),
                    if (selectedPayment == 'Bank Transfer') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Please transfer the total amount to:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 12),
                            _buildBankRow('Bank:', 'MCB Bank Limited'),
                            const SizedBox(height: 8),
                            _buildBankRow('Account #:', '1538016401000300'),
                            const SizedBox(height: 8),
                            _buildBankRow('Title:', 'RestoMart'),
                            const SizedBox(height: 12),
                            const Text(
                              'Please send screenshot or email at order@restomart.pk or +92 321 1655556 after confirmation your order will be dispatched.', 
                              style: TextStyle(fontSize: 11, color: Colors.orange, fontStyle: FontStyle.italic)
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildPaymentOption(
                      Icons.credit_card, 
                      'Credit Card / Online Payment', 
                      Colors.blue,
                      onTapOverride: () {
                        Get.snackbar(
                          'Coming Soon', 
                          "Sorry, this feature is coming very soon. It's not available yet.",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.white,
                        );
                      }
                    ),
                    const SizedBox(height: 32),

                    // ── Order Info ────────────────────────────────
                    Text('Order Info', style: AppTextStyles.headingMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildInfoRow('Subtotal', 'Rs. ${subtotal.toInt()}'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Shipping', 'Rs. ${shipping.toInt()}'),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow('Total', 'Rs. ${total.toInt()}', isBold: true),
                    const SizedBox(height: 80),
                  ],
                ],
              ),
            ),
      bottomSheet: currentStep < 3
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total', style: AppTextStyles.label.copyWith(color: Colors.grey.shade600)),
                        Text('Rs. ${total.toInt()}', style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 24)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: isPlacingOrder ? null : () async {
                        if (currentStep == 1) {
                          setState(() => currentStep = 2);
                        } else if (currentStep == 2) {
                          setState(() {
                            isPlacingOrder = true;
                          });

                          try {
                            // Generate order number (local reference)
                            _orderNumber = _generateOrderNumber();
                            final cartController = Get.find<CartController>();
                            final ordersController = Get.isRegistered<OrdersController>()
                                ? Get.find<OrdersController>()
                                : Get.put(OrdersController(), permanent: true);

                            // --- WOOCOMMERCE LIVE CHECKOUT ---
                            // 1. Build line items
                            final List<Map<String, dynamic>> lineItems = cartController.cartItems.map((item) {
                              return {
                                "product_id": int.tryParse(item.id) ?? 0, 
                                "name": item.name,
                                "quantity": item.quantity,
                              };
                            }).toList();
                            
                            // 2. Build Customer Details (Using hardcoded user data or address picker)
                            final activeAddr = addressController.savedAddresses[addressController.selectedAddressIndex.value];
                            final billing = {
                              "first_name": "Muhammad",
                              "last_name": "Ali",
                              "address_1": activeAddr['address'],
                              "city": "Karachi",
                              "state": "SD",
                              "postcode": "75000",
                              "country": "PK",
                              "email": FirebaseAuth.instance.currentUser?.email ?? "customer@restomart.pk",
                              "phone": "+923211655556"
                            };

                            final payload = {
                              "payment_method": selectedPayment == 'Cash on delivery' ? "cod" : "bacs",
                              "payment_method_title": selectedPayment,
                              "set_paid": false,
                              "billing": billing,
                              "shipping": billing,
                              "line_items": lineItems,
                              "shipping_lines": [
                                {
                                  "method_id": "flat_rate",
                                  "method_title": "Delivery Fee",
                                  "total": shipping.toString()
                                }
                              ],
                              "customer_note": _instructionsController.text
                            };

                            // 3. Post to WordPress
                            String? wooOrderId = await WooCommerceApiService.createOrder(payload);

                            if (wooOrderId != null) {
                              _orderNumber = wooOrderId; // Update local order number to match WooCommerce

                              final newOrder = OrderModel(
                                id: _orderNumber!,
                                date: DateTime.now(),
                                total: total,
                                status: 'Processing',
                                paymentMethod: selectedPayment,
                                specialInstructions: _instructionsController.text,
                                items: List.from(cartController.cartItems), // Clone list
                              );

                              // Save to local orders history
                              ordersController.addOrder(newOrder);

                              cartController.clearCart();
                              
                              // Ledger: Ensure account and record debit
                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                final uid = user?.uid ?? 'guest';
                                final email = user?.email ?? 'guest@restomart.pk';
                                
                                await LedgerService.ensureAccountExists(
                                  uid: uid,
                                  name: _nameController.text.isNotEmpty ? _nameController.text : 'Guest Customer',
                                  email: email,
                                  phone: _phoneController.text.isNotEmpty ? _phoneController.text : '+920000000000',
                                );
                                
                                await LedgerService.recordOrderDebit(
                                  uid: uid,
                                  orderId: _orderNumber!,
                                  amount: total,
                                  paymentMethod: selectedPayment,
                                );
                              } catch (e) {
                                print("Ledger error: $e");
                              }
                              
                              // Trigger local notification safely
                              try {
                                PushNotificationService.showOrderSuccessNotification(_orderNumber!);
                              } catch (e) {
                                print("Notification failed: $e");
                              }

                              // Send Invoice Email via SMTP to the logged-in user
                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  WooCommerceApiService.markCartConverted(user.uid);
                                  final currentUserEmail = user.email;
                                  if (currentUserEmail != null && currentUserEmail.isNotEmpty) {
                                    PdfInvoiceService.generateInvoiceBytes(newOrder).then((pdfBytes) {
                                      EmailService.sendInvoiceEmail(
                                        recipientEmail: currentUserEmail,
                                        order: newOrder,
                                        pdfBytes: pdfBytes,
                                      ).catchError((e) => print("Email error: $e"));
                                    }).catchError((e) => print("PDF error: $e"));
                                  }
                                }
                              } catch (e) {
                                print("Email sequence failed: $e");
                              }

                              setState(() {
                                isPlacingOrder = false;
                                currentStep = 3;
                              });
                            } else {
                              setState(() {
                                isPlacingOrder = false;
                              });
                              Get.snackbar(
                                'Checkout Failed', 
                                'There was a problem sending your order to the server. Please try again.',
                                backgroundColor: Colors.red.shade600,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          } catch (e) {
                            print("Checkout exception: $e");
                            setState(() {
                              isPlacingOrder = false;
                            });
                            Get.snackbar(
                              'Checkout Error', 
                              'An unexpected error occurred: $e',
                              backgroundColor: Colors.red.shade600,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48), // Overrides global theme infinite width
                        backgroundColor: const Color(0xFF25258F),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isPlacingOrder 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            currentStep == 1 ? 'Continue to Payment' : 'Place Order',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildConfirmationScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success Check Animation
            SizedBox(
              width: 150,
              height: 150,
              child: Lottie.asset(
                'assets/images/ORDER CONFIRMED svg.json',
                repeat: false,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your order has been confirmed.\nWe will deliver it to your restaurant soon.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Order Number Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF25258F).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text('Order Number', style: TextStyle(fontSize: 14, color: Color(0xFF25258F))),
                  const SizedBox(height: 8),
                  Text(
                    _orderNumber ?? 'RM-00000',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF25258F), letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Payment: $selectedPayment',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // View My Order
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.until((route) => route.isFirst);
                  Get.to(() => const OrdersView());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25258F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View My Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            
            // Or Back to Home
            TextButton(
              onPressed: () {
                  Get.until((route) => route.isFirst);
              },
              child: Text('Back to Home', style: TextStyle(color: Colors.grey.shade600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          children: [
            _buildStepCircle(step: 1),
            _buildStepLine(isActive: currentStep >= 2),
            _buildStepCircle(step: 2),
            _buildStepLine(isActive: currentStep >= 3),
            _buildStepCircle(step: 3),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ADDRESS', style: _stepLabelStyle(currentStep >= 1)),
            Text('PAYMENT', style: _stepLabelStyle(currentStep >= 2)),
            Text('CONFIRM', style: _stepLabelStyle(currentStep >= 3)),
          ],
        ),
      ],
    );
  }

  TextStyle _stepLabelStyle(bool isActive) {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: isActive ? const Color(0xFF25258F) : Colors.grey.shade400,
    );
  }

  Widget _buildStepCircle({required int step}) {
    final isCompleted = currentStep > step;
    final isActive = currentStep >= step;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? const Color(0xFF25258F) : (isActive ? const Color(0xFFFFD54F) : Colors.white),
        border: Border.all(color: isActive ? const Color(0xFF25258F) : Colors.grey.shade300, width: 2),
      ),
      child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
    );
  }

  Widget _buildStepLine({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? const Color(0xFF25258F) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: isBold ? Colors.black : Colors.grey.shade600)),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
      ],
    );
  }

  Widget _buildBankRow(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87))),
      ],
    );
  }

  Widget _buildPaymentOption(IconData icon, String title, Color iconColor, {VoidCallback? onTapOverride}) {
    bool isSelected = selectedPayment == title;
    return InkWell(
      onTap: onTapOverride ?? () => setState(() => selectedPayment = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF25258F) : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF25258F) : iconColor),
            const SizedBox(width: 12),
            Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF25258F), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptionSmall(IconData icon, String title) {
    bool isSelected = selectedPayment == title;
    return InkWell(
      onTap: () => setState(() => selectedPayment = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF25258F) : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF25258F) : Colors.black54, size: 20),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
