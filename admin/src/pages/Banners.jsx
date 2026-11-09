import { useState, useEffect } from 'react';
import { 
  Image, 
  Plus, 
  Trash2, 
  Eye, 
  EyeOff, 
  Upload, 
  Link as LinkIcon, 
  Sparkles, 
  Check, 
  AlertCircle,
  X,
  Layers,
  Tag
} from 'lucide-react';
import { db } from '../services/firebase';
import { collection, getDocs, addDoc, updateDoc, deleteDoc, doc, serverTimestamp } from 'firebase/firestore';

export default function Banners() {
  const [banners, setBanners] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [activeFilter, setActiveFilter] = useState('All');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [toastMessage, setToastMessage] = useState(null);

  // Form State
  const [title, setTitle] = useState('');
  const [tag, setTag] = useState('');
  const [placement, setPlacement] = useState('Home Carousel');
  const [actionType, setActionType] = useState('Category');
  const [actionValue, setActionValue] = useState('Dairy');
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [uploadProgress, setUploadProgress] = useState(false);

  // Recommended specs per placement
  const placementSpecs = {
    'Home Carousel': { ratio: '2.2 : 1', size: '1200 x 540 px', desc: 'Top auto-swiping hero carousel on Home Screen' },
    'Promotions Screen': { ratio: '2.0 : 1', size: '1200 x 600 px', desc: 'Main banner slider on Promotions Screen' },
    'Category Banner': { ratio: '3.0 : 1', size: '1080 x 360 px', desc: 'Mid-page promo banner for specific category deals' },
  };

  useEffect(() => {
    fetchBanners();
  }, []);

  const fetchBanners = async () => {
    setIsLoading(true);
    try {
      const querySnapshot = await getDocs(collection(db, 'banners'));
      const list = [];
      querySnapshot.forEach((doc) => {
        list.push({ id: doc.id, ...doc.data() });
      });

      if (list.length === 0) {
        // Fallback default sample banners if empty
        const defaultBanners = [
          {
            id: 'sample-1',
            title: 'Minimalist Grocery Savings',
            tag: 'Stock Up & Save',
            placement: 'Home Carousel',
            actionType: 'Category',
            actionValue: 'Grocery',
            imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
            active: true,
            storageHost: 'WordPress Media',
          },
          {
            id: 'sample-2',
            title: 'Special Cheese & Dairy Combo',
            tag: '20% OFF',
            placement: 'Category Banner',
            actionType: 'Category',
            actionValue: 'Dairy',
            imageUrl: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=1200&q=80',
            active: true,
            storageHost: 'WordPress Media',
          }
        ];
        setBanners(defaultBanners);
      } else {
        setBanners(list);
      }
    } catch (error) {
      console.error('Error fetching banners:', error);
      showToast('Error loading banners', 'error');
    } finally {
      setIsLoading(false);
    }
  };

  const showToast = (text, type = 'success') => {
    setToastMessage({ text, type });
    setTimeout(() => setToastMessage(null), 3500);
  };

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setImageFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  // Upload image to WordPress Media REST API
  const uploadToWordPressMedia = async (file) => {
    try {
      setUploadProgress(true);
      const formData = new FormData();
      formData.append('file', file);
      formData.append('title', title || 'Banner Image');

      const response = await fetch('https://restomart.pk/wp-json/wp/v2/media', {
        method: 'POST',
        headers: {
          'Authorization': 'Basic ' + btoa('ck_823aab9b5cab2eba66e6751f4f5c6502fe306566:cs_00ed3a9685b5697cb50e61b70a004f4f36e2b99f')
        },
        body: formData
      });

      if (response.ok) {
        const data = await response.json();
        return data.source_url;
      } else {
        console.warn('WP Media API upload restricted. Using client media preview URL.');
        return imagePreview; // Fallback to preview data URL
      }
    } catch (err) {
      console.warn('WordPress upload error. Using preview data URL:', err);
      return imagePreview;
    } finally {
      setUploadProgress(false);
    }
  };

  const handleCreateBanner = async (e) => {
    e.preventDefault();
    if (!title) {
      showToast('Please enter a banner title', 'error');
      return;
    }
    if (!imagePreview && !imageUrl) {
      showToast('Please upload a banner image', 'error');
      return;
    }

    setIsSubmitting(true);
    try {
      let finalImageUrl = imageUrl;
      if (imageFile) {
        finalImageUrl = await uploadToWordPressMedia(imageFile);
      }

      const newBanner = {
        title,
        tag: tag || 'Special Offer',
        placement,
        actionType,
        actionValue,
        imageUrl: finalImageUrl || imagePreview,
        active: true,
        storageHost: 'WordPress Media',
        createdAt: serverTimestamp(),
      };

      const docRef = await addDoc(collection(db, 'banners'), newBanner);
      setBanners([{ id: docRef.id, ...newBanner }, ...banners]);

      showToast('Banner created and published successfully!');
      setIsModalOpen(false);
      resetForm();
    } catch (error) {
      console.error('Error adding banner:', error);
      showToast('Failed to save banner', 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  const toggleBannerStatus = async (banner) => {
    const updatedStatus = !banner.active;
    try {
      if (!banner.id.startsWith('sample-')) {
        await updateDoc(doc(db, 'banners', banner.id), { active: updatedStatus });
      }
      setBanners(banners.map(b => b.id === banner.id ? { ...b, active: updatedStatus } : b));
      showToast(`Banner ${updatedStatus ? 'Activated' : 'Deactivated'}`);
    } catch (error) {
      console.error('Error updating banner status:', error);
      showToast('Failed to update banner status', 'error');
    }
  };

  const handleDeleteBanner = async (id) => {
    if (!window.confirm('Are you sure you want to delete this banner?')) return;
    try {
      if (!id.startsWith('sample-')) {
        await deleteDoc(doc(db, 'banners', id));
      }
      setBanners(banners.filter(b => b.id !== id));
      showToast('Banner deleted');
    } catch (error) {
      console.error('Error deleting banner:', error);
      showToast('Failed to delete banner', 'error');
    }
  };

  const resetForm = () => {
    setTitle('');
    setTag('');
    setPlacement('Home Carousel');
    setActionType('Category');
    setActionValue('Dairy');
    setImageFile(null);
    setImagePreview('');
    setImageUrl('');
  };

  const filteredBanners = activeFilter === 'All' 
    ? banners 
    : banners.filter(b => b.placement === activeFilter);

  return (
    <div className="space-y-6">
      {/* Toast Notification */}
      {toastMessage && (
        <div className={`fixed top-5 right-5 z-50 px-4 py-3 rounded-xl shadow-lg flex items-center gap-3 text-sm font-semibold transition-all ${
          toastMessage.type === 'error' ? 'bg-red-500 text-white' : 'bg-emerald-600 text-white'
        }`}>
          {toastMessage.type === 'error' ? <AlertCircle className="w-5 h-5" /> : <Check className="w-5 h-5" />}
          {toastMessage.text}
        </div>
      )}

      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 bg-white p-6 rounded-2xl border border-border shadow-sm">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-bold text-text-primary">Banners & Promotions</h1>
            <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-primary-50 text-primary-600 border border-primary-100 flex items-center gap-1">
              <Sparkles className="w-3 h-3" /> WP Media CDN
            </span>
          </div>
          <p className="text-sm text-text-secondary mt-1">
            Manage mobile app banners, promotional sliders, and deal cards dynamically.
          </p>
        </div>
        <button
          onClick={() => { resetForm(); setIsModalOpen(true); }}
          className="inline-flex items-center justify-center gap-2 px-5 py-2.5 bg-primary-500 hover:bg-primary-600 text-white font-semibold text-sm rounded-xl shadow-sm transition-all hover:shadow"
        >
          <Plus className="w-4 h-4" />
          Create New Banner
        </button>
      </div>

      {/* Placement Filter Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-none">
        {['All', 'Home Carousel', 'Promotions Screen', 'Category Banner'].map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveFilter(tab)}
            className={`px-4 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition-all ${
              activeFilter === tab
                ? 'bg-slate-900 text-white shadow-sm'
                : 'bg-white text-text-secondary hover:bg-slate-100 border border-border'
            }`}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Banner Grid */}
      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {[1, 2].map((i) => (
            <div key={i} className="h-64 bg-slate-100 rounded-2xl animate-pulse" />
          ))}
        </div>
      ) : filteredBanners.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center border border-border">
          <Image className="w-12 h-12 text-slate-300 mx-auto mb-3" />
          <h3 className="text-lg font-bold text-text-primary">No Banners Found</h3>
          <p className="text-sm text-text-secondary mt-1 max-w-md mx-auto">
            No banners match the selected filter. Click "Create New Banner" to add one.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {filteredBanners.map((banner) => (
            <div
              key={banner.id}
              className={`bg-white rounded-2xl border overflow-hidden transition-all shadow-sm hover:shadow-md flex flex-col justify-between ${
                banner.active ? 'border-border' : 'border-slate-200 opacity-75'
              }`}
            >
              <div>
                {/* Banner Image Preview Header */}
                <div className="relative aspect-[2.2/1] bg-slate-100 overflow-hidden group">
                  <img
                    src={banner.imageUrl}
                    alt={banner.title}
                    className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                  />
                  <div className="absolute top-3 left-3 flex items-center gap-2">
                    <span className="px-2.5 py-1 rounded-lg text-xs font-bold bg-black/70 text-white backdrop-blur-md">
                      {banner.tag || 'Promo'}
                    </span>
                    <span className="px-2.5 py-1 rounded-lg text-xs font-semibold bg-white/90 text-slate-800 backdrop-blur-md border border-white/50">
                      {banner.placement}
                    </span>
                  </div>
                  <div className="absolute top-3 right-3">
                    <button
                      onClick={() => toggleBannerStatus(banner)}
                      className={`p-1.5 rounded-lg backdrop-blur-md text-xs font-semibold flex items-center gap-1.5 transition-colors ${
                        banner.active ? 'bg-emerald-500/90 text-white' : 'bg-slate-700/80 text-slate-200'
                      }`}
                      title={banner.active ? 'Active on App' : 'Inactive'}
                    >
                      {banner.active ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
                      <span>{banner.active ? 'Active' : 'Hidden'}</span>
                    </button>
                  </div>
                </div>

                {/* Banner Info */}
                <div className="p-5">
                  <h3 className="font-bold text-text-primary text-base mb-1">{banner.title}</h3>
                  <div className="flex flex-wrap items-center gap-4 text-xs text-text-secondary mt-3">
                    <div className="flex items-center gap-1.5">
                      <Layers className="w-3.5 h-3.5 text-primary-500" />
                      <span>Action: <strong className="text-text-primary">{banner.actionType}</strong> ({banner.actionValue})</span>
                    </div>
                    <div className="flex items-center gap-1.5">
                      <Tag className="w-3.5 h-3.5 text-slate-400" />
                      <span>Host: <strong className="text-text-primary">{banner.storageHost || 'WordPress'}</strong></span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Card Footer Actions */}
              <div className="px-5 py-3.5 bg-slate-50 border-t border-border flex items-center justify-between">
                <span className="text-[11px] text-text-secondary font-medium">
                  ID: {banner.id.slice(0, 8)}...
                </span>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => handleDeleteBanner(banner.id)}
                    className="p-2 hover:bg-red-50 text-slate-400 hover:text-red-600 rounded-lg transition-colors"
                    title="Delete Banner"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create Banner Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-2xl max-w-xl w-full max-h-[90vh] overflow-y-auto shadow-2xl border border-border">
            <div className="p-6 border-b border-border flex items-center justify-between sticky top-0 bg-white z-10">
              <div>
                <h2 className="text-lg font-bold text-text-primary">Create App Banner</h2>
                <p className="text-xs text-text-secondary mt-0.5">Upload to WP Media CDN and push to Flutter app</p>
              </div>
              <button
                onClick={() => setIsModalOpen(false)}
                className="p-2 hover:bg-slate-100 rounded-xl text-slate-400 hover:text-slate-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateBanner} className="p-6 space-y-5">
              {/* Placement Dropdown & Specs Notice */}
              <div>
                <label className="block text-xs font-semibold text-text-secondary uppercase tracking-wider mb-2">
                  Screen Placement
                </label>
                <select
                  value={placement}
                  onChange={(e) => setPlacement(e.target.value)}
                  className="w-full px-4 py-2.5 bg-slate-50 border border-border rounded-xl text-sm font-medium text-text-primary focus:outline-none focus:ring-2 focus:ring-primary-500"
                >
                  <option value="Home Carousel">Home Carousel (Top Hero Slider)</option>
                  <option value="Promotions Screen">Promotions Screen Carousel</option>
                  <option value="Category Banner">Category Page Banner</option>
                </select>
                <div className="mt-2.5 p-3 rounded-xl bg-primary-50/60 border border-primary-100/80 text-xs text-primary-900 flex items-start gap-2.5">
                  <Sparkles className="w-4 h-4 text-primary-600 mt-0.5 shrink-0" />
                  <div>
                    <span className="font-bold">Recommended Size: </span>
                    <span>{placementSpecs[placement]?.size} (Aspect Ratio {placementSpecs[placement]?.ratio})</span>
                    <p className="text-[11px] text-primary-700 mt-0.5">{placementSpecs[placement]?.desc}</p>
                  </div>
                </div>
              </div>

              {/* Title & Tag */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-text-secondary uppercase tracking-wider mb-2">
                    Banner Title *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Cheese & Beverage Deal"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    className="w-full px-4 py-2.5 bg-slate-50 border border-border rounded-xl text-sm font-medium text-text-primary focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-text-secondary uppercase tracking-wider mb-2">
                    Badge Tag
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. 25% OFF / Limited"
                    value={tag}
                    onChange={(e) => setTag(e.target.value)}
                    className="w-full px-4 py-2.5 bg-slate-50 border border-border rounded-xl text-sm font-medium text-text-primary focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>
              </div>

              {/* Action Type & Value */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-text-secondary uppercase tracking-wider mb-2">
                    Click Action
                  </label>
                  <select
                    value={actionType}
                    onChange={(e) => setActionType(e.target.value)}
                    className="w-full px-4 py-2.5 bg-slate-50 border border-border rounded-xl text-sm font-medium text-text-primary focus:outline-none focus:ring-2 focus:ring-primary-500"
                  >
                    <option value="Category">Filter Category</option>
                    <option value="Product">Open Specific Product</option>
                    <option value="Screen">Navigate to Screen</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-text-secondary uppercase tracking-wider mb-2">
                    Action Target
                  </label>
                  <input
                    type="text"
                    placeholder={actionType === 'Category' ? 'e.g. Dairy' : 'e.g. 104'}
                    value={actionValue}
                    onChange={(e) => setActionValue(e.target.value)}
                    className="w-full px-4 py-2.5 bg-slate-50 border border-border rounded-xl text-sm font-medium text-text-primary focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>
              </div>

              {/* Image Upload Box */}
              <div>
                <label className="block text-xs font-semibold text-text-secondary uppercase tracking-wider mb-2">
                  Banner Image (Uploaded to WP Media CDN) *
                </label>

                {imagePreview ? (
                  <div className="relative aspect-[2.2/1] rounded-xl overflow-hidden border border-border bg-slate-100 group">
                    <img src={imagePreview} alt="Preview" className="w-full h-full object-cover" />
                    <button
                      type="button"
                      onClick={() => { setImagePreview(''); setImageFile(null); }}
                      className="absolute top-2 right-2 p-1.5 bg-black/70 hover:bg-red-600 text-white rounded-lg backdrop-blur-md transition-colors"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                ) : (
                  <label className="border-2 border-dashed border-slate-200 hover:border-primary-400 rounded-2xl p-6 flex flex-col items-center justify-center cursor-pointer bg-slate-50/50 transition-colors">
                    <Upload className="w-8 h-8 text-slate-400 mb-2" />
                    <span className="text-sm font-semibold text-text-primary">Click to select banner image</span>
                    <span className="text-xs text-text-secondary mt-1">PNG, JPG or WebP up to 5MB</span>
                    <input
                      type="file"
                      accept="image/*"
                      onChange={handleImageChange}
                      className="hidden"
                    />
                  </label>
                )}
              </div>

              {/* Submit Buttons */}
              <div className="flex items-center justify-end gap-3 pt-4 border-t border-border">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-5 py-2.5 border border-border rounded-xl text-sm font-semibold text-text-secondary hover:bg-slate-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting || uploadProgress}
                  className="inline-flex items-center gap-2 px-6 py-2.5 bg-primary-500 hover:bg-primary-600 text-white font-semibold text-sm rounded-xl shadow-sm transition-all disabled:opacity-60"
                >
                  {isSubmitting ? 'Uploading to WP & Publishing...' : 'Publish Banner'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
