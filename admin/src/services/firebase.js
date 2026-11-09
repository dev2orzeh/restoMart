import { initializeApp } from 'firebase/app';
import { getFirestore, collection, onSnapshot, doc, updateDoc, query, orderBy, runTransaction, serverTimestamp, getDocs, setDoc, deleteDoc, getDoc, addDoc } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyCWg-_YHLqGPzNBhR7ovpAYZKRxeWTFsfw",
  appId: "1:883277273690:web:e59ad9a2e55e6a203b5663",
  messagingSenderId: "883277273690",
  projectId: "restomart-fe0c7",
  authDomain: "restomart-fe0c7.firebaseapp.com",
  storageBucket: "restomart-fe0c7.firebasestorage.app",
  measurementId: "G-LD7NLPJM70"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);

// Helper to subscribe to all orders, ordered by date descending
export const subscribeToOrders = (callback) => {
  const q = query(collection(db, 'orders'), orderBy('date', 'desc'));
  return onSnapshot(q, (snapshot) => {
    const orders = [];
    snapshot.forEach((doc) => {
      const data = doc.data();
      orders.push({ 
        id: doc.id,
        ...data,
        customer: data.customer || 'Guest User',
        email: data.email || 'guest@restomart.pk',
        phone: data.phone || 'N/A',
        payment: data.payment || 'Cash on delivery',
        status: (data.status || 'pending').toLowerCase(),
      });
    });
    callback(orders);
  });
};

// Helper to update an order's status
export const updateOrderStatus = async (orderId, newStatus) => {
  const orderRef = doc(db, 'orders', orderId);
  await updateDoc(orderRef, { 
    status: newStatus,
    updatedAt: serverTimestamp() 
  });

  try {
    const orderSnap = await getDoc(orderRef);
    if (orderSnap.exists()) {
      const orderData = orderSnap.data();
      const userId = orderData.userId;
      if (userId) {
        let title = 'Order Update';
        let description = `Your order #${orderId} is now ${newStatus}.`;
        const stLower = (newStatus || '').toLowerCase();
        if (stLower === 'shipped') {
          title = 'Order Shipped! 🚚';
          description = `Your order #${orderId} is on its way.`;
        } else if (stLower === 'delivered' || stLower === 'completed') {
          title = 'Order Delivered! ✅';
          description = `Your order #${orderId} has been delivered. Enjoy!`;
        } else if (stLower === 'cancelled') {
          title = 'Order Cancelled ❌';
          description = `Your order #${orderId} has been cancelled.`;
        }

        await addDoc(collection(db, 'users', userId, 'notifications'), {
          title,
          description,
          action: 'order_view',
          type: 'order_status',
          isRead: false,
          createdAt: serverTimestamp(),
        });
      }
    }
    if ((newStatus || '').toLowerCase().includes('cancel')) {
      await syncLedgerAccountsWithOrders();
    }
  } catch (err) {
    console.error("Error creating user notification in Firestore:", err);
  }
};

// ── Ledger Specific Functions ──

export const syncLedgerAccountsWithOrders = async () => {
  try {
    const ordersSnap = await getDocs(collection(db, 'orders'));
    const accountsSnap = await getDocs(collection(db, 'ledger_accounts'));

    const allOrders = ordersSnap.docs.map(d => ({ id: d.id, ...d.data() }));
    const allAccounts = accountsSnap.docs.map(d => ({ id: d.id, ...d.data() }));

    const accountMap = {};
    allAccounts.forEach(acc => {
      if (acc.id) accountMap[acc.id] = acc;
      if (acc.customerEmail) accountMap[acc.customerEmail.toLowerCase().trim()] = acc;
    });

    const customerOrders = {};
    allOrders.forEach(order => {
      const status = (order.status || '').toLowerCase().trim();
      if (status.includes('cancel') || status.includes('reject')) return;

      const uid = order.userId;
      const email = (order.email || order.billing?.email || '').toLowerCase().trim();

      let targetAccountId = null;
      if (uid && accountMap[uid]) {
        targetAccountId = accountMap[uid].id;
      } else if (!uid && email && accountMap[email]) {
        targetAccountId = accountMap[email].id;
      }

      if (targetAccountId) {
        if (!customerOrders[targetAccountId]) {
          customerOrders[targetAccountId] = [];
        }
        customerOrders[targetAccountId].push({
          id: order.id,
          cleanId: order.id.toString().replaceAll('#', '').trim(),
          total: parseFloat(order.total) || 0,
          payment: order.payment || order.paymentMethod || 'Cash on delivery',
          date: order.date
        });
      }
    });

    for (const accDoc of accountsSnap.docs) {
      const accId = accDoc.id;
      const validOrders = customerOrders[accId] || [];
      const validOrderIds = new Set(validOrders.map(o => o.cleanId));

      // 1. Fetch all transactions for this account
      const txSnap = await getDocs(collection(db, 'ledger_accounts', accId, 'transactions'));
      
      const seenOrderDebits = new Map();
      const docsToDelete = [];
      let totalActualCredit = 0;

      for (const txDoc of txSnap.docs) {
        const data = txDoc.data();
        const pMethod = (data.paymentMethod || '').toString().toLowerCase();
        const desc = (data.description || '').toString();

        // Remove legacy order cancellation reversals so Total Paid (Credit) isn't artificially inflated
        if (pMethod === 'system_reversal' || desc.includes('Reversal for Cancelled Order') || desc.toLowerCase().includes('cancel')) {
          docsToDelete.push(txDoc.ref);
          continue;
        }

        // Sum actual payments received from customer
        if (data.type === 'credit') {
          totalActualCredit += parseFloat(data.amount || 0);
        }

        // Handle debit transactions (orders)
        if (data.type === 'debit') {
          const rawOId = (data.orderId || desc || '').toString().replaceAll('#', '').replace('Order', '').trim();
          
          // If this order does not belong to this account's valid active orders, or is duplicate, delete it!
          if (!validOrderIds.has(rawOId)) {
            docsToDelete.push(txDoc.ref);
          } else if (seenOrderDebits.has(rawOId)) {
            docsToDelete.push(txDoc.ref);
          } else {
            seenOrderDebits.set(rawOId, txDoc.id);
          }
        }
      }

      // Execute transaction document cleanups
      for (const refToDelete of docsToDelete) {
        try {
          await deleteDoc(refToDelete);
        } catch (delErr) {
          console.error("Failed to delete stale transaction:", delErr);
        }
      }

      // 2. Recalculate unique total debit, credit, and balance
      const calculatedDebit = Math.round(validOrders.reduce((sum, o) => sum + (parseFloat(o.total) || 0), 0) * 100) / 100;
      totalActualCredit = Math.round(totalActualCredit * 100) / 100;
      const calculatedBalance = Math.round((calculatedDebit - totalActualCredit) * 100) / 100;

      await updateDoc(doc(db, 'ledger_accounts', accId), {
        totalDebit: calculatedDebit,
        totalCredit: totalActualCredit,
        balance: calculatedBalance,
        updatedAt: serverTimestamp()
      });

      // 3. Ensure active non-cancelled orders have a debit transaction
      for (const ord of validOrders) {
        const cleanOrdId = ord.cleanId;
        if (!seenOrderDebits.has(cleanOrdId)) {
          const cleanDocId = `debit_${cleanOrdId}`;
          const newTxRef = doc(db, 'ledger_accounts', accId, 'transactions', cleanDocId);
          await setDoc(newTxRef, {
            type: 'debit',
            amount: parseFloat(ord.total || 0),
            description: `Order #${ord.id}`,
            orderId: ord.id,
            paymentMethod: ord.payment || 'Cash on delivery',
            date: serverTimestamp(),
            recordedBy: 'system'
          }, { merge: true });
        }
      }
    }
  } catch (err) {
    console.error("Ledger auto-sync error:", err);
  }
};

export const subscribeToLedgerAccounts = (callback, onSyncComplete) => {
  // Trigger background sync for missing order debits
  syncLedgerAccountsWithOrders().finally(() => {
    if (onSyncComplete) onSyncComplete();
  });

  const q = query(collection(db, 'ledger_accounts'), orderBy('updatedAt', 'desc'));
  return onSnapshot(q, (snapshot) => {
    const accounts = [];
    snapshot.forEach((doc) => {
      accounts.push({ id: doc.id, ...doc.data() });
    });
    callback(accounts);
  });
};

export const fetchLedgerTransactions = async (uid) => {
  const txRef = collection(db, 'ledger_accounts', uid, 'transactions');
  const q = query(txRef, orderBy('date', 'desc'));
  const snap = await getDocs(q);

  // Retrieve this account's details to know their customerEmail
  const accSnap = await getDoc(doc(db, 'ledger_accounts', uid));
  const accData = accSnap.exists() ? accSnap.data() : {};
  const accEmail = (accData.customerEmail || '').toLowerCase().trim();

  // Retrieve orders to find cancelled orders and verify which orders strictly belong to this account
  const ordersSnap = await getDocs(collection(db, 'orders'));
  const cancelledIds = new Set();
  const validOrderIds = new Set();

  ordersSnap.forEach((d) => {
    const data = d.data();
    const st = (data.status || '').toLowerCase().trim();
    const cleanId = d.id.toString().replaceAll('#', '').trim();

    if (st.includes('cancel') || st.includes('reject')) {
      cancelledIds.add(cleanId);
      cancelledIds.add(d.id.toString().trim());
      return;
    }

    const oUid = (data.userId || data.uid || '').toString().trim();
    const oEmail = (data.email || data.billing?.email || '').toString().toLowerCase().trim();

    // An order only belongs to this user if it matches UID, or (if guest) matches exact email
    if ((oUid && oUid === uid) || (!oUid && accEmail && oEmail === accEmail)) {
      validOrderIds.add(cleanId);
      validOrderIds.add(d.id.toString().trim());
    }
  });

  return snap.docs
    .map(d => ({ id: d.id, ...d.data() }))
    .filter(txn => {
      const pMethod = (txn.paymentMethod || '').toString().toLowerCase();
      const desc = (txn.description || '').toString();
      const oId = (txn.orderId || desc).toString().replaceAll('#', '').replace('Order', '').trim();

      if (pMethod === 'system_reversal' || desc.includes('Reversal for Cancelled Order') || desc.toLowerCase().includes('cancel')) {
        return false;
      }
      if (cancelledIds.has(oId) || (txn.orderId && cancelledIds.has(txn.orderId.toString().trim()))) {
        return false;
      }

      // If this is a debit transaction, ensure it belongs to this user's valid orders
      if (txn.type === 'debit' && validOrderIds.size > 0 && !validOrderIds.has(oId) && (!txn.orderId || !validOrderIds.has(txn.orderId.toString().trim()))) {
        return false;
      }

      return true;
    });
};

export const recordLedgerPayment = async (uid, amount, paymentMethod, note, orderId = null) => {
  const docRef = doc(db, 'ledger_accounts', uid);
  
  await runTransaction(db, async (transaction) => {
    const docSnap = await transaction.get(docRef);
    if (!docSnap.exists()) {
      throw new Error("Account not found");
    }
    
    const data = docSnap.data();
    const currentDebit = parseFloat(data.totalDebit || 0);
    const currentCredit = parseFloat(data.totalCredit || 0);
    const payAmount = Math.round(parseFloat(amount) * 100) / 100;
    
    const newCredit = Math.round((currentCredit + payAmount) * 100) / 100;
    const newBalance = Math.round((currentDebit - newCredit) * 100) / 100;
    
    let descriptionText = note || 'Payment Received';
    if (orderId && orderId.trim()) {
      const cleanOrderId = orderId.trim();
      descriptionText = descriptionText.includes(`Order #${cleanOrderId}`)
        ? descriptionText
        : `${descriptionText} (Order #${cleanOrderId})`;
    }

    // 1. Create Transaction
    const newTxRef = doc(collection(docRef, 'transactions'));
    transaction.set(newTxRef, {
      type: 'credit',
      amount: payAmount,
      description: descriptionText,
      paymentMethod: paymentMethod,
      date: serverTimestamp(),
      recordedBy: 'admin',
      orderId: orderId && orderId.trim() ? orderId.trim() : null
    });
    
    // 2. Update Account
    transaction.update(docRef, {
      totalCredit: newCredit,
      balance: newBalance,
      updatedAt: serverTimestamp()
    });

    // 3. Create real-time notification document for customer app
    const notifRef = doc(collection(db, 'users', uid, 'notifications'));
    transaction.set(notifRef, {
      title: 'Payment Recorded! 💰',
      description: `We received your payment of Rs. ${payAmount.toLocaleString()} (${paymentMethod}). New balance: Rs. ${newBalance.toLocaleString()}.`,
      type: 'ledger_payment',
      action: 'ledger_view',
      createdAt: serverTimestamp(),
      isRead: false,
      amount: payAmount,
      newBalance: newBalance
    });
  });
};

export const subscribeToAllTransactions = (callback) => {
  const qAccounts = collection(db, 'ledger_accounts');
  return onSnapshot(qAccounts, async (snapshot) => {
    // Get cancelled orders set
    const ordersSnap = await getDocs(collection(db, 'orders'));
    const cancelledIds = new Set();
    ordersSnap.forEach((d) => {
      const data = d.data();
      const st = (data.status || '').toLowerCase().trim();
      if (st.includes('cancel') || st.includes('reject')) {
        cancelledIds.add(d.id.toString().replaceAll('#', '').trim());
        cancelledIds.add(d.id.toString().trim());
      }
    });

    const allTxns = [];
    for (const userDoc of snapshot.docs) {
      const userData = userDoc.data();
      try {
        const txSnap = await getDocs(query(collection(db, 'ledger_accounts', userDoc.id, 'transactions'), orderBy('date', 'desc')));
        txSnap.forEach((txDoc) => {
          const tx = txDoc.data();
          const pMethod = (tx.paymentMethod || '').toString().toLowerCase();
          const desc = (tx.description || '').toString();
          const oId = (tx.orderId || desc).toString().replaceAll('#', '').replace('Order', '').trim();

          if (pMethod === 'system_reversal' || desc.includes('Reversal for Cancelled Order') || desc.toLowerCase().includes('cancel')) {
            return;
          }
          if (cancelledIds.has(oId) || (tx.orderId && cancelledIds.has(tx.orderId.toString().trim()))) {
            return;
          }

          let formattedDate = 'N/A';
          if (tx.date) {
            try {
              formattedDate = tx.date.toDate ? tx.date.toDate().toLocaleString() : new Date(tx.date).toLocaleString();
            } catch (e) {
              formattedDate = 'Recent';
            }
          }
          allTxns.push({
            id: `TXN-${txDoc.id.slice(0, 8).toUpperCase()}`,
            customer: userData.customerName || userData.customerEmail || 'Customer',
            email: userData.customerEmail || 'N/A',
            amount: parseFloat(tx.amount || 0),
            type: tx.type || 'credit',
            method: tx.paymentMethod || 'Cash',
            description: tx.description || (tx.type === 'credit' ? 'Payment Received' : 'Order Debit'),
            date: formattedDate,
            orderId: tx.orderId || '-',
            recordedBy: tx.recordedBy || 'admin'
          });
        });
      } catch (err) {
        console.error("Error fetching transactions for user", userDoc.id, err);
      }
    }
    callback(allTxns);
  });
};
