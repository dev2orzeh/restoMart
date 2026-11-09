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

  /// Syncs customer ledger with actual non-cancelled orders and payments.
  /// Exactly mirrors admin dashboard's syncLedgerAccountsWithOrders logic.
  static Future<void> syncCustomerLedger(String uid) async {
    if (uid.isEmpty || uid == 'guest') return;

    try {
      final docRef = _firestore.collection('ledger_accounts').doc(uid);
      final accSnap = await docRef.get();
      final currentUser = FirebaseAuth.instance.currentUser;
      final accData = accSnap.exists ? (accSnap.data() ?? {}) : <String, dynamic>{};
      final email = (accData['customerEmail'] ?? currentUser?.email ?? '').toString().toLowerCase().trim();

      // 1. Fetch user orders from Firestore to find which belong to this user and which are cancelled
      final ordersSnap = await _firestore.collection('orders').get();
      final userOrders = ordersSnap.docs.where((d) {
        final data = d.data();
        final oUid = (data['userId'] ?? data['uid'] ?? '').toString().trim();
        final oEmail = (data['email'] ?? data['billing']?['email'] ?? '').toString().toLowerCase().trim();
        // Strictly match by UID, or if no UID on order, by exact email. NEVER match by phone across different accounts.
        return (oUid.isNotEmpty && oUid == uid) ||
            (oUid.isEmpty && email.isNotEmpty && oEmail == email);
      }).toList();

      final cancelledOrderIds = <String>{};
      final activeOrders = <Map<String, dynamic>>[];

      for (var doc in userOrders) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase().trim();
        final rawId = doc.id.replaceAll('#', '').trim();
        if (status.contains('cancel') || status.contains('reject')) {
          cancelledOrderIds.add(rawId);
          cancelledOrderIds.add(doc.id);
        } else {
          activeOrders.add({
            'id': doc.id,
            'cleanId': rawId,
            'total': (data['total'] as num?)?.toDouble() ?? 0.0,
          });
        }
      }

      final activeOrderIds = activeOrders.map((o) => o['cleanId'].toString()).toSet();

      // 2. Fetch all transaction documents in this account
      final txSnap = await docRef.collection('transactions').get();
      final docsToDelete = <DocumentReference>[];
      final seenDebitOrderIds = <String>{};
      double totalActualCredit = 0.0;
      double totalActiveDebit = 0.0;

      for (var txDoc in txSnap.docs) {
        final data = txDoc.data();
        final type = data['type']?.toString();
        final pMethod = (data['paymentMethod'] ?? '').toString().toLowerCase();
        final desc = (data['description'] ?? '').toString();
        final rawOId = (data['orderId'] ?? desc).toString().replaceAll('#', '').replaceFirst('Order', '').trim();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        // Delete legacy reversal items
        if (pMethod == 'system_reversal' || desc.contains('Reversal for Cancelled Order') || desc.toLowerCase().contains('cancel')) {
          docsToDelete.add(txDoc.reference);
          continue;
        }

        if (type == 'credit') {
          totalActualCredit += amount;
        } else if (type == 'debit') {
          // If order does not belong to this user's active orders, or is cancelled, delete this debit transaction!
          if (!activeOrderIds.contains(rawOId) || cancelledOrderIds.contains(rawOId) || cancelledOrderIds.contains(data['orderId'])) {
            docsToDelete.add(txDoc.reference);
          } else if (seenDebitOrderIds.contains(rawOId)) {
            // Duplicate debit found
            docsToDelete.add(txDoc.reference);
          } else {
            seenDebitOrderIds.add(rawOId);
            totalActiveDebit += amount;
          }
        }
      }

      // Delete stale / cancelled transactions
      for (var ref in docsToDelete) {
        try {
          await ref.delete();
        } catch (_) {}
      }

      // 3. Ensure active non-cancelled orders have their debit recorded if missing
      for (var ord in activeOrders) {
        final cleanId = ord['cleanId'] as String;
        if (!seenDebitOrderIds.contains(cleanId)) {
          final amt = ord['total'] as double;
          totalActiveDebit += amt;
          seenDebitOrderIds.add(cleanId);
          await docRef.collection('transactions').doc('debit_$cleanId').set({
            'type': 'debit',
            'amount': amt,
            'description': 'Order #${ord['id']}',
            'orderId': ord['id'],
            'date': FieldValue.serverTimestamp(),
            'recordedBy': 'system',
            'paymentMethod': 'Cash on delivery',
          }, SetOptions(merge: true));
        }
      }

      totalActiveDebit = double.parse(totalActiveDebit.toStringAsFixed(2));
      totalActualCredit = double.parse(totalActualCredit.toStringAsFixed(2));
      final calculatedBalance = double.parse((totalActiveDebit - totalActualCredit).toStringAsFixed(2));

      // 4. Update the account document with accurate recalculated numbers
      await docRef.set({
        'totalDebit': totalActiveDebit,
        'totalCredit': totalActualCredit,
        'balance': calculatedBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      log('LEDGER: Synced customer ledger for $uid: debit=$totalActiveDebit, credit=$totalActualCredit, balance=$calculatedBalance');
    } catch (e) {
      log('LEDGER: Error syncing customer ledger: $e');
    }
  }
}
