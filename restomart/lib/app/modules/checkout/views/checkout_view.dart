import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../auth/controllers/auth_controller.dart';

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
  
  late final TextEditingController _instructionsController;
  late final TextEditingController _storeNameController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _manualAddressInputController;
  final AddressController addressController = Get.put(AddressController());
  
  bool _isEditingPersonalInfo = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    String name = user?.displayName ?? '';
    String phone = '';
    
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      if (name.isEmpty) name = auth.userName.value;
      phone = auth.userPhone.value;
      _storeNameController = TextEditingController(text: auth.businessName.value.isNotEmpty ? auth.businessName.value : (name.isNotEmpty ? '$name Store' : ''));
    } else {
      _storeNameController = TextEditingController(text: name.isNotEmpty ? '$name Store' : '');
    }

    _instructionsController = TextEditingController();
    _nameController = TextEditingController(text: name);
    _phoneController = TextEditingController(text: phone);
    _manualAddressInputController = TextEditingController();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _storeNameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _manualAddressInputController.dispose();
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
    final double discount = cartController.discountAmount.value;
    final double shipping = (cartController.finalTotal > 0 && cartController.finalTotal < 500) ? 150.0 : 0.0;
    final double total = cartController.finalTotal + shipping;

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
                                (result['label'] as String?) ?? 'New Location',
                                result['address'] as String,
                              );
                            }
                          },
                          child: const Text('+ Add New', style: TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      if (addressController.savedAddresses.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Type Delivery Address Manually', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF25258F))),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _manualAddressInputController,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  hintText: 'e.g. House #12, Street 4, DHA Phase 6, Lahore',
                                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF25258F), width: 2)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final text = _manualAddressInputController.text.trim();
                                    if (text.isNotEmpty) {
                                      addressController.addAddress('Home', text);
                                      _manualAddressInputController.clear();
                                    } else {
                                      Get.snackbar('Address Required', 'Please type your address in the box.');
                                    }
                                  },
                                  icon: const Icon(Icons.add_location_alt, size: 18),
                                  label: const Text('Save & Select Address'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25258F),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
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
                        }),
                      );
                    }),
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
                    if (discount > 0) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Discount', '- Rs. ${discount.toInt()}', valueColor: Colors.green),
                    ],
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
                          if (addressController.savedAddresses.isEmpty) {
                            final manualText = _manualAddressInputController.text.trim();
                            if (manualText.isNotEmpty) {
                              addressController.addAddress('Home', manualText);
                              _manualAddressInputController.clear();
                            } else {
                              Get.snackbar(
                                'Address Required',
                                'Please enter or type your delivery address to continue.',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.red.shade50,
                                colorText: Colors.red.shade900,
                              );
                              return;
                            }
                          }
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
                            final Map<String, dynamic> activeAddr = addressController.savedAddresses.isNotEmpty
                                ? addressController.savedAddresses[addressController.selectedAddressIndex.value]
                                : {'address': 'Default Address, Pakistan'};
                            final billing = {
                              "first_name": _nameController.text.isNotEmpty ? _nameController.text : "Guest",
                              "last_name": "Customer",
                              "address_1": activeAddr['address'],
                              "city": "Lahore",
                              "state": "PB",
                              "postcode": "54000",
                              "country": "PK",
                              "email": FirebaseAuth.instance.currentUser?.email ?? "customer@restomart.pk",
                              "phone": _phoneController.text.isNotEmpty ? _phoneController.text : "00000000000"
                            };

                            final payload = {
                              "payment_method": selectedPayment == 'Cash on delivery' ? "cod" : "bacs",
                              "payment_method_title": selectedPayment,
                              "set_paid": false,
                              "billing": billing,
                              "shipping": billing,
                              "line_items": lineItems,
                              if (cartController.appliedCouponCode.value != null && cartController.appliedCouponCode.value!.isNotEmpty)
                                "coupon_lines": [
                                  {
                                    "code": cartController.appliedCouponCode.value
                                  }
                                ],
                              "shipping_lines": [
                                {
                                  "method_id": "flat_rate",
                                  "method_title": "Delivery Fee",
                                  "total": shipping.toString()
                                }
                              ],
                              "customer_note": _instructionsController.text
                            };

                            // 3. Post to WordPress (attempt WooCommerce API)
                            String? wooOrderId;
                            try {
                              wooOrderId = await WooCommerceApiService.createOrder(payload);
                            } catch (e) {
                              print("WooCommerce API Exception: $e");
                            }

                            if (wooOrderId != null && wooOrderId.isNotEmpty) {
                              _orderNumber = wooOrderId;
                            } else {
                              _orderNumber = _orderNumber ?? _generateOrderNumber();
                            }

                            final newOrder = OrderModel(
                              id: _orderNumber!,
                              date: DateTime.now(),
                              total: total,
                              status: 'pending',
                              paymentMethod: selectedPayment,
                              specialInstructions: _instructionsController.text,
                              items: List.from(cartController.cartItems), // Clone list
                            );

                            // Save to local orders history & Firestore
                            await ordersController.addOrder(
                              newOrder,
                              customerName: _nameController.text,
                              phone: _phoneController.text,
                              address: activeAddr['address'],
                            );

                            if (cartController.appliedCouponCode.value != null) {
                              final usedCode = cartController.appliedCouponCode.value!.toUpperCase();
                              if (usedCode == 'WELCOME10' || usedCode == 'SAVE500') {
                                final prefs = await SharedPreferences.getInstance();
                                final user = FirebaseAuth.instance.currentUser;
                                final uid = user?.uid ?? 'guest';
                                final key = 'used_promo_${usedCode}_$uid';
                                await prefs.setBool(key, true);
                              }
                            }

                            cartController.clearCart();
                            
                            // Ledger: Ensure account exists
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
                                  final pdfBytes = await PdfInvoiceService.generateInvoiceBytes(newOrder);
                                  await EmailService.sendInvoiceEmail(
                                    recipientEmail: currentUserEmail,
                                    order: newOrder,
                                    pdfBytes: pdfBytes,
                                  );
                                }
                              }
                            } catch (e) {
                              print("Email sequence failed: $e");
                            }

                            setState(() {
                              isPlacingOrder = false;
                              currentStep = 3;
                            });
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Prominent Big Green Tick Mark Icon
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x332E7D32),
                    blurRadius: 20,
                    spreadRadius: 4,
                  )
                ],
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 88,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Confirmed!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), letterSpacing: 0.3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Your order has been confirmed successfully.\nWe will deliver it to your restaurant soon.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Order Number Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x4D25258F)),
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

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: isBold ? Colors.black : Colors.grey.shade600)),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: valueColor)),
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
