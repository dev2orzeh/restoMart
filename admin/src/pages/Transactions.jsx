import { useState, useEffect } from 'react';
import { Search, ArrowDownLeft, ArrowUpRight } from 'lucide-react';
import StatusBadge from '../components/shared/StatusBadge';
import Loader from '../components/shared/Loader';
import { subscribeToAllTransactions, subscribeToOrders } from '../services/firebase';

export default function Transactions() {
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    let orderTxns = [];
    let ledgerTxns = [];

    const unsubscribeOrders = subscribeToOrders((orders) => {
      orderTxns = orders.map((o) => ({
        id: `TXN-${o.id.replace(/^RM-/, '')}`,
        orderId: o.id,
        customer: o.customer || 'Customer',
        date: o.date || 'N/A',
        amount: parseFloat(o.total || 0),
        method: o.payment || 'Cash on delivery',
        type: 'debit',
        description: `Order ${o.id}`,
        status: o.status === 'delivered' ? 'paid' : o.status === 'cancelled' ? 'failed' : 'pending',
      }));

      combineAndSet();
    });

    const unsubscribeLedger = subscribeToAllTransactions((txns) => {
      ledgerTxns = txns;
      combineAndSet();
    });

    function combineAndSet() {
      // Merge Khata transactions and Order transactions
      const combined = [...ledgerTxns];

      // Add order transactions if not already in ledger
      orderTxns.forEach((ot) => {
        if (!combined.some((t) => t.orderId === ot.orderId)) {
          combined.push(ot);
        }
      });

      setTransactions(combined);
      setLoading(false);
    }

    return () => {
      unsubscribeOrders();
      unsubscribeLedger();
    };
  }, []);

  const filteredTransactions = transactions.filter((txn) => {
    if (!searchQuery) return true;
    const q = searchQuery.toLowerCase();
    return (
      txn.id.toLowerCase().includes(q) ||
      txn.customer.toLowerCase().includes(q) ||
      (txn.orderId && txn.orderId.toLowerCase().includes(q)) ||
      (txn.description && txn.description.toLowerCase().includes(q))
    );
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-text-primary">Transactions</h1>
        <p className="text-sm text-text-secondary mt-1">
          Live payment and ledger records for all orders and received payments
        </p>
      </div>

      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
        <input
          type="text"
          placeholder="Search by Transaction ID, Customer, or Order..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="input-field w-full pl-10"
        />
      </div>

      {loading ? (
        <Loader message="Loading live transactions..." />
      ) : (
        <div className="bg-white rounded-card shadow-card overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="bg-surface">
                  <th className="table-header text-left py-3 px-4">Transaction ID</th>
                  <th className="table-header text-left py-3 px-4">Order ID</th>
                  <th className="table-header text-left py-3 px-4">Customer</th>
                  <th className="table-header text-left py-3 px-4">Description</th>
                  <th className="table-header text-left py-3 px-4">Date</th>
                  <th className="table-header text-right py-3 px-4">Amount</th>
                  <th className="table-header text-center py-3 px-4">Method</th>
                  <th className="table-header text-center py-3 px-4">Type</th>
                </tr>
              </thead>
              <tbody>
                {filteredTransactions.map((txn) => (
                  <tr key={txn.id} className="hover:bg-surface/50 transition-colors">
                    <td className="table-cell font-semibold text-text-primary">{txn.id}</td>
                    <td className="table-cell font-semibold text-primary-500">{txn.orderId}</td>
                    <td className="table-cell text-text-secondary">{txn.customer}</td>
                    <td className="table-cell text-text-secondary font-medium">{txn.description}</td>
                    <td className="table-cell text-text-secondary">{txn.date}</td>
                    <td className="table-cell text-right font-semibold">
                      ₨ {txn.amount.toLocaleString()}
                    </td>
                    <td className="table-cell text-center">
                      <span className="badge bg-amber-50 text-amber-700">{txn.method}</span>
                    </td>
                    <td className="table-cell text-center">
                      {txn.type === 'credit' ? (
                        <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700 bg-emerald-50 px-2.5 py-1 rounded-full border border-emerald-200">
                          <ArrowDownLeft className="w-3.5 h-3.5" /> Received (Credit)
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-xs font-bold text-rose-700 bg-rose-50 px-2.5 py-1 rounded-full border border-rose-200">
                          <ArrowUpRight className="w-3.5 h-3.5" /> Order (Debit)
                        </span>
                      )}
                    </td>
                  </tr>
                ))}

                {filteredTransactions.length === 0 && (
                  <tr>
                    <td colSpan={8} className="text-center py-12 text-text-muted text-sm">
                      No transactions found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
