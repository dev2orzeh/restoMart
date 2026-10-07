import axios from 'axios';
import { mockProducts, mockCategories, mockCustomers } from '../data/mockData';

// Use local dev proxy to bypass browser CORS when on localhost
const BASE_URL = typeof window !== 'undefined' && window.location.hostname === 'localhost'
  ? '/api-wc'
  : 'https://restomart.pk/wp-json/wc/v3';

const CONSUMER_KEY = 'ck_823aab9b5cab2eba66e6751f4f5c6502fe306566';
const CONSUMER_SECRET = 'cs_00ed3a9685b5697cb50e61b70a004f4f36e2b99f';

// Set up Axios instance
const api = axios.create({
  baseURL: BASE_URL,
  timeout: 15000,
  params: {
    consumer_key: CONSUMER_KEY,
    consumer_secret: CONSUMER_SECRET,
  },
});

export const getProducts = async () => {
  try {
    const firstRes = await api.get('/products', {
      params: { page: 1, per_page: 100 },
    });

    if (!firstRes.data || !Array.isArray(firstRes.data) || firstRes.data.length === 0) {
      return mockProducts;
    }

    let rawProducts = [...firstRes.data];
    const totalPages = parseInt(firstRes.headers['x-wp-totalpages'] || '1', 10);

    // Fetch remaining pages in parallel if more than 1 page
    if (totalPages > 1) {
      const promises = [];
      for (let p = 2; p <= Math.min(totalPages, 10); p++) {
        promises.push(api.get('/products', { params: { page: p, per_page: 100 } }));
      }
      const pageResponses = await Promise.all(promises);
      pageResponses.forEach((res) => {
        if (Array.isArray(res.data)) {
          rawProducts = rawProducts.concat(res.data);
        }
      });
    }

    return rawProducts.map((p) => {
      let status = 'in_stock';
      if (p.stock_quantity === 0) status = 'out_of_stock';
      else if (p.stock_quantity > 0 && p.stock_quantity <= 15) status = 'low_stock';
      else if (p.stock_quantity > 500) status = 'overflow';

      return {
        id: p.id,
        productId: `WC-${p.id}`,
        name: p.name,
        brand: p.attributes?.find((a) => a.name.toLowerCase() === 'brand')?.options?.[0] || 'RestoMart',
        category: p.categories?.[0]?.name || 'Uncategorized',
        price: parseFloat(p.price || 0),
        stock: p.stock_quantity ?? (p.stock_status === 'instock' ? 100 : 0),
        status: status,
        image: p.images?.[0]?.src || '',
        description: p.description?.replace(/<[^>]*>?/gm, '') || p.short_description?.replace(/<[^>]*>?/gm, '') || '',
      };
    });
  } catch (error) {
    console.warn('WooCommerce products fetch error. Using fallback products:', error.message);
    return mockProducts;
  }
};

export const updateProduct = async (id, updateData) => {
  try {
    const response = await api.put(`/products/${id}`, updateData);
    return response.data;
  } catch (error) {
    console.error(`Error updating product ${id}:`, error);
    throw error;
  }
};

export const createProduct = async (productData) => {
  try {
    const response = await api.post('/products', productData);
    return response.data;
  } catch (error) {
    console.error('Error creating product:', error);
    throw error;
  }
};

export const getCategories = async () => {
  try {
    const response = await api.get('/products/categories', {
      params: { per_page: 100 },
    });
    if (!response.data || !Array.isArray(response.data) || response.data.length === 0) {
      return mockCategories;
    }
    return response.data.map(c => c.name);
  } catch (error) {
    console.warn('WooCommerce categories fetch error:', error.message);
    return mockCategories;
  }
};

export const getOrders = async (page = 1, perPage = 50) => {
  try {
    const response = await api.get('/orders', {
      params: { page, per_page: perPage },
    });
    return response.data.map(o => ({
      id: o.id.toString(),
      customer: `${o.billing.first_name} ${o.billing.last_name}`,
      date: new Date(o.date_created).toLocaleDateString(),
      total: parseFloat(o.total),
      status: o.status,
      items: o.line_items.map(item => ({
        name: item.name,
        qty: item.quantity,
        price: parseFloat(item.price || 0)
      })),
      paymentMethod: o.payment_method_title || 'Unknown',
      email: o.billing.email,
      phone: o.billing.phone,
      address: `${o.billing.address_1}, ${o.billing.city}`,
    }));
  } catch (error) {
    console.warn('WooCommerce orders fetch error:', error.message);
    return [];
  }
};

export const getCustomers = async (page = 1, perPage = 50) => {
  try {
    const response = await api.get('/customers', {
      params: { page, per_page: perPage, role: 'all' },
    });
    if (!response.data || !Array.isArray(response.data) || response.data.length === 0) {
      return mockCustomers;
    }
    return response.data.map(c => ({
      id: c.id.toString(),
      name: `${c.first_name} ${c.last_name}`.trim() || c.username,
      email: c.email,
      phone: c.billing?.phone || 'N/A',
      totalOrders: c.orders_count || 0,
      totalSpent: parseFloat(c.total_spent || 0),
      lastOrder: 'N/A',
      avatar: c.avatar_url,
    }));
  } catch (error) {
    console.warn('WooCommerce customers fetch error:', error.message);
    return mockCustomers;
  }
};

export const updateOrder = async (id, status) => {
  try {
    await api.put(`/orders/${id}`, { status });
  } catch (e) {
    console.error('WC Order Update Error:', e);
  }
};
