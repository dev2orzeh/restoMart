import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WooCommerceApiService {
  static const String _baseUrl = 'https://restomart.pk/wp-json/wc/v3';
  static String get _consumerKey => dotenv.env['WOO_CONSUMER_KEY'] ?? '';
  static String get _consumerSecret => dotenv.env['WOO_CONSUMER_SECRET'] ?? '';

  static Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static String _appendAuth(String url) {
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}consumer_key=$_consumerKey&consumer_secret=$_consumerSecret';
  }

  /// Fetch all products from WooCommerce
  static Future<List<dynamic>> getProducts({int page = 1, int perPage = 20, String? categoryId, bool? onSale, String? searchQuery, String? orderBy, String? order}) async {
    try {
      String url = '$_baseUrl/products?page=$page&per_page=$perPage';
      if (categoryId != null) {
        url += '&category=$categoryId';
      }
      if (onSale != null && onSale) {
        url += '&on_sale=true';
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(searchQuery)}';
      }
      if (orderBy != null && orderBy.isNotEmpty) {
        url += '&orderby=$orderBy';
      }
      if (order != null && order.isNotEmpty) {
        url += '&order=$order';
      }

      url = _appendAuth(url);
      log('WOOCOMMERCE API: Fetching products from $url');
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        log('WOOCOMMERCE API: Error fetching products - ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('WOOCOMMERCE API: Exception fetching products - $e');
      return [];
    }
  }

  /// Fetch a single product by ID
  static Future<Map<String, dynamic>?> getProduct(int id) async {
    try {
      final url = _appendAuth('$_baseUrl/products/$id');
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      log('WOOCOMMERCE API: Exception fetching product $id - $e');
    }
    return null;
  }

  /// Fetch all categories
  static Future<List<dynamic>> getCategories({int page = 1, int perPage = 100}) async {
    try {
      String url = '$_baseUrl/products/categories?page=$page&per_page=$perPage&hide_empty=true';
      url = _appendAuth(url);
      log('WOOCOMMERCE API: Fetching categories from $url');
      
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        log('WOOCOMMERCE API: Error fetching categories - ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('WOOCOMMERCE API: Exception fetching categories - $e');
      return [];
    }
  }

  /// Create an order in WooCommerce
  static Future<String?> createOrder(Map<String, dynamic> orderData) async {
    try {
      final url = _appendAuth('$_baseUrl/orders');
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(orderData),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 201) {
        log('WOOCOMMERCE API: Order created successfully!');
        final responseData = json.decode(response.body);
        return responseData['id'].toString();
      } else {
        log('WOOCOMMERCE API: Failed to create order: ${response.body}');
        return null;
      }
    } catch (e) {
      log('WOOCOMMERCE API: Exception creating order - $e');
      return null;
    }
  }

  /// Update an order status in WooCommerce (e.g. 'cancelled', 'completed')
  static Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final cleanId = orderId.replaceAll('#', '').trim();
      final url = _appendAuth('$_baseUrl/orders/$cleanId');
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: json.encode({'status': status}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        log('WOOCOMMERCE API: Order #$cleanId status updated to $status');
        return true;
      } else {
        log('WOOCOMMERCE API: Failed to update order status: ${response.body}');
        return false;
      }
    } catch (e) {
      log('WOOCOMMERCE API: Exception updating order status - $e');
      return false;
    }
  }

  /// Validate a coupon code in WooCommerce
  static Future<Map<String, dynamic>?> validateCoupon(String code) async {
    try {
      // --- DUMMY PROMOS FOR TESTING ---
      final testCode = code.toUpperCase();
      if (testCode == 'WELCOME10' || testCode == 'SAVE500') {
        final prefs = await SharedPreferences.getInstance();
        final user = FirebaseAuth.instance.currentUser;
        final uid = user?.uid ?? 'guest';
        if (prefs.getBool('used_promo_${testCode}_$uid') == true) {
          log('WOOCOMMERCE API: Dummy promo already used by $uid');
          return null; // Already used
        }

        return { 
          'code': testCode, 
          'discount_type': testCode == 'WELCOME10' ? 'percent' : 'fixed_cart', 
          'amount': testCode == 'WELCOME10' ? '10' : '500' 
        };
      }
      // --------------------------------

      final url = _appendAuth('$_baseUrl/coupons?code=$code');
      log('WOOCOMMERCE API: Validating coupon: $code');
      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> coupons = json.decode(response.body);
        if (coupons.isNotEmpty) {
          return coupons[0]; // Returns the full coupon object (amount, type, etc)
        }
      }
      return null;
    } catch (e) {
      log('WOOCOMMERCE API: Exception validating coupon - $e');
      return null;
    }
  }

  // Legacy / custom endpoints needed by the app:
  static Future<void> syncDeviceToken(String customerId, String fcmToken) async {
    log('WOOCOMMERCE API: Syncing FCM Token ($fcmToken) for customer $customerId');
  }

  static Future<void> syncActiveCart({
    required String customerId,
    required List<dynamic> cartItems,
    required double total,
  }) async {
    log('WOOCOMMERCE API: Syncing Active Cart for customer $customerId');
  }

  static Future<void> markCartConverted(String customerId) async {
    log('WOOCOMMERCE API: Marking cart as converted for customer $customerId');
  }

  static Future<void> syncTemplates(String customerId, String templatesJson) async {
    log('WOOCOMMERCE API: Syncing templates for customer $customerId');
  }
}
