import { useState, useEffect, useRef } from 'react';
import { Search, Settings, Menu, X } from 'lucide-react';
import { useNavigate, useLocation, useSearchParams } from 'react-router-dom';
import NotificationPanel from './NotificationPanel';

export default function TopBar({ onMenuClick }) {
  const navigate = useNavigate();
  const location = useLocation();
  const [searchParams] = useSearchParams();
  const inputRef = useRef(null);

  const [query, setQuery] = useState(() => searchParams.get('q') || '');

  // Keep search input synced with URL when navigation occurs
  useEffect(() => {
    const currentQ = searchParams.get('q') || '';
    setQuery(currentQ);
  }, [searchParams, location.pathname]);

  // Global Cmd+K / Ctrl+K keyboard shortcut to focus search
  useEffect(() => {
    const handleKeyDown = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        inputRef.current?.focus();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  const handleSearchSubmit = (e) => {
    if (e) e.preventDefault();
    const trimmed = query.trim();
    const encoded = encodeURIComponent(trimmed);

    const path = location.pathname;
    let target = '/orders';
    if (path.startsWith('/products')) target = '/products';
    else if (path.startsWith('/transactions')) target = '/transactions';
    else if (path.startsWith('/invoices')) target = '/invoices';
    else if (path.startsWith('/customers')) target = '/customers';
    else if (path.startsWith('/ledger')) target = '/ledger';
    else if (path.startsWith('/orders')) target = '/orders';

    if (trimmed) {
      navigate(`${target}?q=${encoded}`);
    } else {
      navigate(target);
    }
  };

  const handleClear = () => {
    setQuery('');
    const path = location.pathname;
    if (['/orders', '/products', '/transactions', '/invoices', '/customers', '/ledger'].some(p => path.startsWith(p))) {
      navigate(path);
    }
  };

  return (
    <header className="h-16 bg-white border-b border-border flex items-center justify-between px-6 sticky top-0 z-30">
      {/* Left: Hamburger + Search */}
      <div className="flex items-center gap-4 flex-1">
        <button
          onClick={onMenuClick}
          className="lg:hidden p-2 rounded-lg hover:bg-gray-100 transition-colors"
        >
          <Menu className="w-5 h-5 text-text-secondary" />
        </button>

        <form onSubmit={handleSearchSubmit} className="relative max-w-md w-full hidden sm:block">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search Stock or Orders..."
            className="input-field w-full pl-10 pr-20 py-2.5 bg-surface"
          />
          <div className="absolute right-3 top-1/2 -translate-y-1/2 flex items-center gap-1.5">
            {query && (
              <button
                type="button"
                onClick={handleClear}
                className="text-text-muted hover:text-text-primary p-0.5 mr-1"
                title="Clear"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            )}
            <kbd className="text-[10px] font-medium text-text-muted bg-white border border-border rounded px-1.5 py-0.5">
              ⌘
            </kbd>
            <kbd className="text-[10px] font-medium text-text-muted bg-white border border-border rounded px-1.5 py-0.5">
              K
            </kbd>
          </div>
        </form>
      </div>

      {/* Right: Icons + User */}
      <div className="flex items-center gap-3">
        <button 
          onClick={() => navigate('/settings')}
          className="relative p-2.5 rounded-xl hover:bg-gray-100 text-gray-600 transition-colors"
          title="Settings"
        >
          <Settings className="w-5 h-5" />
        </button>

        {/* Real-time Notification Panel */}
        <NotificationPanel />

        {/* User Avatar */}
        <div className="flex items-center gap-3 pl-3 border-l border-border ml-1">
          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-primary-400 to-primary-600 flex items-center justify-center text-white text-sm font-bold shadow-sm">
            RM
          </div>
          <div className="hidden md:block">
            <p className="text-sm font-semibold text-text-primary leading-tight">
              RestoMart
            </p>
            <p className="text-[11px] text-text-muted leading-tight">
              Admin
            </p>
          </div>
        </div>
      </div>
    </header>
  );
}
