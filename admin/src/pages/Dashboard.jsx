import { useState, useEffect, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { ShoppingCart, DollarSign, AlertTriangle, Eye } from 'lucide-react';
import StatCard from '../components/shared/StatCard';
import StatusBadge from '../components/shared/StatusBadge';
import Loader from '../components/shared/Loader';
import { getProducts } from '../services/woocommerce';
import { subscribeToOrders, subscribeToLedgerAccounts } from '../services/firebase';

export default function Dashboard() {
  const [orders, setOrders] = useState([]);
  const [products, setProducts] = useState([]);
  const [ledgerAccounts, setLedgerAccounts] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  const [stats, setStats] = useState({
    totalSales: 0,
    totalRevenue: 0,
    refunds: 0,
  });

  useEffect(() => {
    let isMounted = true;

    // Safety timeout: ensure dashboard displays after 1.5 seconds max even if network is slow
    const timer = setTimeout(() => {
      if (isMounted) setLoading(false);
    }, 1500);

    // 1. Subscribe to Live Orders from Firestore
    const unsubscribeOrders = subscribeToOrders((liveOrders) => {
      if (!isMounted) return;
      setOrders(liveOrders);

      // Calculate real stats
      let revenue = 0;
      let refunds = 0;

      liveOrders.forEach((order) => {
        revenue += parseFloat(order.total || 0);
        if (order.status === 'cancelled' || order.status === 'refunded') {
          refunds++;
        }
      });

      setStats({
        totalSales: liveOrders.length,
        totalRevenue: Math.round(revenue * 100) / 100,
        refunds: refunds,
      });

      setLoading(false);
    });

    // 2. Subscribe to Firebase Ledger Accounts for Active Customers
    const unsubscribeLedger = subscribeToLedgerAccounts((accs) => {
      if (isMounted) {
        setLedgerAccounts(accs);
      }
    });

    // 3. Fetch Live Products from WooCommerce
    const fetchProducts = async () => {
      try {
        const liveProducts = await getProducts();
        if (isMounted) setProducts(liveProducts);
      } catch (e) {
        console.error("Failed to load products for dashboard", e);
      }
    };
    fetchProducts();

    return () => {
      isMounted = false;
      clearTimeout(timer);
      unsubscribeOrders();
      unsubscribeLedger();
    };
  }, []);

  // Compute Active Customer count (matches Analytics page)
  const activeCustomersCount = useMemo(() => {
    const customerSet = new Set();
    orders.forEach(o => {
      const email = (o.email || o.billing?.email || '').toLowerCase().trim();
      if (email) customerSet.add(email);
    });
    ledgerAccounts.forEach(a => {
      const email = (a.customerEmail || a.id || '').toLowerCase().trim();
      if (email) customerSet.add(email);
    });
    return Math.max(customerSet.size, ledgerAccounts.length);
  }, [orders, ledgerAccounts]);

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

      {loading ? (
        <Loader message="Loading dashboard..." />
      ) : (
      <>
      {/* Stat Cards - Interactive & Navigable */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <StatCard
          icon={ShoppingCart}
          title="Total Sales"
          value={stats.totalSales.toString()}
          changeText="Live from Firebase"
          isPrimary={true}
          onClick={() => navigate('/orders')}
        />
        <StatCard
          icon={Eye}
          title="Active Customers"
          value={activeCustomersCount.toString()}
          changeText="Live registered clients"
          color="blue"
          onClick={() => navigate('/customers')}
        />
        <StatCard
          icon={DollarSign}
          title="Total Revenue"
          value={`Rs. ${stats.totalRevenue.toLocaleString()}`}
          changeText="Live from Firebase"
          color="emerald"
          onClick={() => navigate('/transactions')}
        />
        <StatCard
          icon={AlertTriangle}
          title="Refund/Cancel Requests"
          value={stats.refunds.toString()}
          changeText="Live from Firebase"
          color="red"
          onClick={() => navigate('/orders')}
        />
      </div>

      {/* Top Products */}
      <div className="bg-[#F6F5F2] rounded-[32px] p-8 shadow-sm w-full">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h2 className="text-[22px] font-bold text-gray-900">Top Products</h2>
            <p className="text-xs text-gray-500 mt-0.5">Live store catalog from WooCommerce</p>
          </div>
          <button 
            onClick={() => navigate('/products')}
            className="text-sm font-bold text-primary-600 hover:text-primary-700 bg-white px-4 py-2 rounded-full shadow-sm hover:shadow transition-all"
          >
            View All Products →
          </button>
        </div>
        
        <div className="space-y-5">
          {products.slice(0, 6).map((product) => (
            <div 
              key={product.id} 
              onClick={() => navigate('/products')}
              className="flex items-center justify-between p-3.5 rounded-2xl bg-white/70 hover:bg-white transition-all shadow-2xs hover:shadow-md cursor-pointer group"
            >
              <div className="flex items-center gap-4">
                <div className="w-14 h-14 rounded-xl bg-gray-100 p-1 overflow-hidden flex-shrink-0 flex items-center justify-center">
                  {product.image ? (
                    <img 
                      src={product.image} 
                      alt={product.name} 
                      className="w-full h-full object-contain group-hover:scale-110 transition-transform" 
                      onError={(e) => { e.target.style.display = 'none'; }}
                    />
                  ) : (
                    <div className="w-full h-full bg-gray-200 flex items-center justify-center text-xs text-gray-500 font-bold">No Img</div>
                  )}
                </div>
                <div>
                  <h3 className="text-[16px] font-bold text-gray-900 group-hover:text-primary-600 transition-colors">{product.name}</h3>
                  <p className="text-[14px] text-gray-500 font-medium mt-0.5">{product.category}</p>
                </div>
              </div>
              <span className="text-[16px] font-extrabold text-gray-900">₨ {parseFloat(product.price || 0).toLocaleString()}</span>
            </div>
          ))}
          {products.length === 0 && <p className="text-gray-500 text-sm">Loading WooCommerce live products...</p>}
        </div>
      </div>

      {/* Recent Orders Table */}
      <div className="bg-white rounded-card shadow-card overflow-hidden">
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <h2 className="text-base font-bold text-text-primary">
            Recent Orders
          </h2>
          <button
            onClick={() => navigate('/orders')}
            className="text-sm text-primary-500 hover:text-primary-600 font-medium"
          >
            View All →
          </button>
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
                  onClick={() => navigate('/orders')}
                  className="hover:bg-surface/50 transition-colors cursor-pointer"
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
                    <button onClick={() => navigate('/orders')} className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors inline-block">
                      <Eye className="w-4 h-4 text-text-secondary" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
      </>
      )}
    </div>
  );
}
