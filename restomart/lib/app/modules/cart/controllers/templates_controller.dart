import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_controller.dart';
import '../../../core/services/woocommerce_api_service.dart';

class CartTemplate {
  final String id;
  final String name;
  final List<CartItem> items;

  CartTemplate({
    required this.id,
    required this.name,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory CartTemplate.fromJson(Map<String, dynamic> json) => CartTemplate(
    id: json['id'],
    name: json['name'],
    items: (json['items'] as List).map((i) => CartItem.fromJson(i)).toList(),
  );
}

class TemplatesController extends GetxController {
  final RxList<CartTemplate> templates = <CartTemplate>[].obs;
  static const String _templatesKey = 'restomart_local_templates';

  @override
  void onInit() {
    super.onInit();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final templatesJsonStr = prefs.getString(_templatesKey);
    
    if (templatesJsonStr != null) {
      try {
        final List<dynamic> decoded = json.decode(templatesJsonStr);
        templates.value = decoded.map((item) => CartTemplate.fromJson(item)).toList();
      } catch (e) {
        print('Error loading templates: $e');
      }
    }
  }

  Future<void> _saveTemplatesToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(templates.map((t) => t.toJson()).toList());
    await prefs.setString(_templatesKey, encoded);

    // Sync to WooCommerce backend via user meta
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WooCommerceApiService.syncTemplates(user.uid, encoded);
    }
  }

  void saveCurrentCartAsTemplate(String templateName) {
    final cartController = Get.find<CartController>();
    if (cartController.cartItems.isEmpty) return;

    final newTemplate = CartTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: templateName,
      items: List.from(cartController.cartItems), // Create a copy
    );

    templates.add(newTemplate);
    _saveTemplatesToLocal();
    
    Get.snackbar(
      'Template Saved',
      '"$templateName" has been saved successfully.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE8F5E9),
      colorText: const Color(0xFF2E7D32),
    );
  }

  void applyTemplateToCart(CartTemplate template) {
    final cartController = Get.find<CartController>();
    for (var item in template.items) {
      cartController.addToCart(item.id, item.imagePath, item.name, item.price, item.quantity);
    }
    
    Get.snackbar(
      'Template Applied',
      '"${template.name}" items added to your cart.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE3F2FD),
      colorText: const Color(0xFF1565C0),
    );
  }
  
  void deleteTemplate(String id) {
    templates.removeWhere((t) => t.id == id);
    _saveTemplatesToLocal();
  }
}
