/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#EEEEFF',
          100: '#D4D4FF',
          200: '#A8A8FF',
          300: '#7C7CFF',
          400: '#5252F0',
          500: '#4F46E5',
          600: '#3730A3',
          700: '#25258F',
          800: '#1E1E7A',
          900: '#141452',
        },
        surface: '#F8F9FC',
        card: '#FFFFFF',
        sidebar: '#FFFFFF',
        success: '#10B981',
        danger: '#EF4444',
        warning: '#F59E0B',
        info: '#8B5CF6',
        border: '#E5E7EB',
        'text-primary': '#1A1A2E',
        'text-secondary': '#6B7280',
        'text-muted': '#9CA3AF',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
      },
      borderRadius: {
        'card': '12px',
        'btn': '8px',
      },
      boxShadow: {
        'card': '0 1px 3px rgba(0,0,0,0.04), 0 1px 2px rgba(0,0,0,0.02)',
        'card-hover': '0 4px 12px rgba(0,0,0,0.08)',
        'sidebar': '2px 0 8px rgba(0,0,0,0.04)',
      },
    },
  },
  plugins: [],
}
