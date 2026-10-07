import { useState } from 'react';
import { Mail, MessageCircle, Phone, FileQuestion, ExternalLink } from 'lucide-react';

const faqs = [
  {
    question: "How do I add a new product?",
    answer: "Go to the Products tab from the sidebar and click the 'Add Product' button in the top right corner. Fill out the product details and click Save."
  },
  {
    question: "How are orders synced from the app?",
    answer: "Orders placed in the mobile app are instantly synced to this dashboard via the WooCommerce REST API. You will see them appear in the Orders tab."
  },
  {
    question: "Can I print invoices for completed orders?",
    answer: "Yes. Open any order in the Orders tab or go to the Invoices tab. Click the 'Print' or 'Download PNG' button to generate a branded invoice."
  },
  {
    question: "How do I change my admin password?",
    answer: "Go to Settings > Security to update your password. Currently, demo mode uses a hardcoded password, but this will be connected to your WordPress admin account."
  }
];

export default function HelpCenter() {
  const [openFaq, setOpenFaq] = useState(0);

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text-primary tracking-tight">Help Center</h1>
          <p className="text-sm text-text-secondary mt-1">Get support and learn how to use the dashboard</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content - FAQs */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-card shadow-sm border border-border p-6">
            <h2 className="text-lg font-bold text-text-primary mb-6 flex items-center gap-2">
              <FileQuestion className="w-5 h-5 text-primary-500" />
              Frequently Asked Questions
            </h2>
            
            <div className="space-y-4">
              {faqs.map((faq, index) => (
                <div 
                  key={index} 
                  className={`border rounded-xl transition-colors ${openFaq === index ? 'border-primary-200 bg-primary-50/30' : 'border-border bg-white hover:border-gray-300'}`}
                >
                  <button
                    className="w-full text-left px-5 py-4 font-semibold text-text-primary flex justify-between items-center"
                    onClick={() => setOpenFaq(openFaq === index ? -1 : index)}
                  >
                    {faq.question}
                    <span className={`text-xl transition-transform ${openFaq === index ? 'rotate-45 text-primary-500' : 'text-gray-400'}`}>+</span>
                  </button>
                  {openFaq === index && (
                    <div className="px-5 pb-5 text-sm text-text-secondary leading-relaxed">
                      {faq.answer}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Sidebar - Contact & Resources */}
        <div className="space-y-6">
          {/* Contact Support */}
          <div className="bg-white rounded-card shadow-sm border border-border p-6">
            <h2 className="text-lg font-bold text-text-primary mb-4">Contact Support</h2>
            <p className="text-sm text-text-secondary mb-6">Need technical assistance? Our development team is here to help.</p>
            
            <div className="space-y-4">
              <a href="mailto:support@restomart.pk" className="flex items-center gap-3 p-3 rounded-xl border border-border hover:border-primary-300 hover:bg-primary-50 transition-colors group">
                <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center text-blue-500 group-hover:bg-blue-100 transition-colors">
                  <Mail className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-text-primary">Email Support</p>
                  <p className="text-xs text-text-secondary">support@restomart.pk</p>
                </div>
              </a>

              <a href="tel:03211655556" className="flex items-center gap-3 p-3 rounded-xl border border-border hover:border-primary-300 hover:bg-primary-50 transition-colors group">
                <div className="w-10 h-10 rounded-lg bg-green-50 flex items-center justify-center text-green-500 group-hover:bg-green-100 transition-colors">
                  <Phone className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-text-primary">Call Us</p>
                  <p className="text-xs text-text-secondary">0321-1655556 • 0321-0655555</p>
                </div>
              </a>

              <button className="w-full flex items-center gap-3 p-3 rounded-xl border border-border hover:border-primary-300 hover:bg-primary-50 transition-colors group text-left">
                <div className="w-10 h-10 rounded-lg bg-purple-50 flex items-center justify-center text-purple-500 group-hover:bg-purple-100 transition-colors">
                  <MessageCircle className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-text-primary">Live Chat</p>
                  <p className="text-xs text-text-secondary">Available 9 AM - 5 PM</p>
                </div>
              </button>
            </div>
          </div>

          {/* Quick Links */}
          <div className="bg-white rounded-card shadow-sm border border-border p-6">
            <h2 className="text-lg font-bold text-text-primary mb-4">Quick Links</h2>
            <div className="space-y-3">
              <a href="https://restomart.pk/wp-admin" target="_blank" rel="noreferrer" className="flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 text-sm font-medium text-text-secondary hover:text-primary-500 transition-colors">
                WordPress Dashboard
                <ExternalLink className="w-4 h-4" />
              </a>
              <a href="https://restomart.pk" target="_blank" rel="noreferrer" className="flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 text-sm font-medium text-text-secondary hover:text-primary-500 transition-colors">
                Visit Storefront
                <ExternalLink className="w-4 h-4" />
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
