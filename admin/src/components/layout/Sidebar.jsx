import { Link, NavLink, useLocation } from 'react-router-dom';
import {
  LayoutDashboard,
  FileText,
  Package,
  BarChart3,
  ArrowLeftRight,
  Receipt,
  Users,
  Settings,
  HelpCircle,
  LogOut,
  ShoppingCart,
  BookOpen,
  Image
} from 'lucide-react';

const navItems = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/orders', icon: FileText, label: 'Orders' },
  { to: '/products', icon: Package, label: 'Products' },
  { to: '/analytics', icon: BarChart3, label: 'Analytics' },
  { to: '/transactions', icon: ArrowLeftRight, label: 'Transactions' },
  { to: '/ledger', icon: BookOpen, label: 'Ledger' },
  { to: '/invoices', icon: Receipt, label: 'Invoices' },
  { to: '/customers', icon: Users, label: 'Customers' },
  { to: '/banners', icon: Image, label: 'Banners' },
];

const bottomItems = [
  { to: '/settings', icon: Settings, label: 'Settings' },
  { to: '/help', icon: HelpCircle, label: 'Help Center' },
];

export default function Sidebar({ isOpen, onClose, onLogout, pendingOrdersCount = 0 }) {
  const location = useLocation();

  return (
    <>
      {/* Mobile overlay */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black/30 z-40 lg:hidden"
          onClick={onClose}
        />
      )}

      <aside
        className={`fixed top-0 left-0 h-full w-[250px] bg-white border-r border-border z-50 flex flex-col transition-transform duration-300 lg:translate-x-0 ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <Link 
          to="/" 
          onClick={onClose}
          className="flex items-center justify-center px-6 py-6 border-b border-border hover:opacity-80 transition-opacity cursor-pointer"
        >
          <div className="w-full h-10 flex items-center justify-center overflow-hidden">
            <img src="/logo.webp" alt="RestoMart Logo" className="w-full h-full object-contain" />
          </div>
        </Link>

        {/* Main Nav */}
        <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
          {navItems.map((item) => {
            const isActive =
              item.to === '/'
                ? location.pathname === '/'
                : location.pathname.startsWith(item.to);

            return (
              <NavLink
                key={item.to}
                to={item.to}
                onClick={onClose}
                className={`sidebar-link ${
                  isActive ? 'sidebar-link-active' : 'sidebar-link-inactive'
                }`}
              >
                <item.icon className="w-[18px] h-[18px]" />
                <span className="flex-1">{item.label}</span>
                {item.to === '/orders' && pendingOrdersCount > 0 && (
                  <span className="bg-danger text-white text-[10px] font-bold w-5 h-5 rounded-full flex items-center justify-center">
                    {pendingOrdersCount}
                  </span>
                )}
              </NavLink>
            );
          })}
        </nav>

        {/* Bottom Nav */}
        <div className="px-3 py-4 border-t border-border space-y-1">
          {bottomItems.map((item) => {
            const isActive = location.pathname.startsWith(item.to);
            return (
              <NavLink
                key={item.to}
                to={item.to}
                onClick={onClose}
                className={`sidebar-link ${
                  isActive ? 'sidebar-link-active' : 'sidebar-link-inactive'
                }`}
              >
                <item.icon className="w-[18px] h-[18px]" />
                <span>{item.label}</span>
              </NavLink>
            );
          })}
          <button 
            onClick={onLogout}
            className="sidebar-link sidebar-link-inactive w-full text-danger hover:text-danger hover:bg-red-50"
          >
            <LogOut className="w-[18px] h-[18px]" />
            <span>Sign Out</span>
          </button>
        </div>
      </aside>
    </>
  );
}
