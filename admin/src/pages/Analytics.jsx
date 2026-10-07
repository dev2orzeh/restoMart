import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';
import { useState, useEffect, useMemo } from 'react';
import { getProducts } from '../services/woocommerce';
import { subscribeToOrders, subscribeToLedgerAccounts, subscribeToAllTransactions } from '../services/firebase';
import { DollarSign, ShoppingBag, Users, Wallet, TrendingUp, Package } from 'lucide-react';
import Loader from '../components/shared/Loader';

const CHART_COLORS = ['#25258F', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#06B6D4', '#6366F1'];

export default function Analytics() {
  const [productsData, setProductsData] = useState([]);
  const [ordersData, setOrdersData] = useState([]);
  const [ledgerAccounts, setLedgerAccounts] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isProductsLoading, setIsProductsLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;

    // Load WooCommerce Products
    getProducts()
      .then((prods) => {
        if (isMounted && prods.length > 0) {
          setProductsData(prods);
        }
      })
      .catch((err) => console.error("Products analytics fetch error", err))
      .finally(() => {
        if (isMounted) setIsProductsLoading(false);
      });

    // Subscribe to Firebase Live Orders
    const unsubOrders = subscribeToOrders((ords) => {
      if (isMounted) {
        setOrdersData(ords);
        setLoading(false);
      }
    });

    // Subscribe to Firebase Ledger Accounts
    const unsubLedger = subscribeToLedgerAccounts((accs) => {
      if (isMounted) {
        setLedgerAccounts(accs);
      }
    });

    // Subscribe to Firebase Transactions
    const unsubTxns = subscribeToAllTransactions((txs) => {
      if (isMounted) {
        setTransactions(txs);
      }
    });

    return () => {
      isMounted = false;
      unsubOrders();
      unsubLedger();
      unsubTxns();
    };
  }, []);

  // ── Key Metrics Calculations ──
  const totalRevenue = useMemo(() => {
    return ordersData
      .filter(o => o.status !== 'cancelled')
      .reduce((sum, o) => sum + (parseFloat(o.total) || 0), 0);
  }, [ordersData]);

  const totalOutstandingBalance = useMemo(() => {
    return ledgerAccounts.reduce((sum, a) => sum + (parseFloat(a.balance) || 0), 0);
  }, [ledgerAccounts]);

  // ── Clean Grouped Category Analytics (Top 5 + Others) ──
  const categoryData = useMemo(() => {
    if (!productsData || productsData.length === 0) return [];
    
    const countMap = {};
    productsData.forEach((p) => {
      const cat = p.category || 'General';
      countMap[cat] = (countMap[cat] || 0) + 1;
    });

    const sorted = Object.keys(countMap)
      .map(k => ({ name: k, value: countMap[k] }))
      .sort((a, b) => b.value - a.value);

    if (sorted.length <= 5) return sorted;

    const top5 = sorted.slice(0, 5);
    const othersCount = sorted.slice(5).reduce((sum, c) => sum + c.value, 0);
    return [...top5, { name: 'Others', value: othersCount }];
  }, [productsData]);

  // ── Monthly Revenue Chart Data ──
  const monthlyRevenueData = useMemo(() => {
    const revMap = {};
    ordersData.forEach(o => {
      if (o.status === 'cancelled') return;
      const d = o.date ? new Date(o.date) : new Date();
      const month = d.toLocaleString('default', { month: 'short' });
      revMap[month] = (revMap[month] || 0) + (parseFloat(o.total) || 0);
    });

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const currentMonthIdx = new Date().getMonth();
    const last6Months = [];

    for (let i = 5; i >= 0; i--) {
      const idx = (currentMonthIdx - i + 12) % 12;
      const m = months[idx];
      last6Months.push({
        month: m,
        revenue: revMap[m] || 0,
      });
    }

    return last6Months;
  }, [ordersData]);

  // Top Stocked Products
  const topStockedProducts = useMemo(() => {
    return [...productsData]
      .sort((a, b) => (b.stock || 0) - (a.stock || 0))
      .slice(0, 5);
  }, [productsData]);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-text-primary">Analytics & Insights</h1>
        <p className="text-sm text-text-secondary mt-1">
          Real-time performance metrics, category breakdown, and revenue statistics
        </p>
      </div>

      {/* ── Key Performance Metrics ── */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white rounded-card p-5 shadow-card border border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold text-text-muted uppercase tracking-wider">Total Sales</p>
              <h3 className="text-2xl font-bold text-primary-500 mt-1">₨ {totalRevenue.toLocaleString()}</h3>
            </div>
            <div className="w-11 h-11 rounded-xl bg-primary-50 text-primary-600 flex items-center justify-center">
              <DollarSign className="w-6 h-6" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-card p-5 shadow-card border border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold text-text-muted uppercase tracking-wider">Total Orders</p>
              <h3 className="text-2xl font-bold text-emerald-600 mt-1">{ordersData.length}</h3>
            </div>
            <div className="w-11 h-11 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <ShoppingBag className="w-6 h-6" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-card p-5 shadow-card border border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold text-text-muted uppercase tracking-wider">Active Customers</p>
              <h3 className="text-2xl font-bold text-amber-600 mt-1">{ledgerAccounts.length}</h3>
            </div>
            <div className="w-11 h-11 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
              <Users className="w-6 h-6" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-card p-5 shadow-card border border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold text-text-muted uppercase tracking-wider">Khata Outstanding</p>
              <h3 className="text-2xl font-bold text-rose-600 mt-1">₨ {totalOutstandingBalance.toLocaleString()}</h3>
            </div>
            <div className="w-11 h-11 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center">
              <Wallet className="w-6 h-6" />
            </div>
          </div>
        </div>
      </div>

      {loading ? (
        <Loader message="Loading analytics insights..." />
      ) : (
        <>
          {/* Charts Row */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Revenue Trend Bar Chart */}
            <div className="bg-white rounded-card p-6 shadow-card border border-border">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <h2 className="text-base font-bold text-text-primary">Monthly Revenue Trend</h2>
                  <p className="text-xs text-text-secondary">Sales performance across recent months</p>
                </div>
                <TrendingUp className="w-5 h-5 text-primary-500" />
              </div>

              <div className="h-[280px]">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={monthlyRevenueData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#F0F0F0" />
                    <XAxis
                      dataKey="month"
                      axisLine={false}
                      tickLine={false}
                      tick={{ fontSize: 12, fill: '#6B7280' }}
                    />
                    <YAxis
                      axisLine={false}
                      tickLine={false}
                      tick={{ fontSize: 12, fill: '#6B7280' }}
                      tickFormatter={(v) => `₨${(v / 1000).toFixed(0)}K`}
                    />
                    <Tooltip
                      contentStyle={{
                        background: '#1A1A2E',
                        border: 'none',
                        borderRadius: '8px',
                        color: '#fff',
                        fontSize: '13px',
                      }}
                      formatter={(value) => [`₨ ${value.toLocaleString()}`, 'Revenue']}
                    />
                    <Bar
                      dataKey="revenue"
                      fill="#25258F"
                      radius={[6, 6, 0, 0]}
                      barSize={36}
                    />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* Clean Unclustered Category Breakdown Chart */}
            <div className="bg-white rounded-card p-6 shadow-card border border-border flex flex-col justify-between">
              <div>
                <h2 className="text-base font-bold text-text-primary">Inventory Category Breakdown</h2>
                <p className="text-xs text-text-secondary mb-4">Product distribution by top categories</p>
              </div>

              {isProductsLoading ? (
                <Loader compact message="Fetching category distribution..." />
              ) : categoryData.length === 0 ? (
                <div className="flex items-center justify-center p-8 text-xs text-text-muted">
                  No inventory category data available
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 items-center">
                  <div className="h-[220px]">
                    <ResponsiveContainer width="100%" height="100%">
                      <PieChart>
                        <Pie
                          data={categoryData}
                          cx="50%"
                          cy="50%"
                          innerRadius={55}
                          outerRadius={85}
                          paddingAngle={4}
                          dataKey="value"
                        >
                          {categoryData.map((entry, index) => (
                            <Cell
                              key={entry.name}
                              fill={CHART_COLORS[index % CHART_COLORS.length]}
                            />
                          ))}
                        </Pie>
                        <Tooltip
                          contentStyle={{
                            background: '#1A1A2E',
                            border: 'none',
                            borderRadius: '8px',
                            color: '#fff',
                            fontSize: '13px',
                          }}
                        />
                      </PieChart>
                    </ResponsiveContainer>
                  </div>

                  {/* Clean Custom Side Legend */}
                  <div className="space-y-2.5">
                    {categoryData.map((cat, idx) => {
                      const totalProds = productsData.length || 1;
                      const pct = Math.round((cat.value / totalProds) * 100);
                      return (
                        <div key={cat.name} className="flex items-center justify-between text-xs">
                          <div className="flex items-center gap-2 truncate">
                            <span
                              className="w-3 h-3 rounded-full shrink-0"
                              style={{ backgroundColor: CHART_COLORS[idx % CHART_COLORS.length] }}
                            />
                            <span className="font-semibold text-text-primary truncate">{cat.name}</span>
                          </div>
                          <span className="font-bold text-text-secondary ml-2">{cat.value} items ({pct}%)</span>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Top Stocked Products Table */}
          <div className="bg-white rounded-card shadow-card overflow-hidden border border-border">
            <div className="px-6 py-4 border-b border-border flex items-center justify-between">
              <div>
                <h2 className="text-base font-bold text-text-primary">Top Stocked Inventory</h2>
                <p className="text-xs text-text-secondary">Products with the highest inventory availability</p>
              </div>
              <Package className="w-5 h-5 text-primary-500" />
            </div>

            {isProductsLoading ? (
              <Loader compact message="Fetching top stocked inventory..." />
            ) : topStockedProducts.length === 0 ? (
              <div className="p-8 text-center text-xs text-text-muted">No stock data available</div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="bg-surface">
                      <th className="table-header text-left py-3 px-4">#</th>
                      <th className="table-header text-left py-3 px-4">Product Name</th>
                      <th className="table-header text-left py-3 px-4">Category</th>
                      <th className="table-header text-center py-3 px-4">In Stock</th>
                      <th className="table-header text-right py-3 px-4">Unit Price</th>
                    </tr>
                  </thead>
                  <tbody>
                    {topStockedProducts.map((p, i) => (
                      <tr key={p.id} className="hover:bg-surface/50 transition-colors">
                        <td className="table-cell font-bold text-text-muted">{i + 1}</td>
                        <td className="table-cell font-semibold text-text-primary">{p.name}</td>
                        <td className="table-cell">
                          <span className="badge bg-indigo-50 text-indigo-700 font-medium">
                            {p.category || 'General'}
                          </span>
                        </td>
                        <td className="table-cell text-center font-bold text-emerald-600">{p.stock || 0} units</td>
                        <td className="table-cell text-right font-semibold">₨ {(p.price || 0).toLocaleString()}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}
