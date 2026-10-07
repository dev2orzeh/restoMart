import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';
import '../../../core/services/push_notification_service.dart';

class LedgerController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final isLoading = true.obs;
  
  final totalDebit = 0.0.obs;
  final totalCredit = 0.0.obs;
  final balance = 0.0.obs;
  
  final transactions = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _listenToLedger();
  }

  void _listenToLedger() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    // Listen to account totals
    _firestore.collection('ledger_accounts').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        totalDebit.value = (data['totalDebit'] as num?)?.toDouble() ?? 0.0;
        totalCredit.value = (data['totalCredit'] as num?)?.toDouble() ?? 0.0;
        balance.value = (data['balance'] as num?)?.toDouble() ?? 0.0;
      }
    });

    // Listen to transactions
    _firestore
        .collection('ledger_accounts')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      
      // Check for new ledger entries (only if this isn't the first load)
      if (!isLoading.value) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data()!;
            final paymentMethod = data['paymentMethod']?.toString();
            final type = data['type']?.toString();
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final isReversal = paymentMethod == 'system_reversal';

            if (!isReversal) {
              if (type == 'credit') {
                PushNotificationService.showLedgerPaymentNotification(amount, balance.value);
              } else if (type == 'debit') {
                final desc = data['description']?.toString() ?? 'Order Debit';
                PushNotificationService.showLedgerDebitNotification(amount, balance.value, desc);
              }
            }
          }
        }
      }

      final txns = snapshot.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();
      
      transactions.value = txns;
      isLoading.value = false;
    }, onError: (e) {
      log('LEDGER: Error listening to transactions: $e');
      isLoading.value = false;
    });
  }
}
