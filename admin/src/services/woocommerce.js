import axios from 'axios';

const BASE_URL = 'https://restomart.pk/wp-json/wc/v3';
const CONSUMER_KEY = 'ck_823aab9b5cab2eba66e6751f4f5c6502fe306566';
const CONSUMER_SECRET = 'cs_00ed3a9685b5697cb50e61b70a004f4f36e2b99f';

// Set up an Axios instance with base URL and auth params
const api = axios.create({
  baseURL: BASE_URL,
  params: {
    consumer_key: CONSUMER_KEY,
    consumer_secret: CONSUMER_SECRET,
  },
});

export const getProducts = async (page = 1, perPage = 100) => {
  try {
    const response = await api.get('/products', {
      params: {
        page,
        per_page: perPage,
      },
    });
    
    // Map WooCommerce products to the format expected by the dashboard
    return response.data.map(p => {
      let status = 'in_stock';
      if (p.stock_quantity === 0) status = 'out_of_stock';
      else if (p.stock_quantity > 0 && p.stock_quantity <= 15) status = 'low_stock';
      else if (p.stock_quantity > 500) status = 'overflow';
      
      return {
        id: p.id, // numeric ID from WC
        productId: `WC-${p.id}`,
        name: p.name,
        brand: p.attributes?.find(a => a.name.toLowerCase() === 'brand')?.options?.[0] || 'Unknown',
        category: p.categories?.[0]?.name || 'Uncategorized',
        price: parseFloat(p.price || 0),
        stock: p.stock_quantity ?? (p.stock_status === 'instock' ? 100 : 0),
        status: status,
        image: p.images?.[0]?.src || '',
      };
    });
  } catch (error) {
    console.error('Error fetching WooCommerce products:', error);
    throw error;
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
    return response.data.map(c => c.name);
  } catch (error) {
    console.error('Error fetching categories:', error);
    throw error;
  }
};

export const getOrders = async (page = 1, perPage = 100) => {
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
    console.error('Error fetching orders:', error);
    throw error;
  }
};

export const getCustomers = async (page = 1, perPage = 100) => {
  try {
    const response = await api.get('/customers', {
      params: { page, per_page: perPage, role: 'all' },
    });
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
    console.error('Error fetching customers:', error);
    throw error;
  }
};

export const updateOrder = async (id, status) => {
  try {
    await api.put(`/orders/${id}`, { status });
  } catch (e) {
    console.error('WC Order Update Error:', e);
  }
};
