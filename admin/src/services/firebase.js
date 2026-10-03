import { initializeApp } from 'firebase/app';
import { getFirestore, collection, onSnapshot, doc, updateDoc, query, orderBy, runTransaction, serverTimestamp, getDocs, setDoc } from 'firebase/firestore';

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
    status: newStatus
  });
};

// ── Ledger Specific Functions ──

export const subscribeToLedgerAccounts = (callback) => {
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
  return snap.docs.map(d => ({ id: d.id, ...d.data() }));
};

export const recordLedgerPayment = async (uid, amount, paymentMethod, note) => {
  const docRef = doc(db, 'ledger_accounts', uid);
  
  await runTransaction(db, async (transaction) => {
    const docSnap = await transaction.get(docRef);
    if (!docSnap.exists()) {
      throw new Error("Account not found");
    }
    
    const data = docSnap.data();
    const currentDebit = data.totalDebit || 0;
    const currentCredit = data.totalCredit || 0;
    
    const newCredit = currentCredit + parseFloat(amount);
    const newBalance = currentDebit - newCredit;
    
    // 1. Create Transaction
    const newTxRef = doc(collection(docRef, 'transactions'));
    transaction.set(newTxRef, {
      type: 'credit',
      amount: parseFloat(amount),
      description: note || 'Payment Received',
      paymentMethod: paymentMethod,
      date: serverTimestamp(),
      recordedBy: 'admin',
      orderId: null
    });
    
    // 2. Update Account
    transaction.update(docRef, {
      totalCredit: newCredit,
      balance: newBalance,
      updatedAt: serverTimestamp()
    });
  });
};
