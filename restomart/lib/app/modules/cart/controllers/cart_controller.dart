import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/woocommerce_api_service.dart';

class CartItem {
  final String id;
  final String imagePath;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.imagePath,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'name': name,
    'price': price,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] ?? '0',
    imagePath: json['imagePath'],
    name: json['name'],
    price: (json['price'] as num).toDouble(),
    quantity: json['quantity'] as int,
  );
}

class CartController extends GetxController {
  final RxList<CartItem> cartItems = <CartItem>[].obs;

  String get _cartStorageKey {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return 'restomart_local_cart_${user.uid}';
    }
    return 'restomart_local_cart_guest';
  }

  final Rx<String?> appliedCouponCode = Rx<String?>(null);
  final Rx<double> discountAmount = 0.0.obs;
  final TextEditingController promoController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJsonStr = prefs.getString(_cartStorageKey);
    if (cartJsonStr != null) {
      try {
        final List<dynamic> cartList = json.decode(cartJsonStr);
        final mappedItems = cartList.map((item) => CartItem.fromJson(item)).toList();
        // Remove stale/corrupted items with ID 0 that block checkout
        cartItems.value = mappedItems.where((item) => item.id != '0').toList();
        
        // If we filtered out items, update storage
        if (mappedItems.length != cartItems.length) {
          _saveCart();
        }
      } catch (e) {
        print('Error loading cart: $e');
      }
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartList = cartItems.map((item) => item.toJson()).toList();
    await prefs.setString(_cartStorageKey, json.encode(cartList));

    // Sync active cart to WooCommerce for abandoned cart tracking
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WooCommerceApiService.syncActiveCart(
        customerId: user.uid,
        cartItems: cartList,
        total: totalPrice,
      );
    }
  }

  double get totalPrice {
    return cartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  double get finalTotal {
    double total = totalPrice - discountAmount.value;
    return total < 0 ? 0 : total;
  }

  int get totalItems {
    return cartItems.length;
  }

  Future<bool> applyCoupon(String code) async {
    final coupon = await WooCommerceApiService.validateCoupon(code);
    if (coupon != null) {
      appliedCouponCode.value = coupon['code'];
      final type = coupon['discount_type'];
      final amountStr = coupon['amount']?.toString() ?? '0';
      final amount = double.tryParse(amountStr) ?? 0.0;
      
      if (type == 'percent') {
        discountAmount.value = (totalPrice * (amount / 100));
      } else {
        discountAmount.value = amount;
      }
      return true;
    }
    return false;
  }

  void removeCoupon() {
    appliedCouponCode.value = null;
    discountAmount.value = 0.0;
  }

  void addToCart(String id, String imagePath, String name, double price, int quantity) {
    final existingIndex = cartItems.indexWhere((item) => item.name == name);

    if (existingIndex != -1) {
      cartItems[existingIndex].quantity += quantity;
      cartItems.refresh();
    } else {
      cartItems.add(
        CartItem(
          id: id,
          imagePath: imagePath,
          name: name,
          price: price,
          quantity: quantity,
        ),
      );
    }
    _saveCart();
  }

  void updateQuantity(CartItem item, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(item);
      return;
    }
    item.quantity = newQuantity;
    cartItems.refresh();
    _saveCart();
  }

  void increaseQuantity(CartItem item) {
    item.quantity++;
    cartItems.refresh();
    _saveCart();
  }

  void decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
      cartItems.refresh();
      _saveCart();
    } else {
      removeItem(item);
    }
  }

  void removeItem(CartItem item) {
    cartItems.remove(item);
    _saveCart();
  }

  void clearCart() {
    cartItems.clear();
    _saveCart();
  }

  void clearCartForLogout() {
    cartItems.clear();
    appliedCouponCode.value = null;
    discountAmount.value = 0.0;
    _loadCart();
  }

  Future<void> reloadCartForUser() async {
    final existingGuestItems = List<CartItem>.from(cartItems);
    cartItems.clear();
    await _loadCart();
    for (var item in existingGuestItems) {
      addToCart(item.id, item.imagePath, item.name, item.price, item.quantity);
    }
  }

  bool isInCart(String productName) {
    return cartItems.any((item) => item.name == productName);
  }

  int getProductQuantity(String productName) {
    final index = cartItems.indexWhere((item) => item.name == productName);
    if (index == -1) {
      return 0;
    }
    return cartItems[index].quantity;
  }
}
