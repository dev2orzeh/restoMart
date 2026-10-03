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
    if (map['items'] != null) {
      try {
        itemsList = List<CartItem>.from(
          (map['items'] as List).map((x) => CartItem.fromJson(Map<String, dynamic>.from(x))),
        );
      } catch (e) {
        print('Error parsing items: $e');
      }
    }
    return OrderModel(
      id: map['id'] ?? docId,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      total: map['total']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? map['payment'] ?? 'Cash on delivery',
      specialInstructions: map['specialInstructions'],
      items: itemsList,
    );
  }
}

class OrdersController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<OrderModel> orders = <OrderModel>[].obs;

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
        return;
      }

      _orderSubscription = _firestore
          .collection('orders')
          .orderBy('date', descending: true)
          .snapshots()
          .listen((snapshot) {
        final List<OrderModel> parsedOrders = [];
        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['userId'] == user.uid) { // Strictly match the active user
            try {
              parsedOrders.add(OrderModel.fromMap(data, doc.id));
            } catch (e) {
              print('Error parsing order ${doc.id}: $e');
            }
          }
        }
        
        // Check for status changes to trigger local notifications
        if (orders.isNotEmpty) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.modified) {
              final newData = change.doc.data();
              if (newData != null && newData['status'] != null) {
                final oldOrder = orders.firstWhereOrNull((o) => o.id == change.doc.id);
                if (oldOrder != null && oldOrder.status.value != newData['status']) {
                  PushNotificationService.showOrderStatusNotification(change.doc.id, newData['status']);
                }
              }
            }
          }
        }

        orders.value = parsedOrders;
      }, onError: (e) => print('Error listening to orders: $e'));
    });
  }

  Future<void> addOrder(OrderModel order) async {
    try {
      final map = order.toMap();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) map['userId'] = uid;
      await _firestore.collection('orders').doc(order.id).set(map);
    } catch (e) {
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
        final email = FirebaseAuth.instance.currentUser?.email ?? 'guest@restomart.pk';
        await EmailService.sendCancellationEmail(order, email);
        
        // Reverse the ledger debit
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          try {
            await LedgerService.reverseOrderDebit(uid: uid, orderId: orderId, amount: order.total);
          } catch (e) {
            print("Failed to reverse ledger: $e");
          }
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel order: $e');
    }
  }

  void reorder(OrderModel order) {
    final cartController = Get.find<CartController>();
    
    // Clear current cart first, or just append? 
    // Usually re-order appends to the cart. 
    // We will append to the cart and navigate to it.
    
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
