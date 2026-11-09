import { useState } from 'react';
import { User, Store, Bell, Wifi, CheckCircle2, ShieldCheck } from 'lucide-react';

export default function Settings() {
  const [activeTab, setActiveTab] = useState('Profile');
  const [toastMessage, setToastMessage] = useState('');

  const showToast = (msg) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(''), 3000);
  };

  const handleSave = (e, msg) => {
    e.preventDefault();
    showToast(msg);
  };

  const tabs = ['Profile', 'Store Info', 'Notifications', 'API Connection'];

  return (
    <div className="space-y-6 max-w-5xl mx-auto pb-12 animate-in fade-in duration-500">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-6 right-6 bg-slate-900 text-white px-4 py-3 rounded-xl shadow-2xl flex items-center gap-3 animate-in slide-in-from-bottom-5 z-50">
          <CheckCircle2 className="w-5 h-5 text-emerald-400" />
          <p className="font-medium text-xs">{toastMessage}</p>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border pb-4">
        <div>
          <h1 className="text-2xl font-bold text-text-primary">Settings</h1>
          <p className="text-xs text-text-secondary mt-1">
            Manage your admin profile, store details, and API configuration
          </p>
        </div>
      </div>

      {/* Minimal Sub-Navigation Tabs */}
      <div className="flex items-center gap-6 overflow-x-auto border-b border-border scrollbar-none text-sm">
        {tabs.map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`pb-3 font-semibold whitespace-nowrap transition-colors relative ${
              activeTab === tab
                ? 'text-primary-600 border-b-2 border-primary-500'
                : 'text-text-secondary hover:text-text-primary'
            }`}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* TAB CONTENT: PROFILE */}
      {activeTab === 'Profile' && (
        <form onSubmit={(e) => handleSave(e, 'Admin profile updated successfully')} className="bg-white rounded-2xl p-6 border border-border space-y-6 shadow-sm">
          <div className="flex items-center gap-3 pb-4 border-b border-border">
            <div className="w-9 h-9 rounded-xl bg-primary-50 flex items-center justify-center text-primary-600">
              <User className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-sm font-bold text-text-primary">Admin Profile</h2>
              <p className="text-xs text-text-secondary">Update your admin account details and password</p>
            </div>
          </div>

          <div className="space-y-4 max-w-lg">
            <div>
              <label className="block text-xs font-semibold text-text-secondary mb-1.5">Full Name</label>
              <input
                type="text"
                defaultValue="RestoMart Admin"
                className="w-full px-4 py-2.5 bg-slate-50 border border-border rounded-xl text-xs font-medium text-text-primary focus:outline-none focus:ring-2 focus:ring-primary-500"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-text-secondary mb-1.5">Email Address</label>
              <input
                type="email"
                defaultValue="admin@restomart.pk"
                className="w-full px-4 py-2.5 bg-slate-50 border border-border rounded-xl text-xs font-medium text-text-primary focus:outline-none focus:ring-2 focus:ring-primary-500"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-text-secondary mb-1.5">Phone Number</label>
              <input
                type="text"
                defaultValue="0321-1655556 / 0321-0655555"
                className="w-full px-4 py-2.5 bg-slate-50 border border-border rounded-xl text-xs font-medium text-text-primary focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
            </div>
            <button type="submit" className="px-5 py-2.5 bg-primary-500 hover:bg-primary-600 text-white rounded-xl text-xs font-bold transition-all shadow-sm">
              Save Changes
            </button>
          </div>
        </form>
      )}

      {/* TAB CONTENT: STORE INFO */}
      {activeTab === 'Store Info' && (
        <form onSubmit={(e) => handleSave(e, 'Store information updated successfully')} className="bg-white rounded-2xl p-6 border border-border space-y-6 shadow-sm">
          <div className="flex items-center gap-3 pb-4 border-b border-border">
            <div className="w-9 h-9 rounded-xl bg-primary-50 flex items-center justify-center text-primary-600">
              <Store className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-sm font-bold text-text-primary">Store Information</h2>
              <p className="text-xs text-text-secondary">Configure your main store details</p>
            </div>
          </div>

          <div className="space-y-4 max-w-lg">
            <div>
              <label className="block text-xs font-semibold text-text-secondary mb-1.5">Store Name</label>
              <input
                type="text"
                defaultValue="RestoMart"
                className="w-full px-4 py-2.5 bg-slate-50 border border-border rounded-xl text-xs font-medium text-text-primary focus:outline-none focus:ring-2 focus:ring-primary-500"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-text-secondary mb-1.5">Store Address</label>
              <input
                type="text"
                defaultValue="Lahore, Pakistan"
                className="w-full px-4 py-2.5 bg-slate-50 border border-border rounded-xl text-xs font-medium text-text-primary focus:outline-none focus:ring-2 focus:ring-primary-500"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-text-secondary mb-1.5">Storefront Website</label>
              <input
                type="text"
                defaultValue="https://restomart.pk"
                className="w-full px-4 py-2.5 bg-slate-100 border border-border rounded-xl text-xs font-medium text-slate-500 cursor-not-allowed"
                disabled
              />
            </div>
            <button type="submit" className="px-5 py-2.5 bg-primary-500 hover:bg-primary-600 text-white rounded-xl text-xs font-bold transition-all shadow-sm">
              Update Store
            </button>
          </div>
        </form>
      )}

      {/* TAB CONTENT: NOTIFICATIONS */}
      {activeTab === 'Notifications' && (
        <div className="bg-white rounded-2xl p-6 border border-border space-y-6 shadow-sm">
          <div className="flex items-center gap-3 pb-4 border-b border-border">
            <div className="w-9 h-9 rounded-xl bg-primary-50 flex items-center justify-center text-primary-600">
              <Bell className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-sm font-bold text-text-primary">Notifications</h2>
              <p className="text-xs text-text-secondary">Manage order and stock alerts</p>
            </div>
          </div>

          <div className="space-y-4 max-w-xl">
            {[
              { label: 'New Order Alerts', desc: 'Get real-time audio and push alerts when a new order arrives' },
              { label: 'Low Stock Alerts', desc: 'Alert when product stock drops below 10 items' },
              { label: 'Daily Summary Email', desc: 'Receive a daily email overview of store sales' },
            ].map((item) => (
              <div key={item.label} className="flex items-center justify-between py-3 border-b border-border/60">
                <div>
                  <p className="text-xs font-bold text-text-primary">{item.label}</p>
                  <p className="text-[11px] text-text-secondary mt-0.5">{item.desc}</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    defaultChecked
                    onChange={() => showToast('Notification settings updated')}
                    className="sr-only peer"
                  />
                  <div className="w-9 h-5 bg-slate-200 rounded-full peer peer-checked:bg-primary-500 after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:after:translate-x-4" />
                </label>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* TAB CONTENT: API CONNECTION */}
      {activeTab === 'API Connection' && (
        <form onSubmit={(e) => handleSave(e, 'WooCommerce API settings updated')} className="bg-white rounded-2xl p-6 border border-border space-y-6 shadow-sm">
          <div className="flex items-center gap-3 pb-4 border-b border-border">
            <div className="w-9 h-9 rounded-xl bg-emerald-50 flex items-center justify-center text-emerald-600">
              <Wifi className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-sm font-bold text-text-primary">WooCommerce API Connection</h2>
              <p className="text-xs text-text-secondary">Manage WordPress REST API keys</p>
            </div>
          </div>

          <div className="space-y-4 max-w-xl">
            <div className="flex items-center gap-3 p-3 bg-emerald-50 rounded-xl border border-emerald-100 text-xs">
              <div className="w-2.5 h-2.5 bg-emerald-500 rounded-full animate-pulse" />
              <div>
                <p className="font-bold text-emerald-900">Connected & Active</p>
                <p className="text-emerald-700 text-[11px]">Linked to WordPress Storefront (restomart.pk)</p>
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-text-secondary mb-1.5">Consumer Key</label>
              <input
                type="text"
                defaultValue="ck_823aab9b5cab2eba66e6751f4f5c6502fe306566"
                className="w-full px-4 py-2.5 bg-slate-50 border border-border rounded-xl font-mono text-xs text-slate-700"
                readOnly
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-text-secondary mb-1.5">Consumer Secret</label>
              <input
                type="password"
                defaultValue="cs_00ed3a9685b5697cb50e61b70a004f4f36e2b99f"
                className="w-full px-4 py-2.5 bg-slate-50 border border-border rounded-xl font-mono text-xs text-slate-700"
                readOnly
              />
            </div>
            <button type="submit" className="px-5 py-2.5 bg-primary-500 hover:bg-primary-600 text-white rounded-xl text-xs font-bold transition-all shadow-sm">
              Save API Config
            </button>
          </div>
        </form>
      )}
    </div>
  );
}
