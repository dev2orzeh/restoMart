import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../cart/controllers/cart_controller.dart';
import '../../cart/views/cart_view.dart';

import '../../../core/services/push_notification_service.dart';
import '../../../core/services/email_service.dart';
import '../../../core/services/ledger_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void onInit() {
    super.onInit();
    _listenToOrders();
  }

  StreamSubscription? _orderSubscription;

  void _listenToOrders() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _orderSubscription?.cancel();
      
      if (user == null) {
        orders.value = [];
        _knownStatuses.clear();
        return;
      }

      // Query without composite index requirement
      _orderSubscription = _firestore
          .collection('orders')
          .snapshots()
          .listen((snapshot) {
        final List<OrderModel> parsedOrders = [];
        final currentUid = user.uid;
        final currentEmail = user.email?.toLowerCase().trim();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final orderUserId = data['userId']?.toString();
          final orderEmail = (data['email'] ?? data['billing']?['email'])?.toString().toLowerCase().trim();

          // Match if order belongs to current user's UID or Email
          if ((orderUserId != null && orderUserId == currentUid) ||
              (currentEmail != null && orderEmail == currentEmail)) {
            try {
              parsedOrders.add(OrderModel.fromMap(data, doc.id));
            } catch (e) {
              print('Error parsing order ${doc.id}: $e');
            }
          }
        }

        // Sort by date descending in Dart (no composite index needed)
        parsedOrders.sort((a, b) => b.date.compareTo(a.date));

        // Check docChanges for status change notifications
        for (var change in snapshot.docChanges) {
          final docId = change.doc.id;
          final data = change.doc.data();
          if (data != null && data['status'] != null) {
            final newStatus = data['status'].toString();
            final orderUserId = data['userId']?.toString();
            final orderEmail = (data['email'] ?? data['billing']?['email'])?.toString().toLowerCase().trim();

            final isMyOrder = (orderUserId != null && orderUserId == currentUid) ||
                              (currentEmail != null && orderEmail == currentEmail);

            if (isMyOrder) {
              if (change.type == DocumentChangeType.modified) {
                final oldStatus = _knownStatuses[docId];
                if (oldStatus != null && oldStatus.toLowerCase() != newStatus.toLowerCase()) {
                  PushNotificationService.showOrderStatusNotification(docId, newStatus);
                }
              }
              _knownStatuses[docId] = newStatus;
            }
          }
        }

        orders.value = parsedOrders;
      }, onError: (e) => print('Error listening to orders: $e'));
    });
  }

  Future<void> addOrder(OrderModel order, {String? customerName, String? phone, String? address}) async {
    try {
      final map = order.toMap();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        map['userId'] = user.uid;
        map['email'] = user.email;
      }
      
      final displayName = customerName != null && customerName.isNotEmpty 
          ? customerName 
          : (user?.displayName != null && user!.displayName!.isNotEmpty ? user.displayName : 'Customer');
          
      map['customer'] = displayName;
      map['phone'] = phone ?? '';
      map['address'] = address ?? '';
      map['payment'] = order.paymentMethod;
      map['billing'] = {
        'first_name': displayName,
        'email': user?.email ?? '',
        'phone': phone ?? '',
        'address_1': address ?? '',
      };
      map['shipping'] = map['billing'];

      await _firestore.collection('orders').doc(order.id).set(map);

      if (user != null && user.uid.isNotEmpty) {
        try {
          await LedgerService.ensureAccountExists(
            uid: user.uid,
            name: displayName ?? 'Customer',
            email: user.email ?? '',
            phone: phone ?? '',
          );
          await LedgerService.recordOrderDebit(
            uid: user.uid,
            orderId: order.id,
            amount: order.total,
            paymentMethod: order.paymentMethod,
          );
        } catch (lErr) {
          print('Ledger record debit error: $lErr');
        }
      }

      // Instantly insert into local reactive list so My Orders displays it immediately
      final existingIndex = orders.indexWhere((o) => o.id == order.id);
      if (existingIndex >= 0) {
        orders[existingIndex] = order;
      } else {
        orders.insert(0, order);
      }
    } catch (e) {
      print('Error saving order to Firestore: $e');
      Get.snackbar('Error', 'Failed to place order: $e');
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled'
      });
      OrderModel? order;
      for (var o in orders) {
        if (o.id == orderId) {
          order = o;
          break;
        }
      }
      if (order != null) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null && uid.isNotEmpty) {
          try {
            await LedgerService.reverseOrderDebit(
              uid: uid,
              orderId: orderId,
              amount: order.total,
            );
          } catch (rErr) {
            print('Ledger reversal error: $rErr');
          }
        }
        final email = FirebaseAuth.instance.currentUser?.email ?? 'guest@restomart.pk';
        await EmailService.sendCancellationEmail(order, email);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel order: $e');
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

    Get.snackbar(
      'Re-ordered',
      'Items from order ${order.id} added to cart',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );

    // Navigate to Cart
    Get.to(() => CartView());
  }
}
