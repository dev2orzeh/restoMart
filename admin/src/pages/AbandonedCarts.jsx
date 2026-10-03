import React from 'react';
import { Clock, RefreshCcw, ShoppingCart, ArrowRight } from 'lucide-react';

const mockAbandonedCarts = [
  {
    id: '#AC-001',
    customer: 'Fraz Liaqat',
    email: 'fraz@example.com',
    phone: '923258019294',
    products: 'Cooking Oil (x2), Cheese (x1)',
    total: 'Rs. 4,500.00',
    createdAt: '2026-09-29 10:30 AM',
    lastActivity: '2026-09-29 10:45 AM',
    status: 'Abandoned',
    lastReminder: '1 hour ago',
    reminderCount: 1,
  },
  {
    id: '#AC-002',
    customer: 'John Doe',
    email: 'john@example.com',
    phone: '923000000000',
    products: 'Flour 10kg (x1)',
    total: 'Rs. 1,200.00',
    createdAt: '2026-09-28 02:15 PM',
    lastActivity: '2026-09-28 02:20 PM',
    status: 'Recovered',
    lastReminder: '1 day ago',
    reminderCount: 2,
  },
  {
    id: '#AC-003',
    customer: 'Ali Khan',
    email: 'ali@example.com',
    phone: '923111111111',
    products: 'Milk 1L (x5), Bread (x2)',
    total: 'Rs. 1,650.00',
    createdAt: '2026-09-29 11:00 AM',
    lastActivity: '2026-09-29 11:05 AM',
    status: 'Active',
    lastReminder: 'None',
    reminderCount: 0,
  }
];

export default function AbandonedCarts() {
  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text-primary">Abandoned Carts</h1>
          <p className="text-sm text-text-secondary mt-1">
            Track and recover lost sales with automated reminders
          </p>
        </div>
        <button
          onClick={() => alert('Opening reminder settings...')}
          className="flex items-center px-4 py-2 bg-white border border-border text-text-primary rounded-lg hover:bg-surface transition-colors"
        >
          <RefreshCcw className="w-4 h-4 mr-2" />
          Settings
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-5 mb-6">
        <div className="bg-white rounded-card p-6 shadow-card flex items-center justify-between">
          <div>
            <p className="text-sm text-text-secondary mb-1">Total Abandoned</p>
            <h3 className="text-2xl font-bold">124</h3>
          </div>
          <div className="w-12 h-12 bg-red-100 text-red-500 rounded-full flex items-center justify-center">
            <ShoppingCart className="w-6 h-6" />
          </div>
        </div>
        <div className="bg-white rounded-card p-6 shadow-card flex items-center justify-between">
          <div>
            <p className="text-sm text-text-secondary mb-1">Recovered Sales</p>
            <h3 className="text-2xl font-bold">Rs. 45,200</h3>
          </div>
          <div className="w-12 h-12 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center">
            <ArrowRight className="w-6 h-6" />
          </div>
        </div>
        <div className="bg-white rounded-card p-6 shadow-card flex items-center justify-between">
          <div>
            <p className="text-sm text-text-secondary mb-1">Recovery Rate</p>
            <h3 className="text-2xl font-bold">18.5%</h3>
          </div>
          <div className="w-12 h-12 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center">
            <Clock className="w-6 h-6" />
          </div>
        </div>
      </div>

      <div className="bg-white rounded-card shadow-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="bg-surface">
                <th className="table-header text-left py-3 px-4">Cart ID</th>
                <th className="table-header text-left py-3 px-4">Customer</th>
                <th className="table-header text-left py-3 px-4">Products</th>
                <th className="table-header text-left py-3 px-4">Total</th>
                <th className="table-header text-left py-3 px-4">Status</th>
                <th className="table-header text-left py-3 px-4">Reminders</th>
                <th className="table-header text-left py-3 px-4">Last Activity</th>
              </tr>
            </thead>
            <tbody>
              {mockAbandonedCarts.map((cart, idx) => (
                <tr key={idx} className="hover:bg-surface/50 transition-colors border-b border-border last:border-0">
                  <td className="table-cell font-semibold text-primary-500 py-3 px-4">{cart.id}</td>
                  <td className="table-cell py-3 px-4">
                    <p className="font-medium text-text-primary">{cart.customer}</p>
                    <p className="text-xs text-text-muted">{cart.email}</p>
                    <p className="text-xs text-text-muted">{cart.phone}</p>
                  </td>
                  <td className="table-cell py-3 px-4 text-sm max-w-[200px] truncate">{cart.products}</td>
                  <td className="table-cell py-3 px-4 font-semibold">{cart.total}</td>
                  <td className="table-cell py-3 px-4">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-medium
                      ${cart.status === 'Recovered' ? 'bg-emerald-100 text-emerald-700' : 
                        cart.status === 'Abandoned' ? 'bg-red-100 text-red-700' : 
                        'bg-blue-100 text-blue-700'}`}>
                      {cart.status}
                    </span>
                  </td>
                  <td className="table-cell py-3 px-4">
                    <p className="text-sm">{cart.reminderCount} sent</p>
                    <p className="text-xs text-text-muted">{cart.lastReminder}</p>
                  </td>
                  <td className="table-cell py-3 px-4 text-sm text-text-secondary">{cart.lastActivity}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
