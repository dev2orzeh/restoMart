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
    final docRef = _firestore.collection('ledger_accounts').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception("Ledger account not found for uid: $uid");
      }

      final currentDebit = (snapshot.data()?['totalDebit'] ?? 0.0) as double;
      final currentCredit = (snapshot.data()?['totalCredit'] ?? 0.0) as double;
      
      final newDebit = currentDebit + amount;
      final newBalance = newDebit - currentCredit;

      // 1. Add transaction document
      final txnRef = docRef.collection('transactions').doc();
      transaction.set(txnRef, {
        'type': 'debit',
        'amount': amount,
        'description': 'Order #$orderId',
        'orderId': orderId,
        'date': FieldValue.serverTimestamp(),
        'recordedBy': 'system',
        'paymentMethod': paymentMethod, // e.g. "Cash on delivery"
      });

      // 2. Update totals
      transaction.update(docRef, {
        'totalDebit': newDebit,
        'balance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    
    log('LEDGER: Recorded debit of $amount for order $orderId');
  }

  /// Reverses an order if it is cancelled.
  static Future<void> reverseOrderDebit({
    required String uid,
    required String orderId,
    required double amount,
  }) async {
    final docRef = _firestore.collection('ledger_accounts').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final currentDebit = (snapshot.data()?['totalDebit'] ?? 0.0) as double;
      final currentCredit = (snapshot.data()?['totalCredit'] ?? 0.0) as double;
      
      final newCredit = currentCredit + amount;
      final newBalance = currentDebit - newCredit;

      // 1. Add transaction document
      final txnRef = docRef.collection('transactions').doc();
      transaction.set(txnRef, {
        'type': 'credit',
        'amount': amount,
        'description': 'Reversal for Cancelled Order #$orderId',
        'orderId': orderId,
        'date': FieldValue.serverTimestamp(),
        'recordedBy': 'system',
        'paymentMethod': 'system_reversal',
      });

      // 2. Update totals (we add to credit to reverse the debit, keeping history intact)
      transaction.update(docRef, {
        'totalCredit': newCredit,
        'balance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    
    log('LEDGER: Reversed debit of $amount for cancelled order $orderId');
  }
}
