import { useState, useEffect, useMemo } from 'react';
import { Search, Eye, ShoppingBag, Wallet } from 'lucide-react';
import { mockCustomers } from '../data/mockData';
import { getCustomers } from '../services/woocommerce';
import { subscribeToLedgerAccounts, subscribeToOrders } from '../services/firebase';
import Loader from '../components/shared/Loader';

export default function Customers() {
  const [searchQuery, setSearchQuery] = useState('');
  const [ledgerAccounts, setLedgerAccounts] = useState([]);
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;

    // 1. Subscribe to Live Orders for exact order counts
    const unsubOrders = subscribeToOrders((liveOrders) => {
      if (isMounted) {
        setOrders(liveOrders);
      }
    });

    // 2. Subscribe to Firebase Ledger Accounts with sync completion signal
    const unsubLedger = subscribeToLedgerAccounts(
      (fbAccounts) => {
        if (!isMounted) return;
        setLedgerAccounts(fbAccounts);
      },
      () => {
        if (isMounted) {
          setLoading(false);
        }
      }
    );

    return () => {
      isMounted = false;
      unsubOrders();
      unsubLedger();
    };
  }, []);

  // Compute exact orders count & ledger balance for each customer
  const customersList = useMemo(() => {
    if (!ledgerAccounts || ledgerAccounts.length === 0) return [];

    // Map order counts per email & phone
    const orderCountMap = {};
    orders.forEach(o => {
      if (o.status === 'cancelled') return;
      const email = (o.email || o.billing?.email || '').toLowerCase().trim();
      const phone = (o.phone || o.billing?.phone || '').trim();
      if (email) orderCountMap[email] = (orderCountMap[email] || 0) + 1;
      if (phone) orderCountMap[phone] = (orderCountMap[phone] || 0) + 1;
    });

    return ledgerAccounts.map((acc) => {
      const email = (acc.customerEmail || acc.id || '').toLowerCase().trim();
      const phone = (acc.customerPhone || '').trim();
      const count = orderCountMap[email] || orderCountMap[phone] || (acc.totalDebit > 0 ? 1 : 0);
      const bal = Math.round(parseFloat(acc.balance || 0) * 100) / 100;

      let lastDate = 'Recent';
      let lastTime = '';
      if (acc.updatedAt?.toDate) {
        const d = acc.updatedAt.toDate();
        lastDate = d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
        lastTime = d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true });
      } else if (acc.updatedAt) {
        const d = new Date(acc.updatedAt);
        if (!isNaN(d.getTime())) {
          lastDate = d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
          lastTime = d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true });
        }
      }

      return {
        id: acc.id,
        name: acc.customerName || 'RestoMart Customer',
        email: acc.customerEmail || 'N/A',
        phone: acc.customerPhone || 'N/A',
        totalOrders: count,
        balance: bal,
        totalDebit: parseFloat(acc.totalDebit || 0),
        totalCredit: parseFloat(acc.totalCredit || 0),
        lastOrder: lastDate,
        lastTime: lastTime,
      };
    });
  }, [ledgerAccounts, orders]);

  const filtered = searchQuery
    ? customersList.filter(
        (c) =>
          c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          c.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
          c.phone.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : customersList;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-text-primary">Customers</h1>
        <p className="text-sm text-text-secondary mt-1">
          Your restaurant and business clients registered in RestoMart
        </p>
      </div>

      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
        <input
          type="text"
          placeholder="Search customers by name, email, or phone..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="input-field w-full pl-10"
        />
      </div>

      {loading ? (
        <Loader message="Fetching & verifying live customer accounts..." />
      ) : (
      <div className="bg-white rounded-card shadow-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="bg-surface">
                <th className="table-header text-left py-3.5 px-4">Customer</th>
                <th className="table-header text-left py-3.5 px-4">Phone</th>
                <th className="table-header text-center py-3.5 px-4">Orders Placed</th>
                <th className="table-header text-right py-3.5 px-4">Khata Balance / Surplus</th>
                <th className="table-header text-left py-3.5 px-4">Last Activity</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((customer) => (
                <tr
                  key={customer.id}
                  className="hover:bg-surface/50 transition-colors group"
                >
                  <td className="table-cell">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-full bg-gradient-to-br from-primary-400 to-primary-600 flex items-center justify-center text-white text-sm font-bold flex-shrink-0 shadow-sm">
                        {customer.name.split(' ').map((n) => n[0]).join('')}
                      </div>
                      <div>
                        <p className="font-semibold text-text-primary text-sm">
                          {customer.name}
                        </p>
                        <p className="text-xs text-text-muted">
                          {customer.email}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td className="table-cell text-text-secondary font-medium">
                    {customer.phone}
                  </td>
                  <td className="table-cell text-center">
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-indigo-50 text-indigo-700 border border-indigo-100">
                      <ShoppingBag className="w-3.5 h-3.5" />
                      {customer.totalOrders} {customer.totalOrders === 1 ? 'Order' : 'Orders'}
                    </span>
                  </td>
                  <td className="table-cell text-right">
                    {customer.balance > 0 ? (
                      <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-bold bg-red-50 text-red-700 border border-red-200">
                        ₨ {customer.balance.toLocaleString()} (Debt)
                      </span>
                    ) : customer.balance < 0 ? (
                      <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                        ₨ {Math.abs(customer.balance).toLocaleString()} (Surplus)
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-700 border border-gray-200">
                        ₨ 0 (Cleared)
                      </span>
                    )}
                  </td>
                  <td className="table-cell text-text-secondary text-xs">
                    <div className="font-semibold text-text-primary">{customer.lastOrder}</div>
                    {customer.lastTime && (
                      <div className="text-[11px] text-text-muted mt-0.5 font-mono">{customer.lastTime}</div>
                    )}
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={5} className="text-center py-8 text-sm text-gray-500">
                    No customers found matching your search.
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
