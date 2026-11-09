import { useState, useEffect, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import { FileText, Download, Eye, Search, X } from 'lucide-react';
import Modal from '../components/shared/Modal';
import InvoiceTemplate from '../components/shared/InvoiceTemplate';
import Loader from '../components/shared/Loader';
import { subscribeToOrders, subscribeToLedgerAccounts } from '../services/firebase';

export default function Invoices() {
  const [searchParams, setSearchParams] = useSearchParams();
  const urlQ = searchParams.get('q') || '';
  const [searchQuery, setSearchQuery] = useState(urlQ);
  const [ordersData, setOrdersData] = useState([]);
  const [ledgerAccounts, setLedgerAccounts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [invoiceOrder, setInvoiceOrder] = useState(null);

  useEffect(() => {
    const qParam = searchParams.get('q') || '';
    setSearchQuery(qParam);
  }, [searchParams]);

  useEffect(() => {
    const unsubscribeOrders = subscribeToOrders((firebaseOrders) => {
      setOrdersData(firebaseOrders);
      setLoading(false);
    });

    const unsubscribeLedger = subscribeToLedgerAccounts((accs) => {
      setLedgerAccounts(accs);
    });

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

  const invoices = useMemo(() => {
    return ordersData
      .filter((order) => {
        const st = (order.status || '').toLowerCase().trim();
        return !st.includes('cancel') && !st.includes('reject');
      })
      .map((order) => ({
        id: `INV-${String(order.id || '').replace(/^RM-/, '')}`,
        orderId: order.id,
        customer: order.customer || 'Customer',
        email: order.email || 'N/A',
        date: order.date || 'N/A',
        amount: parseFloat(order.total || 0),
        itemsCount: Array.isArray(order.items) ? order.items.length : 1,
        status: order.status || 'pending',
        fullOrder: order,
      }));
  }, [ordersData]);

  const filteredInvoices = useMemo(() => {
    if (!searchQuery || !searchQuery.trim()) return invoices;
    const q = searchQuery.toLowerCase().trim();
    const cleanQ = q.replace(/^rm-?/i, '').replace(/^#/i, '').replace(/^inv-?/i, '').trim();

    return invoices.filter((inv) => {
      const id = String(inv.id || '').toLowerCase();
      const cleanInvId = id.replace(/^inv-?/i, '').replace(/^rm-?/i, '').replace(/^#/i, '').trim();
      const orderId = String(inv.orderId || '').toLowerCase();
      const cleanOrderId = orderId.replace(/^rm-?/i, '').replace(/^#/i, '').trim();
      const customer = String(inv.customer || '').toLowerCase();
      const email = String(inv.email || '').toLowerCase();
      const amount = String(inv.amount || '').toLowerCase();

      return (
        id.includes(q) ||
        (cleanQ.length > 0 && cleanInvId.includes(cleanQ)) ||
        orderId.includes(q) ||
        (cleanQ.length > 0 && cleanOrderId.includes(cleanQ)) ||
        customer.includes(q) ||
        email.includes(q) ||
        amount.includes(q)
      );
    });
  }, [invoices, searchQuery]);

  const activeLedgerAccount = invoiceOrder ? ledgerAccounts.find(acc => 
    (invoiceOrder.userId && acc.id === invoiceOrder.userId) || 
    (acc.customerEmail && invoiceOrder.email && acc.customerEmail.toLowerCase().trim() === invoiceOrder.email.toLowerCase().trim())
  ) : null;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text-primary">Invoices</h1>
          <p className="text-sm text-text-secondary mt-1">
            Real-time auto-generated invoices for all store orders
          </p>
        </div>
      </div>

      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
        <input
          type="text"
          placeholder="Search by Invoice ID, Order ID, or Customer..."
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
        <Loader message="Loading real-time invoices..." />
      ) : (
        <div className="bg-white rounded-card shadow-card overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="bg-surface">
                  <th className="table-header text-left py-3 px-4">Invoice ID</th>
                  <th className="table-header text-left py-3 px-4">Order ID</th>
                  <th className="table-header text-left py-3 px-4">Customer</th>
                  <th className="table-header text-left py-3 px-4">Date</th>
                  <th className="table-header text-center py-3 px-4">Items</th>
                  <th className="table-header text-right py-3 px-4">Amount</th>
                  <th className="table-header text-center py-3 px-4">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredInvoices.map((inv) => (
                  <tr key={inv.id} className="hover:bg-surface/50 transition-colors group">
                    <td className="table-cell">
                      <div className="flex items-center gap-2">
                        <FileText className="w-4 h-4 text-primary-500" />
                        <span className="font-semibold text-text-primary">{inv.id}</span>
                      </div>
                    </td>
                    <td className="table-cell font-semibold text-primary-500">{inv.orderId}</td>
                    <td className="table-cell">
                      <div>
                        <p className="font-medium text-text-primary">{inv.customer}</p>
                        <p className="text-xs text-text-muted">{inv.email}</p>
                      </div>
                    </td>
                    <td className="table-cell text-text-secondary">{inv.date}</td>
                    <td className="table-cell text-center">{inv.itemsCount}</td>
                    <td className="table-cell text-right font-semibold">₨ {inv.amount.toLocaleString()}</td>
                    <td className="table-cell text-center">
                      <button
                        onClick={() => setInvoiceOrder(inv.fullOrder)}
                        className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors text-primary-600 font-medium text-xs flex items-center gap-1 mx-auto"
                        title="View Invoice"
                      >
                        <Eye className="w-4 h-4" /> View Invoice
                      </button>
                    </td>
                  </tr>
                ))}

                {filteredInvoices.length === 0 && (
                  <tr>
                    <td colSpan={7} className="text-center py-12 text-text-muted text-sm">
                      No invoices found. Place an order to see live invoices.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Invoice Modal */}
      <Modal
        isOpen={!!invoiceOrder}
        onClose={() => setInvoiceOrder(null)}
        title="Invoice Details"
        size="xl"
      >
        {invoiceOrder && (
          <InvoiceTemplate 
            order={invoiceOrder} 
            ledgerAccount={activeLedgerAccount} 
            onClose={() => setInvoiceOrder(null)} 
          />
        )}
      </Modal>
    </div>
  );
}
