const statusConfig = {
  in_stock: { label: 'In Stock', className: 'badge-success' },
  low_stock: { label: 'Low Stock', className: 'badge-warning' },
  out_of_stock: { label: 'Out of Stock', className: 'badge-danger' },
  overflow: { label: 'Overflow Stock', className: 'badge-info' },
  pending: { label: 'Pending', className: 'badge-pending' },
  processing: { label: 'Processing', className: 'badge-warning' },
  delivered: { label: 'Delivered', className: 'badge-success' },
  cancelled: { label: 'Cancelled', className: 'badge-danger' },
  paid: { label: 'Paid', className: 'badge-success' },
  failed: { label: 'Failed', className: 'badge-danger' },
};

export default function StatusBadge({ status }) {
  const config = statusConfig[status] || {
    label: status,
    className: 'bg-gray-100 text-gray-600',
  };

  return <span className={`badge ${config.className}`}>{config.label}</span>;
}
