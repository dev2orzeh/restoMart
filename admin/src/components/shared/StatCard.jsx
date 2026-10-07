import { ArrowUpRight } from 'lucide-react';

export default function StatCard({ 
  icon: Icon, 
  title, 
  value, 
  changeText,
  change,
  isPrimary = false,
  color = 'indigo',
  iconBg,
  onClick
}) {
  const badgeText = changeText || change || '';

  // Theme presets based on color prop
  const colorMap = {
    blue: {
      bg: 'bg-blue-50/70 hover:bg-blue-50/90',
      border: 'border-blue-100/80',
      icon: 'bg-blue-500 text-white shadow-blue-200',
      arrow: 'bg-blue-100 text-blue-600',
      badge: 'bg-blue-100/80 text-blue-700',
    },
    emerald: {
      bg: 'bg-emerald-50/70 hover:bg-emerald-50/90',
      border: 'border-emerald-100/80',
      icon: 'bg-emerald-500 text-white shadow-emerald-200',
      arrow: 'bg-emerald-100 text-emerald-600',
      badge: 'bg-emerald-100/80 text-emerald-700',
    },
    red: {
      bg: 'bg-rose-50/70 hover:bg-rose-50/90',
      border: 'border-rose-100/80',
      icon: 'bg-rose-500 text-white shadow-rose-200',
      arrow: 'bg-rose-100 text-rose-600',
      badge: 'bg-rose-100/80 text-rose-700',
    },
    amber: {
      bg: 'bg-amber-50/70 hover:bg-amber-50/90',
      border: 'border-amber-100/80',
      icon: 'bg-amber-500 text-white shadow-amber-200',
      arrow: 'bg-amber-100 text-amber-600',
      badge: 'bg-amber-100/80 text-amber-700',
    },
    indigo: {
      bg: 'bg-slate-50/80 hover:bg-slate-100/80',
      border: 'border-slate-200/80',
      icon: 'bg-indigo-600 text-white shadow-indigo-200',
      arrow: 'bg-gray-100 text-gray-600',
      badge: 'bg-gray-100 text-gray-600',
    }
  };

  const theme = colorMap[color] || colorMap.indigo;

  return (
    <div 
      onClick={onClick}
      className={`group relative overflow-hidden rounded-[24px] p-6 flex flex-col justify-between h-[165px] transition-all duration-300 ease-out transform hover:-translate-y-1.5 cursor-pointer border ${
        isPrimary 
          ? 'bg-gradient-to-br from-[#FF7F57] via-[#FF6B3D] to-[#E85026] text-white shadow-lg shadow-orange-500/20 hover:shadow-2xl hover:shadow-orange-500/30 border-orange-400/40' 
          : `${theme.bg} ${theme.border} text-gray-800 shadow-sm hover:shadow-xl hover:shadow-slate-200/60`
      }`}
    >
      {/* Background Subtle Accent Shape */}
      <div 
        className={`absolute -right-8 -bottom-8 w-32 h-32 rounded-full transition-all duration-500 group-hover:scale-125 opacity-20 ${
          isPrimary ? 'bg-white' : 'bg-current'
        }`} 
      />

      {/* Top Row */}
      <div className="flex justify-between items-start w-full relative z-10">
        <div className="flex items-center gap-3">
          {/* Icon Circle */}
          <div className={`w-11 h-11 rounded-2xl flex items-center justify-center transition-transform duration-300 group-hover:scale-110 group-hover:rotate-3 shadow-sm ${
            isPrimary 
              ? 'bg-white/20 backdrop-blur-md text-white' 
              : iconBg || theme.icon
          }`}>
            <Icon className="w-5 h-5" />
          </div>
          <span className={`text-sm font-bold tracking-tight ${isPrimary ? 'text-white/90' : 'text-gray-700'}`}>
            {title}
          </span>
        </div>
        
        {/* Top Right Arrow Button */}
        <div className={`w-8 h-8 rounded-full flex items-center justify-center transition-all duration-300 ${
          isPrimary 
            ? 'bg-white/20 group-hover:bg-white group-hover:text-[#FF6B3D] text-white' 
            : `${theme.arrow} group-hover:bg-gray-900 group-hover:text-white`
        }`}>
          <ArrowUpRight className="w-4 h-4 transition-transform duration-300 group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
        </div>
      </div>

      {/* Bottom Row */}
      <div className="flex items-end justify-between w-full mt-4 relative z-10">
        <h3 className={`text-[32px] font-extrabold tracking-tight leading-none ${isPrimary ? 'text-white' : 'text-gray-900'}`}>
          {value}
        </h3>
        {badgeText && (
          <span className={`text-xs font-semibold px-2.5 py-1 rounded-full backdrop-blur-sm transition-colors ${
            isPrimary 
              ? 'bg-white/20 text-white' 
              : theme.badge
          }`}>
            {badgeText}
          </span>
        )}
      </div>
    </div>
  );
}
