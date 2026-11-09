import { useRef } from 'react';
import { Download, Printer, Package } from 'lucide-react';
import html2canvas from 'html2canvas-pro';

export default function InvoiceTemplate({ order, ledgerAccount, onClose }) {
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

  const subtotal = (order.items || []).reduce((sum, item) => sum + (item.qty || item.quantity || 1) * (item.price || 0), 0);
  const shipping = 0;
  const total = parseFloat(order.total || subtotal);

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
              <p className="text-base text-gray-500">INV-{order.id.toString().split('-').pop()}</p>
            </div>
          </div>

          {/* Info Grid */}
          <div className="grid grid-cols-2 gap-8 mb-10">
            <div>
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Bill To</p>
              <p className="text-base font-bold text-gray-800">{order.customer || 'Customer'}</p>
              <p className="text-sm text-gray-500 mt-1">{order.email || 'N/A'}</p>
              <p className="text-sm text-gray-500">{order.phone || 'N/A'}</p>
              {order.address && <p className="text-sm text-gray-500 mt-1">{order.address}</p>}
            </div>
            <div className="text-right">
              <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-3">Invoice Details</p>
              <p className="text-sm text-gray-600 mb-1"><span className="font-semibold text-gray-800 mr-2">Date:</span> {order.date}</p>
              <p className="text-sm text-gray-600 mb-1"><span className="font-semibold text-gray-800 mr-2">Order ID:</span> {order.id}</p>
              <p className="text-sm text-gray-600 font-bold text-[#25258F]"><span className="font-semibold text-gray-800 mr-2">Payment Method:</span> {order.payment || order.paymentMethod || 'Cash on delivery'}</p>
            </div>
          </div>

          {/* Items Table */}
          <table className="w-full mb-10">
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
              {(order.items || []).map((item, i) => {
                const q = item.qty || item.quantity || 1;
                const p = item.price || 0;
                return (
                  <tr key={i} className="border-b border-gray-100">
                    <td className="py-4 text-sm text-gray-500">{i + 1}</td>
                    <td className="py-4 text-sm font-semibold text-gray-800">{item.name}</td>
                    <td className="py-4 text-sm text-gray-600 text-center font-medium">x{q}</td>
                    <td className="py-4 text-sm text-gray-600 text-right">₨ {p.toLocaleString()}</td>
                    <td className="py-4 text-sm font-bold text-gray-800 text-right">₨ {(q * p).toLocaleString()}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>

          {/* Totals & Summary */}
          <div className="flex justify-end mb-8">
            <div className="w-72 space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-gray-500 font-medium">Subtotal</span>
                <span className="font-semibold text-gray-800">₨ {subtotal.toLocaleString()}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-500 font-medium">Shipping</span>
                <span className="font-semibold text-gray-800">₨ {shipping.toLocaleString()}</span>
              </div>
              <div className="border-t-2 border-[#25258F] pt-3 mt-2 flex justify-between items-center">
                <span className="text-lg font-bold text-[#25258F]">Order Total</span>
                <span className="text-xl font-bold text-[#25258F]">₨ {total.toLocaleString()}</span>
              </div>
            </div>
          </div>

          {/* Payment Method & Customer Ledger (Business Khata) Summary Box */}
          <div className="grid grid-cols-2 gap-6 p-5 bg-gray-50 rounded-xl border border-gray-200">
            <div>
              <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Payment Details</p>
              <p className="text-sm text-gray-700">
                <span className="font-semibold text-gray-900">Payment Method:</span> {order.payment || order.paymentMethod || 'Cash on delivery'}
              </p>
              <p className="text-sm text-gray-700 mt-1">
                <span className="font-semibold text-gray-900">Order Status:</span>{' '}
                <span className="inline-block px-2 py-0.5 rounded text-xs font-bold bg-blue-100 text-blue-800 uppercase">
                  {order.status || 'Pending'}
                </span>
              </p>
            </div>

            <div className="border-l border-gray-200 pl-6">
              <p className="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">Customer Business Khata (Ledger)</p>
              {ledgerAccount ? (
                <div className="space-y-2.5">
                  {/* Total Debit / Purchased Card */}
                  <div className="flex justify-between items-center px-3 py-2 rounded-lg bg-red-50 border border-red-200 shadow-xs">
                    <span className="font-bold text-red-900 text-sm flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full bg-red-600"></span>
                      Total Orders (Debit):
                    </span>
                    <span className="font-extrabold text-red-700 text-base">
                      ₨ {(ledgerAccount.totalDebit || 0).toLocaleString()}
                    </span>
                  </div>

                  {/* Total Credit / Received Card */}
                  <div className="flex justify-between items-center px-3 py-2 rounded-lg bg-emerald-50 border border-emerald-200 shadow-xs">
                    <span className="font-bold text-emerald-950 text-sm flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full bg-emerald-600"></span>
                      Payment Received (Credit):
                    </span>
                    <span className="font-extrabold text-emerald-700 text-base">
                      ₨ {(ledgerAccount.totalCredit || 0).toLocaleString()}
                    </span>
                  </div>

                  {/* Outstanding Balance */}
                  <div className="flex justify-between items-center pt-2.5 px-1 border-t-2 border-gray-200">
                    <span className="text-gray-900 text-xs font-bold uppercase tracking-wider">
                      {(ledgerAccount.balance || 0) > 0 
                        ? "Outstanding Balance (Debt):" 
                        : (ledgerAccount.balance || 0) < 0 
                          ? "Advance Credit / Surplus:" 
                          : "Outstanding Balance:"}
                    </span>
                    <span className={`text-lg font-black ${(ledgerAccount.balance || 0) > 0 ? "text-red-600" : "text-emerald-600"}`}>
                      ₨ {Math.abs(ledgerAccount.balance || 0).toLocaleString()}
                    </span>
                  </div>
                </div>
              ) : (
                <div className="space-y-2">
                  <div className="flex justify-between items-center px-3 py-2.5 rounded-lg bg-emerald-50 border border-emerald-200">
                    <span className="font-bold text-emerald-950 text-sm">Payment Status:</span>
                    <span className="font-extrabold text-emerald-700 text-base">All Clear (₨ 0.00)</span>
                  </div>
                  <p className="text-xs text-gray-400 font-medium">Account clear / no active debt.</p>
                </div>
              )}
            </div>
          </div>

          {/* Footer */}
          <div className="mt-auto pt-8 border-t border-gray-200 text-center">
            <p className="text-xs text-gray-400 font-bold uppercase tracking-widest mb-1">Thank you for shopping with RestoMart!</p>
            <p className="text-xs text-gray-500">restomart.pk • Lahore, Pakistan • 0321-1655556 / 0321-0655555</p>
          </div>
        </div>
      </div>
    </div>
  );
}
