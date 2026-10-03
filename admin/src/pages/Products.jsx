import { useState, useMemo } from 'react';
import {
  ShoppingCart,
  DollarSign,
  AlertTriangle,
  Search,
  SlidersHorizontal,
  Calendar,
  Pencil,
  Eye,
  Download,
  Save,
} from 'lucide-react';
import StatCard from '../components/shared/StatCard';
import StatusBadge from '../components/shared/StatusBadge';
import FilterPanel from '../components/shared/FilterPanel';
import Modal from '../components/shared/Modal';
import {
  mockProducts as initialProducts, // kept for reference
  mockDashboardStats,
} from '../data/mockData';
import { getProducts, updateProduct, createProduct, getCategories } from '../services/woocommerce';
import { useEffect } from 'react';

export default function Products() {
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterOpen, setFilterOpen] = useState(false);
  const [activeFilters, setActiveFilters] = useState(null);
  const [editProduct, setEditProduct] = useState(null);
  const [viewProduct, setViewProduct] = useState(null);
  const [isAddingProduct, setIsAddingProduct] = useState(false);
  const [newProduct, setNewProduct] = useState({
    name: '', brand: '', category: '', price: 0, stock: 0, image: ''
  });
  const stats = {
    totalProducts: products.length,
    lowStock: products.filter(p => p.status === 'low_stock' || p.status === 'out_of_stock').length,
    categories: categories.length,
    revenue: products.reduce((acc, p) => acc + (p.price || 0), 0) // Approximation
  };

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [prods, cats] = await Promise.all([
        getProducts(),
        getCategories()
      ]);
      setProducts(prods);
      setCategories(cats);
      if (cats.length > 0) {
        setNewProduct(prev => ({ ...prev, category: cats[0] }));
      }
    } catch (error) {
      console.error('Failed to load products', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredProducts = useMemo(() => {
    let prods = [...products];

    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      prods = prods.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          p.productId.toLowerCase().includes(q) ||
          p.brand.toLowerCase().includes(q)
      );
    }

    if (activeFilters) {
      const { stockFilters, categoryFilters } = activeFilters;

      const activeStockStatuses = Object.entries(stockFilters)
        .filter(([, v]) => v)
        .map(([k]) => k);

      if (activeStockStatuses.length > 0) {
        prods = prods.filter((p) =>
          activeStockStatuses.includes(p.status)
        );
      }

      const activeCategories = Object.entries(categoryFilters)
        .filter(([, v]) => v)
        .map(([k]) => k);

      if (activeCategories.length > 0 && activeCategories.length < categories.length) {
        prods = prods.filter((p) =>
          activeCategories.includes(p.category)
        );
      }
    }

    return prods;
  }, [products, searchQuery, activeFilters, categories]);

  const handleExportCSV = () => {
    const headers = ['Product ID', 'Name', 'Brand', 'Category', 'Stock', 'Price', 'Status'];
    const rows = filteredProducts.map((p) => [
      p.productId, p.name, p.brand, p.category, p.stock, p.price, p.status,
    ]);
    const csv = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'RestoMart-Products.csv';
    link.click();
  };

  const handleSaveProduct = async (updatedProduct) => {
    try {
      await updateProduct(updatedProduct.id, {
        regular_price: updatedProduct.price.toString(),
        manage_stock: true,
        stock_quantity: updatedProduct.stock,
      });

      let status = 'in_stock';
      if (updatedProduct.stock === 0) status = 'out_of_stock';
      else if (updatedProduct.stock <= 15) status = 'low_stock';
      else if (updatedProduct.stock > 500) status = 'overflow';

      setProducts((prev) =>
        prev.map((p) =>
          p.id === updatedProduct.id
            ? { ...p, ...updatedProduct, status }
            : p
        )
      );
      setEditProduct(null);
    } catch (error) {
      alert('Failed to update product');
    }
  };

  const handleCreateProduct = async () => {
    try {
      const created = await createProduct({
        name: newProduct.name,
        regular_price: newProduct.price.toString(),
        manage_stock: true,
        stock_quantity: newProduct.stock,
      });
      // reload data
      loadData();
      setIsAddingProduct(false);
      setNewProduct({ name: '', brand: '', category: categories[0] || '', price: 0, stock: 0, image: '' });
    } catch (error) {
      alert('Failed to create product');
    }
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text-primary">Products</h1>
          <p className="text-sm text-text-secondary mt-1">
            Manage your inventory and stock levels
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={handleExportCSV} className="btn-outline flex items-center gap-2">
            <Download className="w-4 h-4" />
            Export CSV
          </button>
          <button onClick={() => setIsAddingProduct(true)} className="btn-primary flex items-center gap-2">
            <ShoppingCart className="w-4 h-4" />
            Add Product
          </button>
        </div>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <StatCard
          icon={ShoppingCart}
          iconBg="bg-blue-100 text-blue-600"
          title="Total Products"
          value={stats.totalProducts.toLocaleString()}
          change="+Active"
        />
        <StatCard
          icon={DollarSign}
          iconBg="bg-emerald-100 text-emerald-600"
          title="Categories"
          value={`${stats.categories}`}
          change="Available"
        />
        <StatCard
          icon={AlertTriangle}
          iconBg="bg-red-100 text-red-500"
          title="Low/Out of Stock"
          value={`${stats.lowStock} Items`}
          change="Needs action"
        />
      </div>

      {/* Toolbar */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[200px] max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
          <input
            type="text"
            placeholder="Search products..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="input-field w-full pl-10"
          />
        </div>

        <button className="btn-outline flex items-center gap-2">
          <Calendar className="w-4 h-4" />
          Select Date
        </button>

        <div className="relative">
          <button
            onClick={() => setFilterOpen(!filterOpen)}
            className={`btn-outline flex items-center gap-2 ${
              activeFilters ? 'border-primary-400 text-primary-500' : ''
            }`}
          >
            <SlidersHorizontal className="w-4 h-4" />
            Filters
            {activeFilters && (
              <span className="w-2 h-2 bg-primary-500 rounded-full" />
            )}
          </button>
          <FilterPanel
            isOpen={filterOpen}
            onClose={() => setFilterOpen(false)}
            onApply={(filters) => setActiveFilters(filters)}
            categories={categories}
          />
        </div>
      </div>

      {/* Products Table */}
      <div className="bg-white rounded-card shadow-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="bg-surface">
                <th className="table-header text-left py-3 px-4">Product</th>
                <th className="table-header text-left py-3 px-4">Product ID</th>
                <th className="table-header text-left py-3 px-4">Category</th>
                <th className="table-header text-center py-3 px-4">Stock</th>
                <th className="table-header text-right py-3 px-4">Price</th>
                <th className="table-header text-center py-3 px-4">Status</th>
                <th className="table-header text-center py-3 px-4">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredProducts.map((product) => (
                <tr
                  key={product.id}
                  className="hover:bg-surface/50 transition-colors group"
                >
                  <td className="table-cell">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-lg bg-surface overflow-hidden flex-shrink-0">
                        <img
                          src={product.image}
                          alt={product.name}
                          className="w-full h-full object-contain p-1"
                          onError={(e) => { e.target.style.display = 'none'; }}
                        />
                      </div>
                      <div>
                        <p className="font-semibold text-text-primary text-sm">{product.name}</p>
                        <p className="text-xs text-text-muted">{product.brand}</p>
                      </div>
                    </div>
                  </td>
                  <td className="table-cell font-semibold text-primary-500">{product.productId}</td>
                  <td className="table-cell text-text-secondary">{product.category}</td>
                  <td className="table-cell text-center font-medium">{product.stock}</td>
                  <td className="table-cell text-right font-semibold">₨ {product.price.toLocaleString()}</td>
                  <td className="table-cell text-center">
                    <StatusBadge status={product.status} />
                  </td>
                  <td className="table-cell text-center">
                    <div className="flex items-center justify-center gap-1">
                      <button
                        onClick={() => setEditProduct({ ...product })}
                        className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors"
                        title="Edit Product"
                      >
                        <Pencil className="w-4 h-4 text-text-secondary" />
                      </button>
                      <button
                        onClick={() => setViewProduct(product)}
                        className="p-1.5 rounded-lg hover:bg-gray-100 transition-colors"
                        title="View Product"
                      >
                        <Eye className="w-4 h-4 text-text-secondary" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}

              {filteredProducts.length === 0 && (
                <tr>
                  <td colSpan={7} className="text-center py-12 text-text-muted text-sm">
                    No products found matching your criteria.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Edit Product Modal */}
      <Modal
        isOpen={!!editProduct}
        onClose={() => setEditProduct(null)}
        title="Edit Product"
      >
        {editProduct && (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-text-secondary mb-1.5">Product Name</label>
              <input
                type="text"
                value={editProduct.name}
                onChange={(e) => setEditProduct({ ...editProduct, name: e.target.value })}
                className="input-field w-full"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-text-secondary mb-1.5">Price (₨)</label>
                <input
                  type="number"
                  value={editProduct.price}
                  onChange={(e) => setEditProduct({ ...editProduct, price: Number(e.target.value) })}
                  className="input-field w-full"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-text-secondary mb-1.5">Stock</label>
                <input
                  type="number"
                  value={editProduct.stock}
                  onChange={(e) => setEditProduct({ ...editProduct, stock: Number(e.target.value) })}
                  className="input-field w-full"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-text-secondary mb-1.5">Category</label>
              <select
                value={editProduct.category}
                onChange={(e) => setEditProduct({ ...editProduct, category: e.target.value })}
                className="input-field w-full"
              >
                {categories.map((cat) => (
                  <option key={cat} value={cat}>{cat}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-text-secondary mb-1.5">Brand</label>
              <input
                type="text"
                value={editProduct.brand}
                onChange={(e) => setEditProduct({ ...editProduct, brand: e.target.value })}
                className="input-field w-full"
              />
            </div>
            <div className="flex gap-3 pt-2">
              <button
                onClick={() => handleSaveProduct(editProduct)}
                className="btn-primary flex items-center gap-2"
              >
                <Save className="w-4 h-4" />
                Save Changes
              </button>
              <button onClick={() => setEditProduct(null)} className="btn-outline">
                Cancel
              </button>
            </div>
          </div>
        )}
      </Modal>

      {/* View Product Modal */}
      <Modal
        isOpen={!!viewProduct}
        onClose={() => setViewProduct(null)}
        title="Product Details"
      >
        {viewProduct && (
          <div className="space-y-5">
            <div className="flex items-center gap-4">
              <div className="w-20 h-20 rounded-xl bg-surface overflow-hidden flex-shrink-0">
                <img
                  src={viewProduct.image}
                  alt={viewProduct.name}
                  className="w-full h-full object-contain p-2"
                  onError={(e) => { e.target.style.display = 'none'; }}
                />
              </div>
              <div>
                <h3 className="text-lg font-bold text-text-primary">{viewProduct.name}</h3>
                <p className="text-sm text-text-muted">{viewProduct.brand}</p>
                <StatusBadge status={viewProduct.status} />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              {[
                { label: 'Product ID', value: viewProduct.productId },
                { label: 'Category', value: viewProduct.category },
                { label: 'Price', value: `₨ ${viewProduct.price.toLocaleString()}` },
                { label: 'Stock', value: viewProduct.stock },
              ].map((item) => (
                <div key={item.label} className="bg-surface rounded-xl p-4">
                  <p className="text-xs font-semibold text-text-muted uppercase tracking-wider mb-1">{item.label}</p>
                  <p className="text-sm font-bold text-text-primary">{item.value}</p>
                </div>
              ))}
            </div>
            <button
              onClick={() => {
                setViewProduct(null);
                setEditProduct({ ...viewProduct });
              }}
              className="btn-primary flex items-center gap-2"
            >
              <Pencil className="w-4 h-4" />
              Edit Product
            </button>
          </div>
        )}
      </Modal>
      {/* Add Product Modal */}
      <Modal
        isOpen={isAddingProduct}
        onClose={() => setIsAddingProduct(false)}
        title="Add New Product"
      >
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-text-secondary mb-1.5">Product Name</label>
            <input
              type="text"
              value={newProduct.name}
              onChange={(e) => setNewProduct({ ...newProduct, name: e.target.value })}
              className="input-field w-full"
              placeholder="e.g. Shangrila Tomato Ketchup"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-text-secondary mb-1.5">Price (₨)</label>
              <input
                type="number"
                value={newProduct.price}
                onChange={(e) => setNewProduct({ ...newProduct, price: Number(e.target.value) })}
                className="input-field w-full"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-text-secondary mb-1.5">Initial Stock</label>
              <input
                type="number"
                value={newProduct.stock}
                onChange={(e) => setNewProduct({ ...newProduct, stock: Number(e.target.value) })}
                className="input-field w-full"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-text-secondary mb-1.5">Category</label>
            <select
              value={newProduct.category}
              onChange={(e) => setNewProduct({ ...newProduct, category: e.target.value })}
              className="input-field w-full"
            >
              {categories.map((cat) => (
                <option key={cat} value={cat}>{cat}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-text-secondary mb-1.5">Brand</label>
            <input
              type="text"
              value={newProduct.brand}
              onChange={(e) => setNewProduct({ ...newProduct, brand: e.target.value })}
              className="input-field w-full"
              placeholder="e.g. Shangrila"
            />
          </div>
          <div className="flex gap-3 pt-2">
            <button
              onClick={handleCreateProduct}
              className="btn-primary flex items-center gap-2"
              disabled={!newProduct.name}
            >
              <Save className="w-4 h-4" />
              Create Product
            </button>
            <button onClick={() => setIsAddingProduct(false)} className="btn-outline">
              Cancel
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
