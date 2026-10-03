import { useState, useEffect } from 'react';
import { ShoppingCart, DollarSign, AlertTriangle, Eye } from 'lucide-react';
import StatCard from '../components/shared/StatCard';
import StatusBadge from '../components/shared/StatusBadge';
import { getProducts, getOrders } from '../services/woocommerce';

export default function Dashboard() {
  const [orders, setOrders] = useState([]);
  const [products, setProducts] = useState([]);
  const [stats, setStats] = useState({
    totalSales: 0,
    activeCustomers: 0,
    totalRevenue: 0,
    refunds: 0,
  });

  useEffect(() => {
    // 1. Fetch Live Orders from WooCommerce
    const fetchWooOrders = async () => {
      try {
        const liveOrders = await getOrders();
        setOrders(liveOrders);
        
        // Calculate real stats
        let revenue = 0;
        let refunds = 0;
        const uniqueCustomers = new Set();
        
        liveOrders.forEach(order => {
          revenue += order.total || 0;
          if (order.email) uniqueCustomers.add(order.email);
          if (order.status === 'cancelled' || order.status === 'refunded') {
            refunds++;
          }
        });
        
        setStats({
          totalSales: liveOrders.length,
          activeCustomers: uniqueCustomers.size,
          totalRevenue: revenue,
          refunds: refunds,
        });
      } catch (e) {
        console.error("Failed to load dashboard orders", e);
      }
    };
    fetchWooOrders();

    // 2. Fetch Live Products from WooCommerce
    const fetchProducts = async () => {
      try {
        const liveProducts = await getProducts(1, 10);
        setProducts(liveProducts);
      } catch (e) {
        console.error("Failed to load products for dashboard", e);
      }
    };
    fetchProducts();
  }, []);

  const recentOrders = orders.slice(0, 5);

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold text-text-primary">Dashboard</h1>
        <p className="text-sm text-text-secondary mt-1">
          Welcome back! Here's what's happening today.
        </p>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <StatCard
          icon={ShoppingCart}
          title="Total Sales"
          value={stats.totalSales.toString()}
          changeText="Live from Firebase"
          isPrimary={true}
        />
        <StatCard
          icon={Eye}
          title="Active Customers"
          value={stats.activeCustomers.toString()}
          changeText="Unique buyers"
        />
        <StatCard
          icon={DollarSign}
          title="Total Revenue"
          value={`Rs. ${stats.totalRevenue.toLocaleString()}`}
          changeText="Live from Firebase"
        />
        <StatCard
          icon={AlertTriangle}
          title="Refund/Cancel Requests"
          value={stats.refunds.toString()}
          changeText="Live from Firebase"
        />
      </div>

      {/* Top Products */}
      <div className="bg-[#F6F5F2] rounded-[32px] p-8 shadow-sm w-full">
        <div className="flex justify-between items-center mb-8">
          <h2 className="text-[22px] font-bold text-gray-900">Top Products</h2>
          <button className="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-sm text-gray-700 hover:bg-gray-50 transition-colors">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="12" cy="12" r="1"></circle>
              <circle cx="19" cy="12" r="1"></circle>
              <circle cx="5" cy="12" r="1"></circle>
            </svg>
          </button>
        </div>
        
        <div className="space-y-6">
          {products.slice(0, 6).map((product) => (
            <div key={product.id} className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="w-14 h-14 rounded-xl bg-gray-200 overflow-hidden flex-shrink-0">
                  {product.image ? (
                    <img src={product.image} alt={product.name} className="w-full h-full object-cover" />
                  ) : (
                    <div className="w-full h-full bg-gray-300 flex items-center justify-center text-xs">No Img</div>
                  )}
                </div>
                <div>
                  <h3 className="text-[17px] font-bold text-gray-900">{product.name}</h3>
                  <p className="text-[15px] text-gray-500 font-medium mt-0.5">{product.category}</p>
                </div>
              </div>
              <span className="text-[17px] font-bold text-gray-900">₨ {product.price}</span>
            </div>
          ))}
          {products.length === 0 && <p className="text-gray-500">Loading WooCommerce products...</p>}
        </div>
      </div>

      {/* Recent Orders Table */}
      <div className="bg-white rounded-card shadow-card overflow-hidden">
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <h2 className="text-base font-bold text-text-primary">
            Recent Orders
          </h2>
          <a
            href="/orders"
            className="text-sm text-primary-500 hover:text-primary-600 font-medium"
          >
            View All →
          </a>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="bg-surface">
                <th className="table-header text-left py-3 px-4">Order ID</th>
                <th className="table-header text-left py-3 px-4">Customer</th>
                <th className="table-header text-left py-3 px-4">Date</th>
                <th className="table-header text-right py-3 px-4">Total</th>
                <th className="table-header text-center py-3 px-4">Status</th>
                <th className="table-header text-center py-3 px-4">Action</th>
              </tr>
            </thead>
            <tbody>
              {recentOrders.map((order) => (
                <tr
                  key={order.id}
                  className="hover:bg-surface/50 transition-colors"
                >
                  <td className="table-cell font-semibold text-primary-500">
                    {order.id}
                  </td>
                  <td className="table-cell">
                    <div>
                      <p className="font-medium text-text-primary">
                        {order.customer}
                      </p>
                      <p className="text-xs text-text-muted">{order.email}</p>
                    </div>
                  </td>
                  <td className="table-cell text-text-secondary">
                    {order.date}
                  </td>
                  <td className="table-cell text-right font-semibold">
                    ₨ {order.total.toLocaleString()}
                  </td>
                  <td className="table-cell text-center">
                    <StatusBadge status={order.status} />
                  </td>
                  <td className="table-cell text-center">
                    <a href="/orders" className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors inline-block">
                      <Eye className="w-4 h-4 text-text-secondary" />
                    </a>
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
