import { useRef } from 'react';
import { Download, Printer, Package } from 'lucide-react';
import html2canvas from 'html2canvas-pro';

export default function InvoiceTemplate({ order, onClose }) {
  const invoiceRef = useRef(null);

  const handleDownload = async () => {
    if (!invoiceRef.current) return;

    const canvas = await html2canvas(invoiceRef.current, {
      scale: 2,
      backgroundColor: '#ffffff',
      useCORS: true,
    });

    const link = document.createElement('a');
    link.download = `RestoMart-Invoice-${order.id}.png`;
    link.href = canvas.toDataURL('image/png');
    link.click();
  };

  const handlePrint = () => {
    window.print();
  };

  const subtotal = order.items.reduce((sum, item) => sum + item.qty * item.price, 0);
  const shipping = 0;
  const total = subtotal + shipping;

  return (
    <div>
      {/* Action Buttons */}
      <div className="flex items-center gap-3 mb-6 no-print">
        <button
          onClick={handleDownload}
          className="btn-primary flex items-center gap-2"
        >
          <Download className="w-4 h-4" />
          Download PNG
        </button>
        <button
          onClick={handlePrint}
          className="btn-outline flex items-center gap-2"
        >
          <Printer className="w-4 h-4" />
          Print
        </button>
      </div>

      {/* Invoice Content */}
      <div className="bg-gray-100 print:bg-white p-4 sm:p-8 print:p-0 rounded-xl overflow-x-auto">
        <div
          ref={invoiceRef}
          className="bg-white p-10 print-area flex flex-col mx-auto shadow-sm print:shadow-none"
          style={{ width: '794px', minHeight: '1123px' }}
        >
          {/* Header */}
          <div className="flex items-start justify-between mb-12">
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 flex items-center justify-center">
                <img src="/circular_logo.png" alt="RestoMart Logo" className="w-full h-full object-contain drop-shadow-sm" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-[#25258F]">RestoMart</h1>
                <p className="text-sm text-gray-500">Your Trusted Grocery Partner</p>
              </div>
            </div>
            <div className="text-right">
              <h2 className="text-3xl font-bold text-[#25258F] mb-1">INVOICE</h2>
              <p className="text-base text-gray-500">INV-{order.id.split('-').pop()}</p>
            </div>
          </div>

          {/* Info Grid */}
          <div className="grid grid-cols-2 gap-8 mb-12">
            <div>
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Bill To</p>
              <p className="text-base font-bold text-gray-800">{order.customer}</p>
              <p className="text-sm text-gray-500 mt-1">{order.email}</p>
              <p className="text-sm text-gray-500">{order.phone}</p>
            </div>
            <div className="text-right">
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Invoice Details</p>
              <p className="text-sm text-gray-600 mb-1"><span className="font-semibold text-gray-800 mr-2">Date:</span> {order.date}</p>
              <p className="text-sm text-gray-600 mb-1"><span className="font-semibold text-gray-800 mr-2">Order ID:</span> {order.id}</p>
              <p className="text-sm text-gray-600"><span className="font-semibold text-gray-800 mr-2">Payment:</span> {order.payment}</p>
            </div>
          </div>

          {/* Items Table */}
          <table className="w-full mb-12">
            <thead>
              <tr className="border-b-2 border-[#25258F]">
                <th className="text-left py-4 text-xs font-bold text-gray-500 uppercase tracking-wider w-16">#</th>
                <th className="text-left py-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Description</th>
                <th className="text-center py-4 text-xs font-bold text-gray-500 uppercase tracking-wider w-24">Qty</th>
                <th className="text-right py-4 text-xs font-bold text-gray-500 uppercase tracking-wider w-32">Unit Price</th>
                <th className="text-right py-4 text-xs font-bold text-gray-500 uppercase tracking-wider w-32">Total</th>
              </tr>
            </thead>
            <tbody>
              {order.items.map((item, i) => (
                <tr key={i} className="border-b border-gray-100">
                  <td className="py-5 text-sm text-gray-500">{i + 1}</td>
                  <td className="py-5 text-sm font-semibold text-gray-800">{item.name}</td>
                  <td className="py-5 text-sm text-gray-600 text-center font-medium">x{item.qty}</td>
                  <td className="py-5 text-sm text-gray-600 text-right">₨ {item.price.toLocaleString()}</td>
                  <td className="py-5 text-sm font-bold text-gray-800 text-right">₨ {(item.qty * item.price).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>

          {/* Totals */}
          <div className="flex justify-end">
            <div className="w-72 space-y-3">
              <div className="flex justify-between text-sm">
                <span className="text-gray-500 font-medium">Subtotal</span>
                <span className="font-semibold text-gray-800">₨ {subtotal.toLocaleString()}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-500 font-medium">Shipping</span>
                <span className="font-semibold text-gray-800">₨ {shipping.toLocaleString()}</span>
              </div>
              <div className="border-t-2 border-[#25258F] pt-3 mt-3 flex justify-between items-center">
                <span className="text-lg font-bold text-[#25258F]">Total</span>
                <span className="text-xl font-bold text-[#25258F]">₨ {total.toLocaleString()}</span>
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="mt-24 pt-8 border-t border-gray-200 text-center">
            <p className="text-xs text-gray-400 font-bold uppercase tracking-widest mb-2">Thank you for shopping with RestoMart!</p>
            <p className="text-xs text-gray-500">restomart.pk • Lahore, Pakistan • +92 325 8019294</p>
          </div>
        </div>
      </div>
    </div>
  );
}
