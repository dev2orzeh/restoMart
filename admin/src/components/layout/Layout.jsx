import { useState, useEffect, useRef } from 'react';
import { Outlet } from 'react-router-dom';
import { Toaster, toast } from 'react-hot-toast';
import { subscribeToOrders } from '../../services/firebase';
import Sidebar from './Sidebar';
import TopBar from './TopBar';

export default function Layout({ onLogout }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [pendingCount, setPendingCount] = useState(0);
  
  const isFirstLoad = useRef(true);
  const knownOrderIds = useRef(new Set());

  useEffect(() => {
    const unsubscribe = subscribeToOrders((orders) => {
      const pendingOrders = orders.filter(o => o.status === 'pending');
      setPendingCount(pendingOrders.length);
      
      if (isFirstLoad.current) {
        isFirstLoad.current = false;
        pendingOrders.forEach(o => knownOrderIds.current.add(o.id));
      } else {
        pendingOrders.forEach(o => {
          if (!knownOrderIds.current.has(o.id)) {
            toast.success(`New order received!`, {
              duration: 5000,
              icon: '🔔',
              style: {
                borderRadius: '10px',
                background: '#333',
                color: '#fff',
              },
            });
            
            // Also trigger native browser notification if allowed
            if (Notification.permission === 'granted') {
              new Notification('New Order Received!', {
                body: `You have a new pending order.`,
              });
            }
            
            knownOrderIds.current.add(o.id);
          }
        });
      }
    });

    // Request notification permission on load
    if (Notification.permission === 'default') {
      Notification.requestPermission();
    }

    return () => unsubscribe();
  }, []);

  return (
    <div className="min-h-screen bg-surface">
      <Toaster position="top-right" />
      <Sidebar 
        isOpen={sidebarOpen} 
        onClose={() => setSidebarOpen(false)} 
        onLogout={onLogout} 
        pendingOrdersCount={pendingCount}
      />

      {/* Main content area (offset by sidebar width on desktop) */}
      <div className="lg:ml-[250px] min-h-screen flex flex-col">
        <TopBar onMenuClick={() => setSidebarOpen(true)} />

        <main className="flex-1 p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
