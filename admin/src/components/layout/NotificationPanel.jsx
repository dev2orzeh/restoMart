import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Bell, 
  ShoppingBag, 
  AlertTriangle, 
  BookOpen, 
  CheckCheck, 
  Trash2, 
  X, 
  ChevronRight,
  Sparkles
} from 'lucide-react';
import { subscribeToOrders } from '../../services/firebase';

export default function NotificationPanel() {
  const [isOpen, setIsOpen] = useState(false);
  const [notifications, setNotifications] = useState([]);
  const [activeTab, setActiveTab] = useState('all'); // 'all' | 'unread' | 'orders'
  const panelRef = useRef(null);
  const navigate = useNavigate();

  // Persistent read/cleared notification IDs
  const [readIds, setReadIds] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem('restomart_admin_notifs_read') || '[]');
    } catch {
      return [];
    }
  });

  const [clearedIds, setClearedIds] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem('restomart_admin_notifs_cleared') || '[]');
    } catch {
      return [];
    }
  });

  useEffect(() => {
    // Generate live notifications from Firestore orders
    const unsubscribe = subscribeToOrders((orders) => {
      const generatedList = [];

      // Add orders as live notifications
      orders.slice(0, 10).forEach((order, idx) => {
        const notifId = `order-${order.id}`;
        if (clearedIds.includes(notifId)) return;

        const isRead = readIds.includes(notifId);
        generatedList.push({
          id: notifId,
          type: 'order',
          title: `Order #${order.id}`,
          message: `${order.customer || 'Customer'} placed an order worth Rs. ${parseFloat(order.total || 0).toLocaleString()}`,
          time: idx === 0 ? 'Just now' : `${idx * 15 + 2}m ago`,
          read: isRead,
          link: '/orders',
          orderId: order.id,
          amount: order.total,
          status: order.status || 'pending'
        });
      });

      setNotifications(generatedList);
    });

    return () => unsubscribe();
  }, [readIds, clearedIds]);

  // Handle click outside to close dropdown
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (panelRef.current && !panelRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    };
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  const unreadCount = notifications.filter(n => !n.read).length;

  const handleClearAll = () => {
    const allIds = notifications.map(n => n.id);
    const updatedCleared = Array.from(new Set([...clearedIds, ...allIds]));
    setClearedIds(updatedCleared);
    localStorage.setItem('restomart_admin_notifs_cleared', JSON.stringify(updatedCleared));
    setNotifications([]);
  };

  const handleMarkAllRead = () => {
    const allIds = notifications.map(n => n.id);
    const updatedRead = Array.from(new Set([...readIds, ...allIds]));
    setReadIds(updatedRead);
    localStorage.setItem('restomart_admin_notifs_read', JSON.stringify(updatedRead));
    setNotifications(prev => prev.map(n => ({ ...n, read: true })));
  };

  const handleDeleteItem = (e, id) => {
    e.stopPropagation();
    const updatedCleared = Array.from(new Set([...clearedIds, id]));
    setClearedIds(updatedCleared);
    localStorage.setItem('restomart_admin_notifs_cleared', JSON.stringify(updatedCleared));
    setNotifications(prev => prev.filter(n => n.id !== id));
  };

  const handleNotificationClick = (item) => {
    if (!readIds.includes(item.id)) {
      const updatedRead = [...readIds, item.id];
      setReadIds(updatedRead);
      localStorage.setItem('restomart_admin_notifs_read', JSON.stringify(updatedRead));
    }
    setNotifications(prev => prev.map(n => n.id === item.id ? { ...n, read: true } : n));
    setIsOpen(false);
    if (item.link) {
      navigate(item.link);
    }
  };

  const filteredNotifications = notifications.filter(n => {
    if (activeTab === 'unread') return !n.read;
    if (activeTab === 'orders') return n.type === 'order';
    return true;
  });

  return (
    <div className="relative" ref={panelRef}>
      {/* Trigger Bell Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className={`relative p-2.5 rounded-xl transition-all duration-200 ${
          isOpen ? 'bg-primary-50 text-primary-600 ring-2 ring-primary-500/20' : 'hover:bg-gray-100 text-gray-600'
        }`}
        title="Notifications"
      >
        <Bell className="w-5 h-5" />
        {unreadCount > 0 && (
          <span className="absolute top-1.5 right-1.5 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white ring-2 ring-white animate-pulse">
            {unreadCount}
          </span>
        )}
      </button>

      {/* Dropdown Panel */}
      {isOpen && (
        <div className="absolute right-0 mt-3 w-80 sm:w-96 bg-white rounded-3xl shadow-2xl border border-gray-100 overflow-hidden z-50 animate-in fade-in slide-in-from-top-3 duration-200">
          {/* Header */}
          <div className="p-4 px-5 bg-gradient-to-r from-gray-900 to-gray-800 text-white flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Bell className="w-4 h-4 text-primary-400" />
              <h3 className="font-bold text-sm tracking-wide">Notifications</h3>
              {unreadCount > 0 && (
                <span className="bg-primary-500/30 text-primary-200 text-[11px] font-bold px-2 py-0.5 rounded-full border border-primary-400/30">
                  {unreadCount} new
                </span>
              )}
            </div>

            <div className="flex items-center gap-2">
              {notifications.length > 0 && (
                <button
                  onClick={handleClearAll}
                  className="text-xs text-red-300 hover:text-white flex items-center gap-1 font-medium transition-colors px-2 py-1 rounded-lg hover:bg-white/10"
                  title="Clear All Notifications"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                  Clear All
                </button>
              )}
              <button
                onClick={() => setIsOpen(false)}
                className="text-gray-400 hover:text-white p-1 rounded-lg hover:bg-white/10 transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Action Sub-header */}
          <div className="flex items-center justify-between px-4 py-2 bg-gray-50 border-b border-gray-100 text-xs">
            {/* Filter Tabs */}
            <div className="flex items-center gap-1">
              {[
                { id: 'all', label: 'All' },
                { id: 'unread', label: `Unread (${unreadCount})` },
                { id: 'orders', label: 'Orders' },
              ].map(tab => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`px-2.5 py-1 rounded-full font-medium transition-all ${
                    activeTab === tab.id
                      ? 'bg-white text-gray-900 shadow-sm font-bold border border-gray-200'
                      : 'text-gray-500 hover:text-gray-900'
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>

            {unreadCount > 0 && (
              <button
                onClick={handleMarkAllRead}
                className="text-primary-600 hover:text-primary-700 font-bold flex items-center gap-1"
              >
                <CheckCheck className="w-3.5 h-3.5" />
                Read All
              </button>
            )}
          </div>

          {/* Notification List */}
          <div className="max-h-[380px] overflow-y-auto divide-y divide-gray-100">
            {filteredNotifications.map((item) => (
              <div
                key={item.id}
                onClick={() => handleNotificationClick(item)}
                className={`group p-4 flex items-start gap-3 hover:bg-slate-50/80 transition-colors cursor-pointer relative ${
                  !item.read ? 'bg-indigo-50/30' : ''
                }`}
              >
                {/* Icon Bubble */}
                <div className={`w-9 h-9 rounded-2xl flex items-center justify-center flex-shrink-0 mt-0.5 ${
                  item.type === 'order' 
                    ? 'bg-indigo-100 text-indigo-600'
                    : item.type === 'ledger'
                      ? 'bg-emerald-100 text-emerald-600'
                      : 'bg-amber-100 text-amber-600'
                }`}>
                  {item.type === 'order' && <ShoppingBag className="w-4 h-4" />}
                  {item.type === 'ledger' && <BookOpen className="w-4 h-4" />}
                  {item.type === 'alert' && <AlertTriangle className="w-4 h-4" />}
                </div>

                {/* Content */}
                <div className="flex-1 min-w-0 pr-4">
                  <div className="flex items-center justify-between gap-1 mb-0.5">
                    <p className={`text-xs font-bold truncate ${!item.read ? 'text-gray-900 font-extrabold' : 'text-gray-700'}`}>
                      {item.title}
                    </p>
                    <span className="text-[10px] text-gray-400 flex-shrink-0">{item.time}</span>
                  </div>
                  <p className="text-xs text-gray-600 leading-snug line-clamp-2">
                    {item.message}
                  </p>
                </div>

                {/* Unread indicator dot */}
                {!item.read && (
                  <span className="w-2 h-2 rounded-full bg-primary-500 absolute top-4 right-3" />
                )}

                {/* Delete single button on hover */}
                <button
                  onClick={(e) => handleDeleteItem(e, item.id)}
                  className="opacity-0 group-hover:opacity-100 p-1 text-gray-400 hover:text-red-500 rounded-md hover:bg-red-50 transition-all absolute top-3 right-2"
                  title="Remove"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              </div>
            ))}

            {filteredNotifications.length === 0 && (
              <div className="p-8 text-center flex flex-col items-center justify-center">
                <div className="w-12 h-12 bg-emerald-50 text-emerald-500 rounded-full flex items-center justify-center mb-3">
                  <Sparkles className="w-6 h-6" />
                </div>
                <p className="text-sm font-bold text-gray-800">All caught up!</p>
                <p className="text-xs text-gray-500 mt-1">No new notifications in this filter.</p>
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="p-3 bg-gray-50 border-t border-gray-100 text-center">
            <button
              onClick={() => {
                setIsOpen(false);
                navigate('/orders');
              }}
              className="text-xs font-bold text-primary-600 hover:text-primary-700 inline-flex items-center gap-1"
            >
              View All Orders & Activity
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
