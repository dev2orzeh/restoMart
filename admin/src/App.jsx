import { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/layout/Layout';
import Dashboard from './pages/Dashboard';
import Products from './pages/Products';
import Orders from './pages/Orders';
import Analytics from './pages/Analytics';
import Transactions from './pages/Transactions';
import Invoices from './pages/Invoices';
import Customers from './pages/Customers';
import Settings from './pages/Settings';
import HelpCenter from './pages/HelpCenter';
import Ledger from './pages/Ledger';
import Banners from './pages/Banners';
import Login from './pages/Login';

// Mock Protected Route component
const ProtectedRoute = ({ isAuthenticated, children }) => {
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  return children;
};

function App() {
  // Using simple state for demo purposes. In production, check tokens/cookies.
  const [isAuthenticated, setIsAuthenticated] = useState(() => {
    return localStorage.getItem('restomart_admin_auth') === 'true';
  });

  const handleLogin = () => {
    setIsAuthenticated(true);
    localStorage.setItem('restomart_admin_auth', 'true');
  };

  const handleLogout = () => {
    setIsAuthenticated(false);
    localStorage.removeItem('restomart_admin_auth');
  };

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login onLogin={handleLogin} />} />
        
        <Route 
          element={
            <ProtectedRoute isAuthenticated={isAuthenticated}>
              <Layout onLogout={handleLogout} />
            </ProtectedRoute>
          }
        >
          <Route path="/" element={<Dashboard />} />
          <Route path="/products" element={<Products />} />
          <Route path="/orders" element={<Orders />} />
          <Route path="/analytics" element={<Analytics />} />
          <Route path="/transactions" element={<Transactions />} />
          <Route path="/invoices" element={<Invoices />} />
          <Route path="/customers" element={<Customers />} />
          <Route path="/ledger" element={<Ledger />} />
          <Route path="/banners" element={<Banners />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="/help" element={<HelpCenter />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;
