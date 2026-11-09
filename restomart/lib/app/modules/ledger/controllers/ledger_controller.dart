import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';
import '../../../core/services/push_notification_service.dart';
import '../../../core/services/email_service.dart';
import '../../../core/services/ledger_service.dart';
import '../../orders/controllers/orders_controller.dart';

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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      LedgerService.syncCustomerLedger(uid);
    }
    _listenToLedger();
  }

  void _listenToLedger() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    final docRef = _firestore.collection('ledger_accounts').doc(uid);

    // Listen to transactions (authoritative source of truth for debits and credits)
    _firestore
        .collection('ledger_accounts')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      
      // Collect known user order IDs and cancelled order IDs from reactive OrdersController
      final cancelledOrderIds = <String>{};
      final myOrderIds = <String>{};
      if (Get.isRegistered<OrdersController>()) {
        for (var o in Get.find<OrdersController>().orders) {
          final cleanId = o.id.replaceAll('#', '').trim();
          myOrderIds.add(cleanId);
          myOrderIds.add(o.id.trim());
          final st = o.status.value.toLowerCase().trim();
          if (st.contains('cancel') || st.contains('reject')) {
            cancelledOrderIds.add(cleanId);
            cancelledOrderIds.add(o.id.trim());
          }
        }
      }

      final validTxns = <Map<String, dynamic>>[];
      final seenDebitOrderIds = <String>{};
      double txDebitSum = 0.0;
      double txCreditSum = 0.0;

      for (var d in snapshot.docs) {
        final data = d.data();
        data['id'] = d.id;
        final type = data['type']?.toString();
        final pMethod = (data['paymentMethod'] ?? '').toString().toLowerCase();
        final desc = (data['description'] ?? '').toString();
        final rawOId = (data['orderId'] ?? desc).toString().replaceAll('#', '').replaceFirst('Order', '').trim();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        // Skip & clean up legacy reversal entries
        if (pMethod == 'system_reversal' || desc.contains('Reversal for Cancelled Order')) {
          d.reference.delete().catchError((_) {});
          continue;
        }

        // Skip & clean up cancelled order transactions
        if (cancelledOrderIds.contains(rawOId) || 
            (data['orderId'] != null && cancelledOrderIds.contains(data['orderId'].toString().trim())) ||
            desc.toLowerCase().contains('cancel')) {
          d.reference.delete().catchError((_) {});
          continue;
        }

        // If OrdersController is loaded and has the user's orders, ensure this debit belongs to this user
        if (type == 'debit' && myOrderIds.isNotEmpty && !myOrderIds.contains(rawOId) && 
            (data['orderId'] == null || !myOrderIds.contains(data['orderId'].toString().trim()))) {
          d.reference.delete().catchError((_) {});
          continue;
        }

        if (type == 'credit') {
          txCreditSum += amount;
          validTxns.add(data);
        } else if (type == 'debit') {
          // De-duplicate debit entries for the same order
          if (seenDebitOrderIds.contains(rawOId)) {
            d.reference.delete().catchError((_) {});
            continue;
          }
          seenDebitOrderIds.add(rawOId);
          txDebitSum += amount;
          validTxns.add(data);
        } else {
          validTxns.add(data);
        }
      }

      transactions.value = validTxns;

      txDebitSum = double.parse(txDebitSum.toStringAsFixed(2));
      txCreditSum = double.parse(txCreditSum.toStringAsFixed(2));
      final txBal = double.parse((txDebitSum - txCreditSum).toStringAsFixed(2));

      totalDebit.value = txDebitSum;
      totalCredit.value = txCreditSum;
      balance.value = txBal;

      // Ensure root ledger_accounts document is always kept in sync with actual totals
      docRef.set({
        'totalDebit': txDebitSum,
        'totalCredit': txCreditSum,
        'balance': txBal,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((e) {
        log('LEDGER: Error updating account doc: $e');
      });

      // Check for new ledger entries notifications (only if this isn't the first load)
      if (!isLoading.value) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data == null) continue;
            final paymentMethod = data['paymentMethod']?.toString();
            final type = data['type']?.toString();
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final isReversal = paymentMethod == 'system_reversal';

            if (!isReversal) {
              if (type == 'credit') {
                PushNotificationService.showLedgerPaymentNotification(amount, balance.value);
                final currentUser = FirebaseAuth.instance.currentUser;
                final email = currentUser?.email;
                if (email != null && email.isNotEmpty && !email.contains('guest@')) {
                  EmailService.sendPaymentReceivedEmail(
                    recipientEmail: email,
                    amount: amount,
                    paymentMethod: paymentMethod ?? 'Cash',
                    newBalance: balance.value,
                    description: data['description']?.toString(),
                  );
                }
              } else if (type == 'debit') {
                final desc = data['description']?.toString() ?? 'Order Debit';
                PushNotificationService.showLedgerDebitNotification(amount, balance.value, desc);
              }
            }
          }
        }
      }

      isLoading.value = false;
    }, onError: (e) {
      log('LEDGER: Error listening to transactions: $e');
      isLoading.value = false;
    });
  }
}
