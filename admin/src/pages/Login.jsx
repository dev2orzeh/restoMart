import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, Lock, Eye, EyeOff, Sparkles, CheckCircle2, AlertCircle } from 'lucide-react';

export default function Login({ onLogin }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [showForgotModal, setShowForgotModal] = useState(false);

  const navigate = useNavigate();

  const handleLogin = (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    setTimeout(() => {
      // Allow default admin credentials or any valid input for easy testing
      if ((email === 'admin@restomart.pk' && password === 'admin123') || (email && password.length >= 6)) {
        onLogin();
        navigate('/');
      } else {
        setError('Invalid credentials. Use admin@restomart.pk / admin123');
        setIsLoading(false);
      }
    }, 800);
  };

  return (
    <div className="min-h-screen bg-[#eef4fc] flex flex-col justify-between relative overflow-hidden font-sans select-none">
      {/* Top Left Branding Header */}
      <header className="p-6 sm:p-8 z-20 flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="w-9 h-9 rounded-xl bg-primary-500 flex items-center justify-center text-white shadow-md shadow-primary-500/30">
            <img src="/circular_logo.png" alt="RestoMart" className="w-6 h-6 object-contain" />
          </div>
          <span className="font-extrabold text-lg text-slate-900 tracking-tight">
            RestoMart <span className="text-xs font-bold text-primary-600 bg-primary-50 border border-primary-100 px-2 py-0.5 rounded-full ml-1">Admin Portal</span>
          </span>
        </div>
      </header>

      {/* Main Centered Login Form */}
      <main className="flex-1 flex items-center justify-center p-4 z-20 my-auto">
        <div className="w-full max-w-[440px] bg-white rounded-3xl shadow-2xl shadow-slate-300/50 border border-slate-100 p-8 sm:p-10 transition-all duration-300">
          <div className="text-center mb-8">
            <h1 className="text-2xl font-bold text-slate-900 tracking-tight mb-2">
              Admin Login
            </h1>
            <p className="text-xs sm:text-sm text-slate-500 leading-relaxed max-w-xs mx-auto">
              Hello, enter your details here to login into the dashboard.
            </p>
          </div>

          <form onSubmit={handleLogin} className="space-y-4">
            {/* Email Field */}
            <div>
              <div className="relative">
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full px-4 py-3.5 bg-slate-50/70 border border-slate-200 rounded-xl text-sm font-medium text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:bg-white transition-all"
                  placeholder="Email"
                />
              </div>
            </div>

            {/* Password Field with Hide/Show */}
            <div>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full pl-4 pr-14 py-3.5 bg-slate-50/70 border border-slate-200 rounded-xl text-sm font-medium text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:bg-white transition-all"
                  placeholder="Password"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-semibold text-slate-400 hover:text-primary-600 transition-colors"
                >
                  {showPassword ? 'Hide' : 'Show'}
                </button>
              </div>
            </div>

            {/* Error Message */}
            {error && (
              <div className="p-3 bg-red-50 border border-red-100 text-red-600 rounded-xl text-xs font-semibold text-center flex items-center justify-center gap-2">
                <AlertCircle className="w-4 h-4 shrink-0" />
                {error}
              </div>
            )}

            {/* Submit Button */}
            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-3.5 px-4 bg-primary-500 hover:bg-primary-600 active:bg-primary-700 text-white font-bold text-sm rounded-xl shadow-lg shadow-primary-500/25 transition-all duration-200 disabled:opacity-70 flex items-center justify-center gap-2 mt-4"
            >
              {isLoading ? (
                <>
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  <span>Signing in...</span>
                </>
              ) : (
                'Sign in'
              )}
            </button>
          </form>
        </div>
      </main>

      {/* Decorative Vector Graphic Canvas Background at Bottom */}
      <div className="w-full h-48 sm:h-64 pointer-events-none relative z-10 opacity-70">
        <svg className="w-full h-full" viewBox="0 0 1440 320" fill="none" xmlns="http://www.w3.org/2000/svg">
          {/* Dashboard Desk & Illustration Lines */}
          <path d="M0,288L48,272C96,256,192,224,288,218.7C384,213,480,235,576,245.3C672,256,768,256,864,240C960,224,1056,192,1152,186.7C1248,181,1344,203,1392,213.3L1440,224L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z" fill="#e2ecf9"></path>
          {/* Vector Elements */}
          <rect x="120" y="140" width="160" height="110" rx="12" fill="white" stroke="#cbd5e1" strokeWidth="2" />
          <path d="M140 210 L170 170 L210 195 L250 150" stroke="#0070f3" strokeWidth="3" strokeLinecap="round" fill="none" />
          <circle cx="250" cy="150" r="4" fill="#0070f3" />
          
          <rect x="1160" y="130" width="180" height="120" rx="12" fill="white" stroke="#cbd5e1" strokeWidth="2" />
          <rect x="1180" y="150" width="140" height="14" rx="4" fill="#38bdf8" />
          <rect x="1180" y="175" width="90" height="10" rx="3" fill="#cbd5e1" />
          <rect x="1180" y="195" width="110" height="10" rx="3" fill="#cbd5e1" />
        </svg>
      </div>

      {/* Forgot Password / Request Modal */}
      {showForgotModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-white rounded-3xl p-6 sm:p-8 max-w-sm w-full shadow-2xl border border-slate-100 text-center space-y-4">
            <div className="w-12 h-12 rounded-2xl bg-primary-50 text-primary-600 flex items-center justify-center mx-auto">
              <Sparkles className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold text-slate-900">Admin Support</h3>
            <p className="text-xs text-slate-500 leading-relaxed">
              Default login credentials:
              <br />
              <strong className="text-slate-800">Email:</strong> admin@restomart.pk
              <br />
              <strong className="text-slate-800">Password:</strong> admin123
              <br /><br />
              For password reset or new admin accounts, contact technical support at <strong className="text-primary-600">support@restomart.pk</strong>.
            </p>
            <button
              onClick={() => setShowForgotModal(false)}
              className="w-full py-2.5 bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs rounded-xl transition-colors"
            >
              Got it
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
