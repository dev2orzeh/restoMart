import { Search } from 'lucide-react';
import StatusBadge from '../components/shared/StatusBadge';
import { mockOrders } from '../data/mockData';

export default function Transactions() {
  const transactions = mockOrders.map((order) => ({
    id: `TXN-${order.id.split('-').pop()}`,
    orderId: order.id,
    customer: order.customer,
    date: order.date,
    amount: order.total,
    method: order.payment,
    status: order.status === 'delivered' ? 'paid' : order.status === 'cancelled' ? 'failed' : 'pending',
  }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-text-primary">Transactions</h1>
        <p className="text-sm text-text-secondary mt-1">
          Payment records for all orders
        </p>
      </div>

      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
        <input
          type="text"
          placeholder="Search transactions..."
          className="input-field w-full pl-10"
        />
      </div>

      <div className="bg-white rounded-card shadow-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="bg-surface">
                <th className="table-header text-left py-3 px-4">Transaction ID</th>
                <th className="table-header text-left py-3 px-4">Order</th>
                <th className="table-header text-left py-3 px-4">Customer</th>
                <th className="table-header text-left py-3 px-4">Date</th>
                <th className="table-header text-right py-3 px-4">Amount</th>
                <th className="table-header text-center py-3 px-4">Method</th>
                <th className="table-header text-center py-3 px-4">Status</th>
              </tr>
            </thead>
            <tbody>
              {transactions.map((txn) => (
                <tr key={txn.id} className="hover:bg-surface/50 transition-colors">
                  <td className="table-cell font-semibold text-text-primary">{txn.id}</td>
                  <td className="table-cell font-semibold text-primary-500">{txn.orderId}</td>
                  <td className="table-cell text-text-secondary">{txn.customer}</td>
                  <td className="table-cell text-text-secondary">{txn.date}</td>
                  <td className="table-cell text-right font-semibold">₨ {txn.amount.toLocaleString()}</td>
                  <td className="table-cell text-center">
                    <span className="badge bg-amber-50 text-amber-700">{txn.method}</span>
                  </td>
                  <td className="table-cell text-center">
                    <StatusBadge status={txn.status} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
