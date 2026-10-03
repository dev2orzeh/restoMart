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
  Legend,
} from 'recharts';
import { useState, useEffect } from 'react';
import { getProducts, getOrders } from '../services/woocommerce';
import { mockRevenueData } from '../data/mockData';

const COLORS = ['#4F46E5', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#06B6D4', '#EC4899', '#F97316', '#6366F1'];

export default function Analytics() {
  const [productsData, setProductsData] = useState([]);
  const [revenueData, setRevenueData] = useState(mockRevenueData);

  useEffect(() => {
    const loadData = async () => {
      try {
        const [prods, ords] = await Promise.all([getProducts(), getOrders()]);
        setProductsData(prods);

        // Simple mock revenue generator based on real orders
        if (ords.length > 0) {
          const revMap = {};
          ords.forEach(o => {
            const date = new Date(o.date);
            const month = date.toLocaleString('default', { month: 'short' });
            revMap[month] = (revMap[month] || 0) + o.total;
          });
          const newRev = Object.keys(revMap).map(k => ({ month: k, revenue: revMap[k] }));
          if (newRev.length > 0) {
             setRevenueData(newRev);
          }
        }
      } catch (e) {
        console.error("Failed to fetch analytics data", e);
      }
    };
    loadData();
  }, []);

  // Category distribution
  const categoryData = productsData.reduce((acc, p) => {
    const existing = acc.find((c) => c.name === p.category);
    if (existing) {
      existing.value += 1;
    } else {
      acc.push({ name: p.category, value: 1 });
    }
    return acc;
  }, []);

  // Top products by stock
  const topProducts = [...productsData]
    .sort((a, b) => b.stock - a.stock)
    .slice(0, 5);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-text-primary">Analytics</h1>
        <p className="text-sm text-text-secondary mt-1">
          Business insights and performance metrics
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Revenue Bar Chart */}
        <div className="bg-white rounded-card p-6 shadow-card">
          <h2 className="text-base font-bold text-text-primary mb-1">
            Monthly Revenue
          </h2>
          <p className="text-xs text-text-secondary mb-6">Last 6 months</p>
          <div className="h-[280px]">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={revenueData}>
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
                  formatter={(value) => [
                    `₨ ${value.toLocaleString()}`,
                    'Revenue',
                  ]}
                />
                <Bar
                  dataKey="revenue"
                  fill="#4F46E5"
                  radius={[6, 6, 0, 0]}
                  barSize={40}
                />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Category Pie Chart */}
        <div className="bg-white rounded-card p-6 shadow-card">
          <h2 className="text-base font-bold text-text-primary mb-1">
            Products by Category
          </h2>
          <p className="text-xs text-text-secondary mb-6">
            Distribution of inventory
          </p>
          <div className="h-[280px]">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={categoryData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={4}
                  dataKey="value"
                >
                  {categoryData.map((entry, index) => (
                    <Cell
                      key={entry.name}
                      fill={COLORS[index % COLORS.length]}
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
                <Legend
                  iconType="circle"
                  iconSize={8}
                  wrapperStyle={{ fontSize: '12px' }}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Top Products */}
      <div className="bg-white rounded-card shadow-card overflow-hidden">
        <div className="px-6 py-4 border-b border-border">
          <h2 className="text-base font-bold text-text-primary">
            Top Stocked Products
          </h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="bg-surface">
                <th className="table-header text-left py-3 px-4">#</th>
                <th className="table-header text-left py-3 px-4">Product</th>
                <th className="table-header text-left py-3 px-4">Category</th>
                <th className="table-header text-center py-3 px-4">Stock</th>
                <th className="table-header text-right py-3 px-4">Price</th>
              </tr>
            </thead>
            <tbody>
              {topProducts.map((p, i) => (
                <tr key={p.id} className="hover:bg-surface/50 transition-colors">
                  <td className="table-cell font-bold text-text-muted">
                    {i + 1}
                  </td>
                  <td className="table-cell font-semibold text-text-primary">
                    {p.name}
                  </td>
                  <td className="table-cell text-text-secondary">
                    {p.category}
                  </td>
                  <td className="table-cell text-center font-medium">
                    {p.stock}
                  </td>
                  <td className="table-cell text-right font-semibold">
                    ₨ {p.price.toLocaleString()}
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
