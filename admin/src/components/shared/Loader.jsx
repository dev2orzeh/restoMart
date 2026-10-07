export default function Loader({ message = "Loading data...", compact = false, height = "280px" }) {
  if (compact) {
    return (
      <div className="flex flex-col items-center justify-center p-6 w-full bg-slate-50/50 rounded-2xl border border-slate-100 min-h-[160px]">
        <div 
          className="w-8 h-8 border-3 border-indigo-100 border-t-indigo-600 rounded-full mb-3"
          style={{ animation: 'customSpin 0.8s linear infinite' }}
        />
        <p className="text-xs text-text-secondary font-medium animate-pulse text-center">{message}</p>
        <style>{`
          @keyframes customSpin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
        `}</style>
      </div>
    );
  }

  return (
    <div
      style={{ minHeight: height }}
      className="flex flex-col items-center justify-center w-full bg-white rounded-2xl p-8 border border-gray-100 shadow-sm transition-all"
    >
      <div className="relative flex items-center justify-center mb-4">
        {/* Subtle background glow ring */}
        <div className="absolute w-12 h-12 rounded-full bg-indigo-50 blur-sm" />
        {/* Smooth Spinning Ring Loader */}
        <div 
          className="w-10 h-10 border-4 border-indigo-100 border-t-indigo-600 rounded-full relative z-10"
          style={{ animation: 'customSpin 0.8s linear infinite' }}
        />
      </div>
      <p className="text-sm font-semibold text-text-primary tracking-wide animate-pulse text-center">
        {message}
      </p>

      <style>{`
        @keyframes customSpin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
}
