import { useState } from 'react';
import { User, Store, Bell, Wifi, CheckCircle2 } from 'lucide-react';

export default function Settings() {
  const [toastMessage, setToastMessage] = useState('');

  const showToast = (msg) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(''), 3000);
  };

  const handleSave = (e, msg) => {
    e.preventDefault();
    showToast(msg);
  };

  return (
    <div className="space-y-6 relative">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-6 right-6 bg-gray-900 text-white px-4 py-3 rounded-xl shadow-2xl flex items-center gap-3 animate-in slide-in-from-bottom-5 z-50">
          <CheckCircle2 className="w-5 h-5 text-emerald-400" />
          <p className="font-medium text-sm">{toastMessage}</p>
        </div>
      )}

      <div>
        <h1 className="text-2xl font-bold text-text-primary">Settings</h1>
        <p className="text-sm text-text-secondary mt-1">
          Manage your admin profile and store settings
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Admin Profile */}
        <form onSubmit={(e) => handleSave(e, 'Admin profile updated successfully')} className="bg-white rounded-card p-6 shadow-card">
          <div className="flex items-center gap-3 mb-6">
            <User className="w-5 h-5 text-primary-500" />
            <h2 className="text-base font-bold text-text-primary">
              Admin Profile
            </h2>
          </div>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-text-secondary mb-1.5">
                Full Name
              </label>
              <input
                type="text"
                defaultValue="RestoMart Admin"
                className="input-field w-full"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-text-secondary mb-1.5">
                Email
              </label>
              <input
                type="email"
                defaultValue="admin@restomart.pk"
                className="input-field w-full"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-text-secondary mb-1.5">
                Phone
              </label>
              <input
                type="text"
                defaultValue="+92 325 8019294"
                className="input-field w-full"
              />
            </div>
            <button type="submit" className="btn-primary mt-2">Save Changes</button>
          </div>
        </form>

        {/* Store Info */}
        <form onSubmit={(e) => handleSave(e, 'Store information updated successfully')} className="bg-white rounded-card p-6 shadow-card">
          <div className="flex items-center gap-3 mb-6">
            <Store className="w-5 h-5 text-primary-500" />
            <h2 className="text-base font-bold text-text-primary">
              Store Information
            </h2>
          </div>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-text-secondary mb-1.5">
                Store Name
              </label>
              <input
                type="text"
                defaultValue="RestoMart"
                className="input-field w-full"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-text-secondary mb-1.5">
                Address
              </label>
              <input
                type="text"
                defaultValue="Lahore, Pakistan"
                className="input-field w-full"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-text-secondary mb-1.5">
                Website
              </label>
              <input
                type="text"
                defaultValue="https://restomart.pk"
                className="input-field w-full text-gray-500 bg-gray-50 cursor-not-allowed"
                disabled
              />
            </div>
            <button type="submit" className="btn-primary mt-2">Update Store</button>
          </div>
        </form>

        {/* Notifications */}
        <div className="bg-white rounded-card p-6 shadow-card">
          <div className="flex items-center gap-3 mb-6">
            <Bell className="w-5 h-5 text-primary-500" />
            <h2 className="text-base font-bold text-text-primary">
              Notifications
            </h2>
          </div>
          <div className="space-y-4">
            {[
              { label: 'New Order Alerts', desc: 'Get notified when a new order comes in' },
              { label: 'Low Stock Alerts', desc: 'Alert when product stock goes below 10' },
              { label: 'Daily Summary', desc: 'Receive a daily email with sales overview' },
            ].map((item) => (
              <div
                key={item.label}
                className="flex items-center justify-between py-2"
              >
                <div>
                  <p className="text-sm font-medium text-text-primary">
                    {item.label}
                  </p>
                  <p className="text-xs text-text-muted">{item.desc}</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input type="checkbox" defaultChecked onChange={() => showToast('Notification settings updated')} className="sr-only peer" />
                  <div className="w-10 h-5 bg-gray-200 rounded-full peer peer-checked:bg-primary-500 after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:after:translate-x-5" />
                </label>
              </div>
            ))}
          </div>
        </div>

        {/* API Connection */}
        <form onSubmit={(e) => handleSave(e, 'Checking API keys... Could not connect to WordPress.')} className="bg-white rounded-card p-6 shadow-card">
          <div className="flex items-center gap-3 mb-6">
            <Wifi className="w-5 h-5 text-primary-500" />
            <h2 className="text-base font-bold text-text-primary">
              API Connection
            </h2>
          </div>
          <div className="space-y-4">
            <div className="flex items-center gap-3 p-3 bg-amber-50 rounded-lg border border-amber-200">
              <div className="w-2.5 h-2.5 bg-amber-400 rounded-full animate-pulse" />
              <div>
                <p className="text-sm font-medium text-amber-800">
                  Not Connected
                </p>
                <p className="text-xs text-amber-600">
                  Waiting for WooCommerce API keys
                </p>
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-text-secondary mb-1.5">
                Consumer Key
              </label>
              <input
                type="text"
                placeholder="ck_..."
                className="input-field w-full"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-text-secondary mb-1.5">
                Consumer Secret
              </label>
              <input
                type="password"
                placeholder="cs_..."
                className="input-field w-full"
                required
              />
            </div>
            <button type="submit" className="btn-primary mt-2">Connect API</button>
          </div>
        </form>
      </div>
    </div>
  );
}
