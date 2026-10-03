import { Search, Bell, Settings, Menu } from 'lucide-react';

export default function TopBar({ onMenuClick }) {
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

        <div className="relative max-w-md w-full hidden sm:block">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
          <input
            type="text"
            placeholder="Search Stock or Orders"
            className="input-field w-full pl-10 pr-16 py-2.5 bg-surface"
          />
          <div className="absolute right-3 top-1/2 -translate-y-1/2 flex items-center gap-1">
            <kbd className="text-[10px] font-medium text-text-muted bg-white border border-border rounded px-1.5 py-0.5">
              ⌘
            </kbd>
            <kbd className="text-[10px] font-medium text-text-muted bg-white border border-border rounded px-1.5 py-0.5">
              K
            </kbd>
          </div>
        </div>
      </div>

      {/* Right: Icons + User */}
      <div className="flex items-center gap-3">
        <button className="relative p-2 rounded-lg hover:bg-gray-100 transition-colors">
          <Settings className="w-[18px] h-[18px] text-text-secondary" />
        </button>

        <button className="relative p-2 rounded-lg hover:bg-gray-100 transition-colors">
          <Bell className="w-[18px] h-[18px] text-text-secondary" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-danger rounded-full border-2 border-white" />
        </button>

        {/* User Avatar */}
        <div className="flex items-center gap-3 pl-3 border-l border-border ml-1">
          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-primary-400 to-primary-600 flex items-center justify-center text-white text-sm font-bold">
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
