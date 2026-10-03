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
        totalDebit.value = (data['totalDebit'] ?? 0.0) as double;
        totalCredit.value = (data['totalCredit'] ?? 0.0) as double;
        balance.value = (data['balance'] ?? 0.0) as double;
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
      
      // Check for new payments (only if this isn't the first load)
      if (!isLoading.value) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data()!;
            if (data['type'] == 'credit') {
              final amount = (data['amount'] ?? 0.0) as double;
              PushNotificationService.showLedgerPaymentNotification(amount, balance.value);
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
