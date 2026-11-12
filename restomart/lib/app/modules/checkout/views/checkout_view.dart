import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/google_maps_service.dart';
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
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../orders/views/orders_view.dart';
import '../../../core/services/woocommerce_api_service.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../core/utils/error_handler.dart';
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

    // Auto-load and select primary default address when opening checkout
    addressController.loadAddressesForCurrentUser().then((_) {
      if (mounted && addressController.savedAddresses.isNotEmpty) {
        addressController.selectedAddressIndex.value = 0;
      }
    });

    // Auto-fill user profile (Phone, Name, Business) from local cache and Firestore
    _loadAutoFillProfile();
  }

  Future<void> _loadAutoFillProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPhone = prefs.getString('cached_user_phone_${user.uid}');
      final cachedName = prefs.getString('cached_user_name_${user.uid}');
      final cachedBiz = prefs.getString('cached_user_business_${user.uid}');

      if (mounted) {
        if (_phoneController.text.isEmpty && cachedPhone != null && cachedPhone.isNotEmpty) {
          _phoneController.text = cachedPhone;
        }
        if (_nameController.text.isEmpty && cachedName != null && cachedName.isNotEmpty) {
          _nameController.text = cachedName;
        }
        if (_storeNameController.text.isEmpty && cachedBiz != null && cachedBiz.isNotEmpty) {
          _storeNameController.text = cachedBiz;
        }
      }

      // If phone is still empty, fetch from Firestore users doc directly
      if (_phoneController.text.isEmpty || _nameController.text.isEmpty) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final fsPhone = (data['phone'] as String?) ?? (data['phoneNumber'] as String?) ?? '';
          final fsName = (data['name'] as String?) ?? (data['displayName'] as String?) ?? '';
          final fsBiz = (data['restaurantName'] as String?) ?? (data['businessName'] as String?) ?? '';

          if (mounted) {
            setState(() {
              if (_phoneController.text.isEmpty && fsPhone.isNotEmpty) {
                _phoneController.text = fsPhone;
                prefs.setString('cached_user_phone_${user.uid}', fsPhone);
                if (Get.isRegistered<AuthController>()) {
                  Get.find<AuthController>().userPhone.value = fsPhone;
                }
              }
              if (_nameController.text.isEmpty && fsName.isNotEmpty) {
                _nameController.text = fsName;
                prefs.setString('cached_user_name_${user.uid}', fsName);
              }
              if (_storeNameController.text.isEmpty && fsBiz.isNotEmpty) {
                _storeNameController.text = fsBiz;
                prefs.setString('cached_user_business_${user.uid}', fsBiz);
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Checkout autofill profile error: $e');
    }
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

  void _showQuickAddAddressModal(BuildContext context) {
    final TextEditingController labelCtrl = TextEditingController(text: 'Work');
    final TextEditingController addrCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Delivery Address', style: TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Label (e.g., Home, Shop, Branch 2)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: addrCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address Details',
                hintText: 'Building, Shop #, Street, City',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = addrCtrl.text.trim();
              if (text.isNotEmpty) {
                final label = labelCtrl.text.trim().isEmpty ? 'Address' : labelCtrl.text.trim();
                addressController.addAddress(label, text);
                Get.back();
                AppErrorHandler.showSuccess('Address Saved', 'Selected for delivery');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25258F), foregroundColor: Colors.white),
            child: const Text('Save & Select'),
          ),
        ],
      ),
    );
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
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _showQuickAddAddressModal(context),
                              icon: const Icon(Icons.edit_note, size: 16, color: Color(0xFF25258F)),
                              label: const Text('Type Address', style: TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final result = await Get.to(() => const LocationPickerView());
                                if (result != null) {
                                  addressController.addAddress(
                                    (result['label'] as String?) ?? 'New Location',
                                    result['address'] as String,
                                    lat: (result['lat'] as num?)?.toDouble(),
                                    lng: (result['lng'] as num?)?.toDouble(),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add_location_alt, size: 16, color: Color(0xFF25258F)),
                              label: const Text('Map', style: TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
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
                                      AppErrorHandler.showWarning('Address Required', 'Please type your address in the box.');
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: const Text('Save & Select Address'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25258F),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final result = await Get.to(() => const LocationPickerView());
                                    if (result != null && result['address'] != null) {
                                      addressController.addAddress(
                                        (result['label'] as String?) ?? 'New Location',
                                        result['address'] as String,
                                        lat: (result['lat'] as num?)?.toDouble(),
                                        lng: (result['lng'] as num?)?.toDouble(),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.map_rounded, size: 18, color: Color(0xFF25258F)),
                                  label: const Text('Or Pick on Map / GPS', style: TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: const BorderSide(color: Color(0xFF25258F), width: 1.5),
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
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: Color(0xFF25258F), size: 22),
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
                    _buildPaymentOption(Icons.payments_rounded, 'Cash on delivery', const Color(0xFF2E7D32)),
                    const SizedBox(height: 12),
                    _buildPaymentOption(Icons.account_balance_rounded, 'Bank Transfer', const Color(0xFF1565C0)),
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
                            _buildBankRow('Bank:', 'Faysal Bank'),
                            const SizedBox(height: 8),
                            _buildBankRow('Account #:', '3622499000002192', showCopy: true),
                            const SizedBox(height: 8),
                            _buildBankRow('Title:', 'Restomart'),
                            const SizedBox(height: 12),
                            const Text(
                              'Please send screenshot or email at order@restomart.pk or +92 321 1655556 after confirmation your order will be dispatched.', 
                              style: TextStyle(fontSize: 11, color: Colors.orange, fontStyle: FontStyle.italic)
                            ),
                          ],
                        ),
                      ),
                    ],
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: currentStep == 1
                    ? Row(
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
                            onPressed: () {
                              final phone = _phoneController.text.trim();
                              if (phone.isEmpty || phone.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
                                setState(() {
                                  _isEditingPersonalInfo = true;
                                });
                                AppErrorHandler.showWarning(
                                  'Phone Number Mandatory',
                                  'Please enter a valid mobile number so our delivery team can reach you.',
                                );
                                return;
                              }

                              if (addressController.savedAddresses.isEmpty) {
                                final manualText = _manualAddressInputController.text.trim();
                                if (manualText.isNotEmpty) {
                                  addressController.addAddress('Home', manualText);
                                  _manualAddressInputController.clear();
                                } else {
                                  AppErrorHandler.showWarning(
                                    'Address Required',
                                    'Please enter or type your delivery address to continue.',
                                  );
                                  return;
                                }
                              }
                              setState(() => currentStep = 2);
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: const Color(0xFF25258F),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Continue to Payment',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Total Payable', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  Text(
                                    'Rs. ${total.toInt()}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF25258F)),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25258F).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.payments_outlined, size: 14, color: Color(0xFF25258F)),
                                    const SizedBox(width: 5),
                                    Text(
                                      selectedPayment,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF25258F)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // ── LONG SWIPE TO PLACE ORDER BUTTON ──
                          SwipeToPlaceOrderButton(
                            isLoading: isPlacingOrder,
                            text: 'Swipe to Place Order',
                            onSwipeComplete: () => _handlePlaceOrder(total, shipping, addressController),
                          ),
                        ],
                      ),
              ),
            )
          : null,
    );
  }

  Future<void> _handlePlaceOrder(double total, double shipping, AddressController addressController) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
      setState(() {
        currentStep = 1;
        _isEditingPersonalInfo = true;
      });
      AppErrorHandler.showWarning(
        'Phone Number Mandatory',
        'Please provide a valid mobile number for delivery verification.',
      );
      return;
    }

    // Check location mismatch before placing order (e.g. at university vs default home address)
    final activeAddr = addressController.selectedAddress;
    if (activeAddr != null) {
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          final permission = await Geolocator.checkPermission();
          if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 4),
              ),
            );

            double? targetLat = double.tryParse(activeAddr['lat'] ?? '');
            double? targetLng = double.tryParse(activeAddr['lng'] ?? '');

            if (targetLat == null || targetLng == null) {
              final search = await GoogleMapsService.searchAddress(activeAddr['address'] ?? '');
              if (search.isNotEmpty) {
                targetLat = search[0]['lat'] as double?;
                targetLng = search[0]['lon'] as double?;
              }
            }

            if (targetLat != null && targetLng != null) {
              final dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, targetLat, targetLng);
              // If away by > 2.5 km from selected delivery address, ask confirmation
              if (dist > 2500) {
                final bool? proceed = await Get.dialog<bool>(
                  AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: Color(0xFF25258F)),
                        SizedBox(width: 8),
                        Text('Confirm Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You appear to be away from this delivery address:',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activeAddr['address'] ?? activeAddr['label'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Do you still want to deliver here, or order to your current location?',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('Change Address', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25258F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => Get.back(result: true),
                        child: const Text('Yes, Deliver Here', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (proceed != true) {
                  return;
                }
              }
            }
          }
        }
      } catch (locErr) {
        debugPrint('Location verification check ignored: $locErr');
      }
    }

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
        "customer_note": [
          if (_instructionsController.text.isNotEmpty) _instructionsController.text.trim(),
          if (activeAddr['lat'] != null && activeAddr['lng'] != null)
            "📍 Delivery Map Pin: https://www.google.com/maps/search/?api=1&query=${activeAddr['lat']},${activeAddr['lng']}"
        ].join('\n\n')
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
        lat: double.tryParse(activeAddr['lat']?.toString() ?? ''),
        lng: double.tryParse(activeAddr['lng']?.toString() ?? ''),
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
      
      // Ledger: Ensure account exists & record order debit
      try {
        final user = FirebaseAuth.instance.currentUser;
        final uid = user?.uid ?? 'guest';
        final email = user?.email ?? 'guest@restomart.pk';
        
        if (uid != 'guest') {
          await LedgerService.ensureAccountExists(
            uid: uid,
            name: _nameController.text.isNotEmpty ? _nameController.text : 'Customer',
            email: email,
            phone: _phoneController.text.isNotEmpty ? _phoneController.text : '+920000000000',
          );

          await LedgerService.recordOrderDebit(
            uid: uid,
            orderId: _orderNumber!,
            amount: total,
            paymentMethod: selectedPayment,
          );
        }
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
      AppErrorHandler.showError('Checkout Error', e);
    }
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

  Widget _buildBankRow(String label, String value, {bool showCopy = false}) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54))),
        Expanded(
          child: Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              if (showCopy) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    Get.snackbar(
                      'Copied to Clipboard',
                      'Account number copied: $value',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.white,
                      colorText: Colors.black87,
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      duration: const Duration(seconds: 2),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25258F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy, size: 12, color: Color(0xFF25258F)),
                        SizedBox(width: 3),
                        Text(
                          'Copy',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF25258F)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
}

// ============================================================================
// SWIPE TO PLACE ORDER BUTTON
// ============================================================================
class SwipeToPlaceOrderButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onSwipeComplete;
  final String text;

  const SwipeToPlaceOrderButton({
    super.key,
    required this.isLoading,
    required this.onSwipeComplete,
    this.text = 'Swipe to Place Order',
  });

  @override
  State<SwipeToPlaceOrderButton> createState() => _SwipeToPlaceOrderButtonState();
}

class _SwipeToPlaceOrderButtonState extends State<SwipeToPlaceOrderButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resetController.addListener(() {
      setState(() {
        _dragPosition = _resetAnimation.value;
      });
    });
  }

  @override
  void didUpdateWidget(covariant SwipeToPlaceOrderButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) {
      setState(() {
        _dragPosition = 0.0;
        _isCompleted = false;
      });
    }
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (widget.isLoading || _isCompleted) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (widget.isLoading || _isCompleted) return;
    if (_dragPosition >= maxDrag * 0.72) {
      setState(() {
        _dragPosition = maxDrag;
        _isCompleted = true;
      });
      HapticFeedback.heavyImpact();
      widget.onSwipeComplete();
    } else {
      _resetAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
      );
      _resetController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double buttonHeight = 56.0;
    const double thumbSize = 46.0;
    const double padding = 5.0;

    if (widget.isLoading) {
      return Container(
        height: buttonHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF25258F),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF25258F).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              ),
              SizedBox(width: 14),
              Text(
                'Placing Your Order...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxDrag = (maxWidth - thumbSize - (padding * 2)).clamp(10.0, double.infinity);
        final double progress = (maxDrag > 0) ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return GestureDetector(
          onHorizontalDragUpdate: (details) => _onDragUpdate(details, maxDrag),
          onHorizontalDragEnd: (details) => _onDragEnd(details, maxDrag),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: buttonHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF25258F),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25258F).withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // ── Swipe Progress Fill Track (Theme Orange) ──
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _dragPosition + thumbSize + padding,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6D00), Color(0xFFFFA000)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),

                // ── Centered Swipe Text ──
                Center(
                  child: Opacity(
                    opacity: (1.0 - (progress * 1.5)).clamp(0.0, 1.0),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Swipe to Place Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.keyboard_double_arrow_right_rounded,
                          color: Color(0xFFFFC400),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Draggable Thumb ──
                Positioned(
                  left: padding + _dragPosition,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: progress > 0.72 ? const Color(0xFFFF6D00) : const Color(0xFFFFC400),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        progress > 0.72
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        color: progress > 0.72 ? Colors.white : const Color(0xFF1B1B3A),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
