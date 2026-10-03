import { useState, useMemo, useEffect } from 'react';
import { Search, Eye, Calendar, ChevronDown, Download, Package, Clock, CheckCircle, XCircle, Truck } from 'lucide-react';
import StatusBadge from '../components/shared/StatusBadge';
import Modal from '../components/shared/Modal';
import InvoiceTemplate from '../components/shared/InvoiceTemplate';
import { mockOrders } from '../data/mockData';
import { subscribeToOrders, updateOrderStatus } from '../services/firebase';
import { updateOrder, getOrders } from '../services/woocommerce';

const statusOptions = ['all', 'pending', 'processing', 'shipped', 'delivered', 'cancelled'];

const statusTimeline = {
  pending: 0,
  processing: 1,
  delivered: 3,
  cancelled: -1,
};

const timelineSteps = [
  { key: 'pending', label: 'Order Placed', icon: Package },
  { key: 'processing', label: 'Processing', icon: Clock },
  { key: 'shipped', label: 'Shipped', icon: Truck },
  { key: 'delivered', label: 'Delivered', icon: CheckCircle },
];

export default function Orders() {
  const [ordersData, setOrdersData] = useState([]); // Start empty for Firestore
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [invoiceOrder, setInvoiceOrder] = useState(null);

  useEffect(() => {
    let isMounted = true;
    
    // Fetch live orders from WooCommerce
    const fetchWooOrders = async () => {
      try {
        const liveOrders = await getOrders();
        if (isMounted) {
          if (liveOrders.length === 0) {
            // Keep mock if absolutely 0 orders exist, just so UI has something to show in dev
            setOrdersData(mockOrders);
          } else {
            setOrdersData(liveOrders);
          }
        }
      } catch (e) {
        console.error("Failed to fetch woo orders", e);
      }
    };
    
    fetchWooOrders();
    
    // Optional polling for new orders every 30 seconds
    const interval = setInterval(fetchWooOrders, 30000);

    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, []);

  const filteredOrders = useMemo(() => {
    let orders = [...ordersData];

    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      orders = orders.filter(
        (o) =>
          o.id.toLowerCase().includes(q) ||
          o.customer.toLowerCase().includes(q)
      );
    }

    if (statusFilter !== 'all') {
      orders = orders.filter((o) => o.status === statusFilter);
    }

    return orders;
  }, [searchQuery, statusFilter, ordersData]);

  const handleExportCSV = () => {
    const headers = ['Order ID', 'Customer', 'Date', 'Items', 'Total', 'Status', 'Payment'];
    const rows = filteredOrders.map((o) => [
      o.id,
      o.customer,
      o.date,
      o.items.length,
      o.total,
      o.status,
      o.payment,
    ]);

    const csv = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'RestoMart-Orders.csv';
    link.click();
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text-primary">Orders</h1>
          <p className="text-sm text-text-secondary mt-1">
            Track and manage all incoming orders
          </p>
        </div>
        <button onClick={handleExportCSV} className="btn-outline flex items-center gap-2">
          <Download className="w-4 h-4" />
          Export CSV
        </button>
      </div>

      {/* Toolbar */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[200px] max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
          <input
            type="text"
            placeholder="Search by Order ID or Customer..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="input-field w-full pl-10"
          />
        </div>

        <button className="btn-outline flex items-center gap-2">
          <Calendar className="w-4 h-4" />
          Select Date
        </button>

        <div className="relative">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="input-field appearance-none pr-8 cursor-pointer"
          >
            {statusOptions.map((s) => (
              <option key={s} value={s}>
                {s === 'all' ? 'All Statuses' : s.charAt(0).toUpperCase() + s.slice(1)}
              </option>
            ))}
          </select>
          <ChevronDown className="absolute right-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted pointer-events-none" />
        </div>
      </div>

      {/* Orders Table */}
      <div className="bg-white rounded-card shadow-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="bg-surface">
                <th className="table-header text-left py-3 px-4">Order ID</th>
                <th className="table-header text-left py-3 px-4">Customer</th>
                <th className="table-header text-left py-3 px-4">Date</th>
                <th className="table-header text-center py-3 px-4">Items</th>
                <th className="table-header text-right py-3 px-4">Total</th>
                <th className="table-header text-center py-3 px-4">Payment</th>
                <th className="table-header text-center py-3 px-4">Status</th>
                <th className="table-header text-center py-3 px-4">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredOrders.map((order) => (
                <tr
                  key={order.id}
                  className="hover:bg-surface/50 transition-colors group"
                >
                  <td className="table-cell font-semibold text-primary-500">
                    {order.id}
                  </td>
                  <td className="table-cell">
                    <div>
                      <p className="font-medium text-text-primary">
                        {order.customer}
                      </p>
                      <p className="text-xs text-text-muted">{order.phone}</p>
                    </div>
                  </td>
                  <td className="table-cell text-text-secondary">
                    {order.date}
                  </td>
                  <td className="table-cell text-center">
                    <span className="text-sm font-medium">
                      {order.items.length} {order.items.length === 1 ? 'item' : 'items'}
                    </span>
                  </td>
                  <td className="table-cell text-right font-semibold">
                    ₨ {order.total.toLocaleString()}
                  </td>
                  <td className="table-cell text-center">
                    <span className="badge bg-amber-50 text-amber-700">
                      {order.payment}
                    </span>
                  </td>
                  <td className="table-cell text-center">
                    <StatusBadge status={order.status} />
                  </td>
                  <td className="table-cell text-center">
                    <div className="flex items-center justify-center gap-1">
                      <button
                        onClick={() => setSelectedOrder(order)}
                        className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors"
                        title="View Details"
                      >
                        <Eye className="w-4 h-4 text-text-secondary" />
                      </button>
                      {order.status === 'delivered' ? (
                        <div className="flex items-center gap-1.5 text-emerald-600 text-xs font-semibold px-2 py-1 bg-emerald-50 rounded-md border border-emerald-100">
                          <CheckCircle className="w-3.5 h-3.5" /> Delivered
                        </div>
                      ) : (
                        <select 
                          className="text-xs border border-gray-200 rounded-md py-1 px-2 focus:ring-1 focus:ring-primary-500 bg-white"
                          value={order.status}
                          onChange={async (e) => {
                            const newStatus = e.target.value;
                            try {
                              await Promise.all([
                                updateOrderStatus(order.id, newStatus),
                                updateOrder(order.id, newStatus)
                              ]);
                            } catch (error) {
                              console.error("Failed to update status", error);
                            }
                          }}
                        >
                          <option value="pending">Pending</option>
                          <option value="processing">Processing</option>
                          <option value="shipped">Shipped</option>
                          <option value="delivered">Delivered</option>
                          <option value="cancelled">Cancelled</option>
                        </select>
                      )}
                    </div>
                  </td>
                </tr>
              ))}

              {filteredOrders.length === 0 && (
                <tr>
                  <td
                    colSpan={8}
                    className="text-center py-12 text-text-muted text-sm"
                  >
                    No orders found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* View Order Modal */}
      <Modal
        isOpen={!!selectedOrder}
        onClose={() => setSelectedOrder(null)}
        title={`Order ${selectedOrder?.id || ''}`}
        size="lg"
      >
        {selectedOrder && (
          <div className="space-y-6">
            {/* Status Timeline */}
            {selectedOrder.status !== 'cancelled' ? (
              <div className="flex items-center justify-between">
                {timelineSteps.map((step, i) => {
                  const currentStep = statusTimeline[selectedOrder.status] ?? 0;
                  const isActive = i <= currentStep;
                  const isLast = i === timelineSteps.length - 1;

                  return (
                    <div key={step.key} className="flex items-center flex-1">
                      <div className="flex flex-col items-center">
                        <div className={`w-10 h-10 rounded-full flex items-center justify-center ${isActive ? 'bg-primary-500 text-white' : 'bg-gray-100 text-gray-400'}`}>
                          <step.icon className="w-5 h-5" />
                        </div>
                        <span className={`text-[11px] mt-2 font-medium ${isActive ? 'text-primary-500' : 'text-gray-400'}`}>
                          {step.label}
                        </span>
                      </div>
                      {!isLast && (
                        <div className={`flex-1 h-0.5 mx-2 mb-6 ${i < currentStep ? 'bg-primary-500' : 'bg-gray-200'}`} />
                      )}
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="flex items-center gap-3 p-4 bg-red-50 rounded-xl border border-red-200">
                <XCircle className="w-5 h-5 text-red-500" />
                <div>
                  <p className="text-sm font-semibold text-red-700">Order Cancelled</p>
                  <p className="text-xs text-red-500">This order has been cancelled by the customer.</p>
                </div>
              </div>
            )}

            {/* Customer Info */}
            <div className="grid grid-cols-2 gap-4">
              <div className="bg-surface rounded-xl p-4">
                <p className="text-xs font-semibold text-text-muted uppercase tracking-wider mb-2">Customer</p>
                <p className="text-sm font-semibold text-text-primary">{selectedOrder.customer}</p>
                <p className="text-xs text-text-secondary mt-1">{selectedOrder.email}</p>
                <p className="text-xs text-text-secondary">{selectedOrder.phone}</p>
              </div>
              <div className="bg-surface rounded-xl p-4">
                <p className="text-xs font-semibold text-text-muted uppercase tracking-wider mb-2">Order Info</p>
                <p className="text-sm text-text-secondary"><span className="font-medium text-text-primary">Date:</span> {selectedOrder.date}</p>
                <p className="text-sm text-text-secondary"><span className="font-medium text-text-primary">Payment:</span> {selectedOrder.payment}</p>
                <p className="text-sm text-text-secondary"><span className="font-medium text-text-primary">Status:</span> <StatusBadge status={selectedOrder.status} /></p>
              </div>
            </div>

            {/* Items */}
            <div>
              <p className="text-xs font-semibold text-text-muted uppercase tracking-wider mb-3">Order Items</p>
              <div className="space-y-2">
                {selectedOrder.items.map((item, i) => (
                  <div key={i} className="flex items-center justify-between p-3 bg-surface rounded-lg">
                    <div>
                      <p className="text-sm font-medium text-text-primary">{item.name}</p>
                      <p className="text-xs text-text-muted">Qty: {item.qty} × ₨ {item.price.toLocaleString()}</p>
                    </div>
                    <p className="text-sm font-bold text-text-primary">₨ {(item.qty * item.price).toLocaleString()}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Total */}
            <div className="flex justify-between items-center pt-4 border-t border-border">
              <span className="text-base font-bold text-text-primary">Total</span>
              <span className="text-xl font-bold text-primary-500">₨ {selectedOrder.total.toLocaleString()}</span>
            </div>

            {/* Actions */}
            <div className="flex gap-3 pt-2 justify-between items-center">
              <div className="flex items-center gap-2">
                <span className="text-sm font-medium text-text-secondary">Update Status:</span>
                <select 
                  className="input-field py-1.5 px-3 text-sm"
                  value={selectedOrder.status}
                  onChange={async (e) => {
                    const newStatus = e.target.value;
                    // Update in Firestore
                    try {
                      await Promise.all([
                        updateOrderStatus(selectedOrder.id, newStatus),
                        updateOrder(selectedOrder.id, newStatus)
                      ]);
                      setSelectedOrder({ ...selectedOrder, status: newStatus });
                    } catch (error) {
                      // Fallback for mock data testing if Firestore doc doesn't exist
                      const updatedOrders = ordersData.map(o => 
                        o.id === selectedOrder.id ? { ...o, status: newStatus } : o
                      );
                      setOrdersData(updatedOrders);
                      setSelectedOrder({ ...selectedOrder, status: newStatus });
                    }
                  }}
                >
                  <option value="pending">Pending</option>
                  <option value="processing">Processing</option>
                  <option value="shipped">Shipped</option>
                  <option value="delivered">Delivered</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              </div>

              <button
                onClick={() => {
                  setSelectedOrder(null);
                  setInvoiceOrder(selectedOrder);
                }}
                className="btn-primary flex items-center gap-2"
              >
                <Download className="w-4 h-4" />
                Download Invoice
              </button>
            </div>
          </div>
        )}
      </Modal>

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
