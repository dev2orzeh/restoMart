import { useState } from 'react';
import { X, ChevronDown, ChevronUp } from 'lucide-react';

export default function FilterPanel({ isOpen, onClose, onApply, categories }) {
  const [stockFilters, setStockFilters] = useState({
    overflow: false,
    low_stock: true,
    out_of_stock: true,
  });

  const [categoryFilters, setCategoryFilters] = useState(
    categories.reduce((acc, cat) => ({ ...acc, [cat]: true }), {})
  );

  const [stockOpen, setStockOpen] = useState(true);
  const [catOpen, setCatOpen] = useState(true);

  const handleStockToggle = (key) => {
    setStockFilters((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const handleCategoryToggle = (cat) => {
    setCategoryFilters((prev) => ({ ...prev, [cat]: !prev[cat] }));
  };

  const handleReset = () => {
    setStockFilters({ overflow: false, low_stock: false, out_of_stock: false });
    setCategoryFilters(
      categories.reduce((acc, cat) => ({ ...acc, [cat]: false }), {})
    );
  };

  const handleApply = () => {
    onApply({ stockFilters, categoryFilters });
    onClose();
  };

  if (!isOpen) return null;

  return (
    <>
      <div className="fixed inset-0 z-40" onClick={onClose} />
      <div className="absolute right-0 top-12 z-50 w-[280px] bg-white rounded-xl shadow-lg border border-border animate-in fade-in slide-in-from-top-2">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-border">
          <h3 className="text-base font-bold text-text-primary">Filters</h3>
          <button
            onClick={handleReset}
            className="text-xs text-text-muted hover:text-primary-500 font-medium transition-colors"
          >
            Reset
          </button>
        </div>

        <div className="p-5 space-y-5 max-h-[400px] overflow-y-auto">
          {/* Stock Filter */}
          <div className="border border-border rounded-lg">
            <button
              onClick={() => setStockOpen(!stockOpen)}
              className="flex items-center justify-between w-full px-4 py-3 text-sm font-semibold text-text-primary"
            >
              Product Stock
              {stockOpen ? (
                <ChevronUp className="w-4 h-4 text-text-muted" />
              ) : (
                <ChevronDown className="w-4 h-4 text-text-muted" />
              )}
            </button>
            {stockOpen && (
              <div className="px-4 pb-3 space-y-3">
                {[
                  { key: 'overflow', label: 'Overflow Stock' },
                  { key: 'low_stock', label: 'Low Stock' },
                  { key: 'out_of_stock', label: 'Out of Stock' },
                ].map((item) => (
                  <label
                    key={item.key}
                    className="flex items-center gap-3 cursor-pointer"
                  >
                    <input
                      type="checkbox"
                      checked={stockFilters[item.key]}
                      onChange={() => handleStockToggle(item.key)}
                      className="w-4 h-4 rounded border-border text-primary-500 focus:ring-primary-200"
                    />
                    <span className="text-sm text-text-secondary">
                      {item.label}
                    </span>
                  </label>
                ))}
              </div>
            )}
          </div>

          {/* Category Filter */}
          <div className="border border-border rounded-lg">
            <button
              onClick={() => setCatOpen(!catOpen)}
              className="flex items-center justify-between w-full px-4 py-3 text-sm font-semibold text-text-primary"
            >
              Category
              {catOpen ? (
                <ChevronUp className="w-4 h-4 text-text-muted" />
              ) : (
                <ChevronDown className="w-4 h-4 text-text-muted" />
              )}
            </button>
            {catOpen && (
              <div className="px-4 pb-3 space-y-3">
                {categories.map((cat) => (
                  <label
                    key={cat}
                    className="flex items-center gap-3 cursor-pointer"
                  >
                    <input
                      type="checkbox"
                      checked={categoryFilters[cat]}
                      onChange={() => handleCategoryToggle(cat)}
                      className="w-4 h-4 rounded border-border text-primary-500 focus:ring-primary-200"
                    />
                    <span className="text-sm text-text-secondary">{cat}</span>
                  </label>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="flex items-center gap-3 px-5 py-4 border-t border-border">
          <button onClick={onClose} className="btn-outline flex-1">
            Cancel
          </button>
          <button onClick={handleApply} className="btn-primary flex-1">
            Apply Filter
          </button>
        </div>
      </div>
    </>
  );
}
