import { useState } from 'react';
import { FileText, Download, Eye } from 'lucide-react';
import { mockOrders } from '../data/mockData';
import Modal from '../components/shared/Modal';
import InvoiceTemplate from '../components/shared/InvoiceTemplate';

export default function Invoices() {
  const [invoiceOrder, setInvoiceOrder] = useState(null);

  const invoices = mockOrders
    .filter((o) => o.status === 'delivered')
    .map((order) => ({
      id: `INV-${order.id.split('-').pop()}`,
      orderId: order.id,
      customer: order.customer,
      email: order.email,
      date: order.date,
      amount: order.total,
      items: order.items.length,
      fullOrder: order,
    }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-text-primary">Invoices</h1>
        <p className="text-sm text-text-secondary mt-1">
          Auto-generated invoices for completed orders
        </p>
      </div>

      <div className="bg-white rounded-card shadow-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="bg-surface">
                <th className="table-header text-left py-3 px-4">Invoice ID</th>
                <th className="table-header text-left py-3 px-4">Order</th>
                <th className="table-header text-left py-3 px-4">Customer</th>
                <th className="table-header text-left py-3 px-4">Date</th>
                <th className="table-header text-center py-3 px-4">Items</th>
                <th className="table-header text-right py-3 px-4">Amount</th>
                <th className="table-header text-center py-3 px-4">Actions</th>
              </tr>
            </thead>
            <tbody>
              {invoices.map((inv) => (
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
                  <td className="table-cell text-center">{inv.items}</td>
                  <td className="table-cell text-right font-semibold">₨ {inv.amount.toLocaleString()}</td>
                  <td className="table-cell text-center">
                    <div className="flex items-center justify-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button 
                        onClick={() => setInvoiceOrder(inv.fullOrder)}
                        className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors" 
                        title="View Invoice"
                      >
                        <Eye className="w-4 h-4 text-text-secondary" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}

              {invoices.length === 0 && (
                <tr>
                  <td colSpan={7} className="text-center py-12 text-text-muted text-sm">
                    No invoices generated yet. Invoices are created when orders are delivered.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Invoice Modal */}
      <Modal
        isOpen={!!invoiceOrder}
        onClose={() => setInvoiceOrder(null)}
        title="Invoice"
        size="xl"
      >
        {invoiceOrder && (
          <InvoiceTemplate order={invoiceOrder} onClose={() => setInvoiceOrder(null)} />
        )}
      </Modal>
    </div>
  );
}
