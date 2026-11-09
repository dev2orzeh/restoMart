import { useState, useEffect, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Search, ArrowDownLeft, ArrowUpRight, X } from 'lucide-react';
import StatusBadge from '../components/shared/StatusBadge';
import Loader from '../components/shared/Loader';
import { subscribeToAllTransactions, subscribeToOrders } from '../services/firebase';

export default function Transactions() {
  const [searchParams, setSearchParams] = useSearchParams();
  const urlQ = searchParams.get('q') || '';
  const [searchQuery, setSearchQuery] = useState(urlQ);
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const qParam = searchParams.get('q') || '';
    setSearchQuery(qParam);
  }, [searchParams]);

  useEffect(() => {
    let orderTxns = [];
    let ledgerTxns = [];

    let allOrdersList = [];

    const unsubscribeOrders = subscribeToOrders((orders) => {
      allOrdersList = orders;
      const activeOrders = orders.filter((o) => {
        const st = (o.status || '').toLowerCase().trim();
        return !st.includes('cancel') && !st.includes('reject');
      });

      orderTxns = activeOrders.map((o) => ({
        id: `TXN-${String(o.id || '').replace(/^RM-/, '')}`,
        orderId: o.id,
        customer: o.customer || 'Customer',
        date: o.date || 'N/A',
        amount: parseFloat(o.total || 0),
        method: o.payment || 'Cash on delivery',
        type: 'debit',
        description: `Order #${String(o.id || '').replace(/^#/, '')}`,
        status: o.status === 'delivered' ? 'paid' : 'pending',
      }));

      combineAndSet();
    });

    const unsubscribeLedger = subscribeToAllTransactions((txns) => {
      ledgerTxns = txns;
      combineAndSet();
    });

    function combineAndSet() {
      const cancelledIds = new Set(
        allOrdersList
          .filter((o) => {
            const st = (o.status || '').toLowerCase().trim();
            return st.includes('cancel') || st.includes('reject');
          })
          .map((o) => String(o.id || '').replaceAll('#', '').trim())
      );

      // Merge Khata transactions and Order transactions, filtering out any cancelled orders or reversals
      const combined = ledgerTxns.filter((t) => {
        const oId = String(t.orderId || t.description || '').replaceAll('#', '').replace('Order', '').trim();
        const desc = String(t.description || '').toLowerCase();
        const pMethod = String(t.method || '').toLowerCase();
        if (pMethod === 'system_reversal' || desc.includes('cancel') || desc.includes('reversal')) {
          return false;
        }
        if (cancelledIds.has(oId)) {
          return false;
        }
        return true;
      });

      // Add order transactions if not already in ledger
      orderTxns.forEach((ot) => {
        const cleanOtId = String(ot.orderId || '').replaceAll('#', '').trim();
        if (!cancelledIds.has(cleanOtId) && !combined.some((t) => String(t.orderId || '').replaceAll('#', '').trim() === cleanOtId)) {
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

  const handleSearchChange = (val) => {
    setSearchQuery(val);
    if (val.trim()) {
      setSearchParams({ q: val }, { replace: true });
    } else {
      setSearchParams({}, { replace: true });
    }
  };

  const filteredTransactions = useMemo(() => {
    if (!searchQuery || !searchQuery.trim()) return transactions;
    const q = searchQuery.toLowerCase().trim();
    const cleanQ = q.replace(/^rm-?/i, '').replace(/^#/i, '').trim();

    return transactions.filter((txn) => {
      const id = String(txn.id || '').toLowerCase();
      const customer = String(txn.customer || '').toLowerCase();
      const orderId = String(txn.orderId || '').toLowerCase();
      const cleanOrderId = orderId.replace(/^rm-?/i, '').replace(/^#/i, '').trim();
      const description = String(txn.description || '').toLowerCase();
      const method = String(txn.method || '').toLowerCase();
      const amount = String(txn.amount || '').toLowerCase();

      return (
        id.includes(q) ||
        (cleanQ.length > 0 && id.includes(cleanQ)) ||
        customer.includes(q) ||
        orderId.includes(q) ||
        (cleanQ.length > 0 && cleanOrderId.includes(cleanQ)) ||
        description.includes(q) ||
        (cleanQ.length > 0 && description.includes(cleanQ)) ||
        method.includes(q) ||
        amount.includes(q)
      );
    });
  }, [transactions, searchQuery]);

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
          onChange={(e) => handleSearchChange(e.target.value)}
          className="input-field w-full pl-10 pr-9"
        />
        {searchQuery && (
          <button
            onClick={() => handleSearchChange('')}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-text-muted hover:text-text-primary p-0.5"
            title="Clear search"
          >
            <X className="w-4 h-4" />
          </button>
        )}
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
