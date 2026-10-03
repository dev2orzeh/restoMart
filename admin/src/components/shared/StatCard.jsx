import { ArrowUpRight } from 'lucide-react';

export default function StatCard({ 
  icon: Icon, 
  title, 
  value, 
  changeText, 
  isPrimary = false 
}) {
  return (
    <div 
      className={`relative overflow-hidden rounded-[24px] p-6 flex flex-col justify-between h-[160px] ${
        isPrimary ? 'bg-[#FF7F57] text-white shadow-lg shadow-orange-200' : 'bg-[#F6F5F2] text-gray-800'
      }`}
    >
      {/* Top Row */}
      <div className="flex justify-between items-start w-full">
        <div className="flex items-center gap-3">
          {/* Icon Circle */}
          <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
            isPrimary ? 'bg-white/20' : 'bg-white shadow-sm'
          }`}>
            <Icon className={`w-5 h-5 ${isPrimary ? 'text-white' : 'text-gray-700'}`} />
          </div>
          <span className={`text-base font-medium ${isPrimary ? 'text-white/90' : 'text-gray-600'}`}>
            {title}
          </span>
        </div>
        
        {/* Top Right Arrow */}
        <div className={`w-8 h-8 rounded-full flex items-center justify-center ${
          isPrimary ? 'bg-white/20' : 'bg-white shadow-sm'
        }`}>
          <ArrowUpRight className={`w-4 h-4 ${isPrimary ? 'text-white' : 'text-gray-500'}`} />
        </div>
      </div>

      {/* Bottom Row */}
      <div className="flex items-end justify-between w-full mt-4">
        <h3 className={`text-[32px] font-bold leading-none ${isPrimary ? 'text-white' : 'text-gray-900'}`}>
          {value}
        </h3>
        <span className={`text-xs font-medium mb-1 ${isPrimary ? 'text-white/80' : 'text-gray-500'}`}>
          {changeText}
        </span>
      </div>
    </div>
  );
}
