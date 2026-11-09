import { useState } from 'react';
import { Mail, Phone, MessageCircle, ExternalLink, Search, FileQuestion, HelpCircle, ArrowRight } from 'lucide-react';

const faqs = [
  {
    question: "How do I add a new product?",
    answer: "Go to the Products tab from the sidebar and click the 'Create Product' button in the top right corner. Fill out the product details and click Save. It will instantly sync with your WooCommerce store."
  },
  {
    question: "How are orders synced from the app?",
    answer: "Orders placed in the mobile app are instantly synced to this dashboard via WooCommerce REST API and Cloud Firestore. You will see them appear live in the Orders tab with a notification alert."
  },
  {
    question: "Can I print invoices for completed orders?",
    answer: "Yes. Open any order in the Orders tab or go to the Invoices tab. Click the 'Print' or 'Download PNG/PDF' button to generate a branded invoice."
  },
  {
    question: "How do I change my admin password?",
    answer: "Go to Settings to update your admin credentials and password."
  }
];

export default function HelpCenter() {
  const [openFaq, setOpenFaq] = useState(0);
  const [searchQuery, setSearchQuery] = useState('');

  const filteredFaqs = faqs.filter(f => 
    f.question.toLowerCase().includes(searchQuery.toLowerCase()) || 
    f.answer.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-8 animate-in fade-in duration-500 pb-10">
      {/* Sleek Hero Header */}
      <div className="relative overflow-hidden bg-slate-900 text-white rounded-3xl p-8 sm:p-10 shadow-xl border border-slate-800">
        <div className="relative z-10 max-w-2xl">
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-primary-500/20 text-primary-300 border border-primary-500/30 mb-3">
            <HelpCircle className="w-3.5 h-3.5" /> RestoMart Support Portal
          </span>
          <h1 className="text-3xl font-extrabold tracking-tight text-white mb-2">
            Help Center
          </h1>
          <p className="text-sm text-slate-300 mb-6 leading-relaxed">
            Get technical assistance and learn how to manage your RestoMart store dashboard.
          </p>

          {/* Search Box */}
          <div className="relative max-w-xl">
            <input
              type="text"
              placeholder="Search help topics or questions..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-5 pr-12 py-3 bg-white text-slate-900 placeholder-slate-400 rounded-2xl text-sm font-medium focus:outline-none focus:ring-2 focus:ring-primary-500 shadow-md"
            />
            <Search className="w-4 h-4 absolute right-4 top-1/2 -translate-y-1/2 text-slate-400" />
          </div>
        </div>

        <div className="absolute -right-10 -bottom-10 w-80 h-80 bg-primary-500/10 rounded-full blur-3xl pointer-events-none" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* FAQs Section */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-2xl shadow-sm border border-border p-6">
            <h2 className="text-base font-bold text-text-primary mb-6 flex items-center gap-2">
              <FileQuestion className="w-5 h-5 text-primary-500" />
              Frequently Asked Questions
            </h2>
            
            <div className="space-y-3">
              {filteredFaqs.map((faq, index) => (
                <div 
                  key={index} 
                  className={`border rounded-xl transition-all ${
                    openFaq === index ? 'border-primary-300 bg-primary-50/20' : 'border-border bg-white hover:border-gray-300'
                  }`}
                >
                  <button
                    className="w-full text-left px-5 py-4 font-semibold text-sm text-text-primary flex justify-between items-center"
                    onClick={() => setOpenFaq(openFaq === index ? -1 : index)}
                  >
                    {faq.question}
                    <span className={`text-lg font-bold transition-transform ${openFaq === index ? 'rotate-45 text-primary-500' : 'text-gray-400'}`}>+</span>
                  </button>
                  {openFaq === index && (
                    <div className="px-5 pb-5 text-xs text-text-secondary leading-relaxed border-t border-border/50 pt-3">
                      {faq.answer}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Sidebar - Contact & Quick Links */}
        <div className="space-y-6">
          {/* Contact Support */}
          <div className="bg-white rounded-2xl shadow-sm border border-border p-6">
            <h2 className="text-base font-bold text-text-primary mb-2">Contact Support</h2>
            <p className="text-xs text-text-secondary mb-5 leading-relaxed">Need assistance? Our support team is here to help.</p>
            
            <div className="space-y-3">
              <a href="mailto:support@restomart.pk" className="flex items-center gap-3 p-3 rounded-xl border border-border hover:border-primary-300 hover:bg-primary-50/50 transition-colors group">
                <div className="w-9 h-9 rounded-xl bg-blue-50 flex items-center justify-center text-blue-500 group-hover:bg-blue-100 transition-colors">
                  <Mail className="w-4 h-4" />
                </div>
                <div>
                  <p className="text-xs font-bold text-text-primary">Email Support</p>
                  <p className="text-[11px] text-text-secondary">support@restomart.pk</p>
                </div>
              </a>

              <a href="tel:03211655556" className="flex items-center gap-3 p-3 rounded-xl border border-border hover:border-primary-300 hover:bg-primary-50/50 transition-colors group">
                <div className="w-9 h-9 rounded-xl bg-emerald-50 flex items-center justify-center text-emerald-600 group-hover:bg-emerald-100 transition-colors">
                  <Phone className="w-4 h-4" />
                </div>
                <div>
                  <p className="text-xs font-bold text-text-primary">Call Us</p>
                  <p className="text-[11px] text-text-secondary">0321-1655556 • 0321-0655555</p>
                </div>
              </a>

              <div className="flex items-center gap-3 p-3 rounded-xl border border-border hover:border-primary-300 hover:bg-primary-50/50 transition-colors group cursor-pointer">
                <div className="w-9 h-9 rounded-xl bg-purple-50 flex items-center justify-center text-purple-600 group-hover:bg-purple-100 transition-colors">
                  <MessageCircle className="w-4 h-4" />
                </div>
                <div>
                  <p className="text-xs font-bold text-text-primary">Live Chat</p>
                  <p className="text-[11px] text-text-secondary">Available 9 AM - 5 PM</p>
                </div>
              </div>
            </div>
          </div>

          {/* Quick Links */}
          <div className="bg-white rounded-2xl shadow-sm border border-border p-6">
            <h2 className="text-base font-bold text-text-primary mb-3">Quick Links</h2>
            <div className="space-y-2">
              <a href="https://restomart.pk/wp-admin" target="_blank" rel="noreferrer" className="flex items-center justify-between p-3 rounded-xl hover:bg-slate-50 text-xs font-semibold text-text-secondary hover:text-primary-600 transition-colors border border-border">
                WordPress Dashboard
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
              <a href="https://restomart.pk" target="_blank" rel="noreferrer" className="flex items-center justify-between p-3 rounded-xl hover:bg-slate-50 text-xs font-semibold text-text-secondary hover:text-primary-600 transition-colors border border-border">
                Visit Storefront
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
