import { useState, useEffect } from 'react';
import { Search, Eye } from 'lucide-react';
import { mockCustomers } from '../data/mockData';
import { getCustomers } from '../services/woocommerce';

export default function Customers() {
  const [searchQuery, setSearchQuery] = useState('');
  const [customersData, setCustomersData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchWooCustomers = async () => {
      try {
        const liveCustomers = await getCustomers();
        if (liveCustomers.length === 0) {
          setCustomersData(mockCustomers);
        } else {
          setCustomersData(liveCustomers);
        }
      } catch (e) {
        console.error("Failed to fetch customers", e);
        setCustomersData(mockCustomers);
      } finally {
        setLoading(false);
      }
    };
    
    fetchWooCustomers();
  }, []);

  const filtered = searchQuery
    ? customersData.filter(
        (c) =>
          c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          c.email.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : customersData;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-text-primary">Customers</h1>
        <p className="text-sm text-text-secondary mt-1">
          Your restaurant and business clients
        </p>
      </div>

      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
        <input
          type="text"
          placeholder="Search customers..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="input-field w-full pl-10"
        />
      </div>

      <div className="bg-white rounded-card shadow-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="bg-surface">
                <th className="table-header text-left py-3 px-4">Customer</th>
                <th className="table-header text-left py-3 px-4">Phone</th>
                <th className="table-header text-center py-3 px-4">Total Orders</th>
                <th className="table-header text-right py-3 px-4">Total Spent</th>
                <th className="table-header text-left py-3 px-4">Last Order</th>
                <th className="table-header text-center py-3 px-4">Action</th>
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
                      <div className="w-9 h-9 rounded-full bg-gradient-to-br from-primary-100 to-primary-200 flex items-center justify-center text-primary-600 text-sm font-bold flex-shrink-0">
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
                  <td className="table-cell text-text-secondary">
                    {customer.phone}
                  </td>
                  <td className="table-cell text-center font-semibold">
                    {customer.totalOrders}
                  </td>
                  <td className="table-cell text-right font-semibold">
                    ₨ {customer.totalSpent.toLocaleString()}
                  </td>
                  <td className="table-cell text-text-secondary">
                    {customer.lastOrder}
                  </td>
                  <td className="table-cell text-center">
                    <button className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors opacity-0 group-hover:opacity-100">
                      <Eye className="w-4 h-4 text-text-secondary" />
                    </button>
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
