import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../../cart/controllers/cart_controller.dart';
import '../../cart/views/cart_view.dart';

import '../../../core/services/push_notification_service.dart';
import '../../../core/services/email_service.dart';
import '../../../core/services/ledger_service.dart';
import '../../../core/services/woocommerce_api_service.dart';
import '../../../core/utils/error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class OrderModel {
  final String id;
  final DateTime date;
  final double total;
  final RxString status; // Changed to RxString so UI updates instantly
  final String? specialInstructions;
  final String paymentMethod;
  final List<CartItem> items;

  OrderModel({
    required this.id,
    required this.date,
    required this.total,
    required String status,
    required this.paymentMethod,
    this.specialInstructions,
    required this.items,
  }) : status = status.obs; // Initialize observable

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'total': total,
      'status': status.value,
      'paymentMethod': paymentMethod,
      'specialInstructions': specialInstructions,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    var itemsList = <CartItem>[];
    if (map['items'] != null && map['items'] is List) {
      try {
        itemsList = List<CartItem>.from(
          (map['items'] as List).map((x) => CartItem.fromJson(Map<String, dynamic>.from(x))),
        );
      } catch (e) {
        print('Error parsing items: $e');
      }
    } else if (map['line_items'] != null && map['line_items'] is List) {
      try {
        itemsList = List<CartItem>.from(
          (map['line_items'] as List).map((x) => CartItem(
            id: x['product_id']?.toString() ?? '0',
            name: x['name']?.toString() ?? 'Product Item',
            price: (x['price'] as num?)?.toDouble() ?? 0.0,
            quantity: (x['quantity'] as num?)?.toInt() ?? 1,
            imagePath: '',
          )),
        );
      } catch (e) {
        print('Error parsing line_items: $e');
      }
    }

    DateTime parsedDate = DateTime.now();
    if (map['date'] != null) {
      try {
        if (map['date'] is String) {
          parsedDate = DateTime.parse(map['date']);
        } else if (map['date'] is Timestamp) {
          parsedDate = (map['date'] as Timestamp).toDate();
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
    } else if (map['date_created'] != null) {
      try {
        if (map['date_created'] is String) {
          parsedDate = DateTime.parse(map['date_created']);
        } else if (map['date_created'] is Timestamp) {
          parsedDate = (map['date_created'] as Timestamp).toDate();
        }
      } catch (e) {
        print('Error parsing date_created: $e');
      }
    }

    return OrderModel(
      id: map['id']?.toString() ?? docId,
      date: parsedDate,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      status: map['status']?.toString() ?? 'pending',
      paymentMethod: map['paymentMethod']?.toString() ?? map['payment']?.toString() ?? map['payment_method_title']?.toString() ?? 'Cash on delivery',
      specialInstructions: map['specialInstructions']?.toString() ?? map['customer_note']?.toString(),
      items: itemsList,
    );
  }
}

class OrdersController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final Map<String, String> _knownStatuses = {};
  bool _isInitialSnapshot = true;

  String get _ordersStorageKey {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return 'restomart_orders_${user.uid}';
    }
    return 'restomart_orders_guest';
  }

  @override
  void onInit() {
    super.onInit();
    _loadLocalOrders();
    _listenToOrders();
  }

  Future<void> _loadLocalOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_ordersStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        final loaded = decoded.map((e) => OrderModel.fromMap(Map<String, dynamic>.from(e), e['id']?.toString() ?? '')).toList();
        if (loaded.isNotEmpty) {
          orders.value = loaded;
        }
      }
    } catch (e) {
      print('Error loading local orders: $e');
    }
  }

  Future<void> _saveLocalOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = orders.map((o) => o.toMap()).toList();
      await prefs.setString(_ordersStorageKey, jsonEncode(list));
    } catch (e) {
      print('Error saving local orders: $e');
    }
  }

  StreamSubscription? _orderSubscription;

  void _listenToOrders() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _startOrderStream(user);
    });
  }

  void _startOrderStream(User? user) {
    _orderSubscription?.cancel();
    _isInitialSnapshot = true;
    _loadLocalOrders();

    // Query Firestore orders in real-time
    _orderSubscription = _firestore.collection('orders').snapshots().listen((snapshot) {
      final currentUid = user?.uid;
      final currentEmail = user?.email?.toLowerCase().trim();
      final localOrderIds = orders.map((o) => o.id.replaceAll('#', '').trim()).toSet();

      final List<OrderModel> parsedOrders = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final cleanDocId = doc.id.replaceAll('#', '').trim();
        final orderUserId = data['userId']?.toString();
        final orderEmail = (data['email'] ?? data['billing']?['email'])?.toString().toLowerCase().trim();

        // Match order if:
        // 1. Belongs to current logged-in user's UID
        // 2. Belongs to current logged-in user's Email
        // 3. Or matches an order ID already stored locally on this device (supports guest users!)
        final isMyOrder = (currentUid != null && currentUid.isNotEmpty && orderUserId == currentUid) ||
            (currentEmail != null && currentEmail.isNotEmpty && orderEmail == currentEmail) ||
            localOrderIds.contains(cleanDocId);

        if (isMyOrder) {
          try {
            parsedOrders.add(OrderModel.fromMap(data, doc.id));
          } catch (e) {
            print('Error parsing order ${doc.id}: $e');
          }
        }
      }

      // Check for live status changes on existing orders in real-time
      for (var change in snapshot.docChanges) {
        final docId = change.doc.id;
        final cleanDocId = docId.replaceAll('#', '').trim();
        final data = change.doc.data();
        if (data != null && data['status'] != null) {
          final newStatus = data['status'].toString();

          // Find if this order is in our current list
          final existingOrder = orders.firstWhereOrNull(
            (o) => o.id.replaceAll('#', '').trim() == cleanDocId,
          );

          if (existingOrder != null) {
            if (existingOrder.status.value.toLowerCase() != newStatus.toLowerCase()) {
              existingOrder.status.value = newStatus; // Updates UI instantly!
              _saveLocalOrders();

              if (!_isInitialSnapshot) {
                PushNotificationService.showOrderStatusNotification(docId, newStatus);
                if (newStatus.toLowerCase().contains('cancel') && currentUid != null) {
                  LedgerService.syncCustomerLedger(currentUid);
                }
              }
            }
          }
          _knownStatuses[docId] = newStatus;
        }
      }

      if (_isInitialSnapshot) {
        _isInitialSnapshot = false;
      }

      // Merge newly fetched orders into the reactive orders list
      if (parsedOrders.isNotEmpty) {
        for (var p in parsedOrders) {
          final idx = orders.indexWhere((o) => o.id.replaceAll('#', '').trim() == p.id.replaceAll('#', '').trim());
          if (idx >= 0) {
            orders[idx].status.value = p.status.value;
          } else {
            orders.add(p);
          }
        }
        orders.sort((a, b) => b.date.compareTo(a.date));
        _saveLocalOrders();
      }
    }, onError: (e) {
      print('Error listening to orders: $e');
      if (AppErrorHandler.isNetworkError(e)) {
        AppErrorHandler.showOfflineError();
      }
    });
  }

  Future<void> addOrder(
    OrderModel order, {
    String? customerName,
    String? phone,
    String? address,
    double? lat,
    double? lng,
  }) async {
    // 1. Immediately add to local reactive list so My Orders is NEVER empty
    final existingIndex = orders.indexWhere((o) => o.id == order.id);
    if (existingIndex >= 0) {
      orders[existingIndex] = order;
    } else {
      orders.insert(0, order);
    }
    await _saveLocalOrders();

    try {
      final map = order.toMap();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        map['userId'] = user.uid;
        map['email'] = user.email;
      }
      
      // Attach device FCM token so push notifications reach this phone even when app is closed
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          map['fcmToken'] = token;
        }
      } catch (tokenErr) {
        print('FCM token attachment error: $tokenErr');
      }
      
      final displayName = customerName != null && customerName.isNotEmpty 
          ? customerName 
          : (user?.displayName != null && user!.displayName!.isNotEmpty ? user.displayName : 'Customer');
          
      map['customer'] = displayName;
      map['phone'] = phone ?? '';
      map['address'] = address ?? '';
      if (lat != null && lng != null) {
        map['lat'] = lat;
        map['lng'] = lng;
        map['mapUrl'] = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      } else if (address != null && address.isNotEmpty) {
        map['mapUrl'] = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
      }
      map['payment'] = order.paymentMethod;
      map['billing'] = {
        'first_name': displayName,
        'email': user?.email ?? '',
        'phone': phone ?? '',
        'address_1': address ?? '',
      };
      map['shipping'] = map['billing'];

      await _firestore.collection('orders').doc(order.id).set(map);

      final uid = user?.uid;
      if (uid != null && uid.isNotEmpty && uid != 'guest') {
        try {
          await LedgerService.ensureAccountExists(
            uid: uid,
            name: displayName ?? 'Customer',
            email: user?.email ?? '',
            phone: phone ?? '',
          );
          await LedgerService.recordOrderDebit(
            uid: uid,
            orderId: order.id,
            amount: order.total,
            paymentMethod: order.paymentMethod,
          );
        } catch (lErr) {
          print('Ledger record debit error: $lErr');
        }
      }
    } catch (e) {
      print('Error saving order to Firestore: $e');
      final message = AppErrorHandler.isNetworkError(e)
          ? 'Order saved locally. It will sync when you reconnect.'
          : 'Failed to sync with cloud. Saved locally.';
      AppErrorHandler.showWarning(
        AppErrorHandler.isNetworkError(e) ? 'Offline Mode' : 'Order Notice',
        message,
      );
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      // 1. Update Firestore status
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled'
      });

      // 2. Find matching order model
      final cleanId = orderId.replaceAll('#', '').trim();
      OrderModel? order;
      for (var o in orders) {
        if (o.id.replaceAll('#', '').trim() == cleanId) {
          order = o;
          order.status.value = 'cancelled';
          break;
        }
      }

      // If not in local reactive list, fetch from Firestore
      String customerEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      if (order == null || customerEmail.isEmpty) {
        try {
          final doc = await _firestore.collection('orders').doc(orderId).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            order ??= OrderModel.fromMap(data, doc.id);
            if (customerEmail.isEmpty) {
              customerEmail = (data['email'] ?? data['billing']?['email'] ?? '').toString();
            }
          }
        } catch (_) {}
      }

      // 3. Reverse Ledger debit if user is logged in
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        try {
          if (order != null) {
            await LedgerService.reverseOrderDebit(
              uid: uid,
              orderId: orderId,
              amount: order.total,
            );
          }
          await LedgerService.syncCustomerLedger(uid);
        } catch (rErr) {
          print('Ledger reversal error: $rErr');
        }
      }

      // 4. Update WooCommerce order status to 'cancelled' (triggers WooCommerce email)
      try {
        await WooCommerceApiService.updateOrderStatus(cleanId, 'cancelled');
      } catch (wErr) {
        print('WooCommerce cancel status error: $wErr');
      }

      // 5. Send cancellation email directly to customer
      if (order != null) {
        final emailToSend = customerEmail.isNotEmpty 
            ? customerEmail 
            : (FirebaseAuth.instance.currentUser?.email ?? '');
        if (emailToSend.isNotEmpty && !emailToSend.contains('guest@')) {
          await EmailService.sendCancellationEmail(order, emailToSend);
        }
      }
    } catch (e) {
      AppErrorHandler.showError('Cancel Failed', e);
    }
  }

  void reorder(OrderModel order) {
    final cartController = Get.find<CartController>();
    
    if (cartController.cartItems.isNotEmpty) {
      Get.defaultDialog(
        title: 'Clear Current Cart?',
        middleText: 'You already have items in your cart. Do you want to clear them before adding your previous order?',
        textConfirm: 'Clear & Add',
        textCancel: 'Mix Together',
        confirmTextColor: Colors.white,
        buttonColor: const Color(0xFF25258F),
        onConfirm: () {
          Get.back();
          cartController.clearCart();
          _executeReorder(cartController, order);
        },
        onCancel: () {
          _executeReorder(cartController, order);
        }
      );
    } else {
      _executeReorder(cartController, order);
    }
  }

  void _executeReorder(CartController cartController, OrderModel order) {
    for (final item in order.items) {
      cartController.addToCart(
        item.id,
        item.imagePath,
        item.name,
        item.price,
        item.quantity,
      );
    }

    AppErrorHandler.showSuccess(
      'Re-ordered',
      'Items from order #${order.id.replaceAll('#', '')} added to cart',
    );

    // Navigate to Cart
    Get.to(() => CartView());
  }
}
