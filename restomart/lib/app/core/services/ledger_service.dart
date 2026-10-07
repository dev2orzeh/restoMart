import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

class LedgerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ensures a ledger account exists for the given user.
  static Future<void> ensureAccountExists({
    required String uid,
    required String name,
    required String email,
    required String phone,
  }) async {
    if (uid.isEmpty || uid == 'guest') return;
    
    final docRef = _firestore.collection('ledger_accounts').doc(uid);
    final snapshot = await docRef.get();
    
    if (!snapshot.exists) {
      log('LEDGER: Creating new account for $email');
      await docRef.set({
        'customerName': name,
        'customerEmail': email,
        'customerPhone': phone,
        'totalDebit': 0.0,
        'totalCredit': 0.0,
        'balance': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Records an order (DEBIT) transaction and updates the running balance.
  static Future<void> recordOrderDebit({
    required String uid,
    required String orderId,
    required double amount,
    required String paymentMethod,
  }) async {
    if (uid.isEmpty || uid == 'guest') return;

    final docRef = _firestore.collection('ledger_accounts').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      
      double currentDebit = 0.0;
      double currentCredit = 0.0;
      
      if (!snapshot.exists) {
        final currentUser = FirebaseAuth.instance.currentUser;
        transaction.set(docRef, {
          'customerName': currentUser?.displayName ?? 'Customer',
          'customerEmail': currentUser?.email ?? '',
          'customerPhone': currentUser?.phoneNumber ?? '',
          'totalDebit': 0.0,
          'totalCredit': 0.0,
          'balance': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final data = snapshot.data() ?? {};
        currentDebit = (data['totalDebit'] as num?)?.toDouble() ?? 0.0;
        currentCredit = (data['totalCredit'] as num?)?.toDouble() ?? 0.0;
      }
      
      final cleanAmount = double.parse(amount.toStringAsFixed(2));
      final cleanOrderId = orderId.replaceAll('#', '').trim();
      final txnDocId = 'debit_$cleanOrderId';
      final txnRef = docRef.collection('transactions').doc(txnDocId);
      final existingTxn = await transaction.get(txnRef);

      // Only record debit if not already recorded for this order
      if (!existingTxn.exists) {
        final newDebit = double.parse((currentDebit + cleanAmount).toStringAsFixed(2));
        final newBalance = double.parse((newDebit - currentCredit).toStringAsFixed(2));

        // 1. Add transaction document
        transaction.set(txnRef, {
          'type': 'debit',
          'amount': cleanAmount,
          'description': 'Order #$orderId',
          'orderId': orderId,
          'date': FieldValue.serverTimestamp(),
          'recordedBy': 'system',
          'paymentMethod': paymentMethod,
        });

        // 2. Update totals
        transaction.update(docRef, {
          'totalDebit': newDebit,
          'balance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
    
    log('LEDGER: Recorded debit of $amount for order $orderId');
  }

  /// Reverses/removes an order debit if it is cancelled.
  static Future<void> reverseOrderDebit({
    required String uid,
    required String orderId,
    required double amount,
  }) async {
    if (uid.isEmpty || uid == 'guest') return;

    final docRef = _firestore.collection('ledger_accounts').doc(uid);
    final cleanOrderId = orderId.replaceAll('#', '').trim();
    final txnDocId = 'debit_$cleanOrderId';

    try {
      // 1. Delete debit transaction doc if exists
      final txnRef = docRef.collection('transactions').doc(txnDocId);
      final txnSnap = await txnRef.get();
      if (txnSnap.exists) {
        await txnRef.delete();
      }

      // 2. Delete any matching debit or legacy reversal docs for this order
      final allTxns = await docRef.collection('transactions').get();
      for (var doc in allTxns.docs) {
        final d = doc.data();
        final rawOId = (d['orderId'] ?? d['description'] ?? '').toString().replaceAll('#', '').replaceFirst('Order', '').trim();
        final pMethod = (d['paymentMethod'] ?? '').toString().toLowerCase();
        if (rawOId == cleanOrderId || d['orderId'] == orderId) {
          if (d['type'] == 'debit' || pMethod == 'system_reversal') {
            await doc.reference.delete();
          }
        }
      }

      // 3. Recalculate remaining total debit
      final remainingDebits = await docRef.collection('transactions').where('type', isEqualTo: 'debit').get();
      double recalculatedDebit = 0.0;
      for (var doc in remainingDebits.docs) {
        final amt = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        recalculatedDebit += amt;
      }
      recalculatedDebit = double.parse(recalculatedDebit.toStringAsFixed(2));

      final accSnap = await docRef.get();
      if (accSnap.exists) {
        final data = accSnap.data() ?? {};
        final totalCredit = (data['totalCredit'] as num?)?.toDouble() ?? 0.0;
        final newBalance = double.parse((recalculatedDebit - totalCredit).toStringAsFixed(2));

        await docRef.update({
          'totalDebit': recalculatedDebit,
          'balance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      log('LEDGER: Successfully removed debit for cancelled order $orderId');
    } catch (e) {
      log('LEDGER: Error reversing order debit: $e');
    }
  }
}
