'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { 
  getB2BProducts, 
  addB2BProduct,
  deleteB2BProduct,
  createB2BOrder,
  B2BProduct,
  PARTNER_CATEGORIES,
  WithId 
} from '@/lib/firestore';
import { 
  Store, 
  Plus, 
  Trash2,
  Search,
  Package,
  ShoppingCart,
  Tag,
  Boxes,
  ArrowRight
} from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { vi } from 'date-fns/locale';

export default function MarketplacePage() {
  const { user } = useAuth();
  const [products, setProducts] = useState<WithId<B2BProduct>[]>([]);
  const [myProducts, setMyProducts] = useState<WithId<B2BProduct>[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [showOrderModal, setShowOrderModal] = useState<WithId<B2BProduct> | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [orderQuantity, setOrderQuantity] = useState('');
  const [activeTab, setActiveTab] = useState<'all' | 'my'>('all');
  
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    wholesalePrice: '',
    retailPrice: '',
    minOrderQuantity: '',
    stock: '',
    category: '',
  });

  useEffect(() => {
    loadProducts();
  }, [selectedCategory, activeTab]);

  const loadProducts = async () => {
    try {
      if (activeTab === 'my' && user?.uid) {
        const data = await getB2BProducts(user.uid);
        setMyProducts(data);
      } else {
        const cat = selectedCategory === 'all' ? undefined : selectedCategory;
        const data = await getB2BProducts(undefined, cat);
        // Filter out user's own products
        setProducts(data.filter(p => p.sellerId !== user?.uid));
      }
    } catch (error) {
      console.error('Error loading products:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAddProduct = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user?.uid) return;

    try {
      await addB2BProduct(user.uid, user.storeName || 'Cửa hàng', {
        name: formData.name,
        description: formData.description,
        wholesalePrice: parseFloat(formData.wholesalePrice),
        retailPrice: parseFloat(formData.retailPrice),
        minOrderQuantity: parseInt(formData.minOrderQuantity),
        moq: parseInt(formData.minOrderQuantity),
        stock: parseInt(formData.stock),
        category: formData.category,
        images: [],
      });

      setShowAddModal(false);
      setFormData({
        name: '',
        description: '',
        wholesalePrice: '',
        retailPrice: '',
        minOrderQuantity: '',
        stock: '',
        category: '',
      });
      loadProducts();
    } catch (error) {
      console.error('Error adding product:', error);
    }
  };

  const handleOrder = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!showOrderModal || !user?.uid || !orderQuantity) return;

    const qty = parseInt(orderQuantity);
    if (qty < showOrderModal.minOrderQuantity) {
      alert(`Số lượng tối thiểu là ${showOrderModal.minOrderQuantity}`);
      return;
    }

    try {
      await createB2BOrder(
        user.uid,
        user.storeName || 'Cửa hàng',
        showOrderModal.sellerId,
        showOrderModal.sellerStoreName,
        [{
          productId: showOrderModal.id!,
          productName: showOrderModal.name,
          quantity: qty,
          unitPrice: showOrderModal.wholesalePrice,
          total: qty * showOrderModal.wholesalePrice,
        }],
        '', // shipping address - can be added later
        '' // note
      );

      alert('Đặt hàng thành công!');
      setShowOrderModal(null);
      setOrderQuantity('');
    } catch (error) {
      console.error('Error creating order:', error);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const displayedProducts = activeTab === 'my' ? myProducts : products;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-violet-500 to-fuchsia-600 flex items-center justify-center">
            <Store className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-emerald-900">B2B Marketplace</h1>
            <p className="text-emerald-600/70 text-sm">Mua bán sỉ giữa các đối tác</p>
          </div>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="px-4 py-2 bg-gradient-to-r from-violet-600 to-fuchsia-600 text-white rounded-lg font-medium transition-all hover:opacity-90 flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          Đăng bán sỉ
        </button>
      </div>

      {/* Tabs */}
      <div className="flex gap-2">
        <button
          onClick={() => setActiveTab('all')}
          className={`px-4 py-2 rounded-lg font-medium transition-colors ${
            activeTab === 'all'
              ? 'bg-violet-600 text-white'
              : 'bg-white text-violet-700 hover:bg-violet-50 border border-violet-200'
          }`}
        >
          Tất cả sản phẩm
        </button>
        <button
          onClick={() => setActiveTab('my')}
          className={`px-4 py-2 rounded-lg font-medium transition-colors ${
            activeTab === 'my'
              ? 'bg-violet-600 text-white'
              : 'bg-white text-violet-700 hover:bg-violet-50 border border-violet-200'
          }`}
        >
          Sản phẩm của tôi
        </button>
      </div>

      {/* Category Filter - only show in 'all' tab */}
      {activeTab === 'all' && (
        <div className="flex flex-wrap gap-2">
          <button
            onClick={() => setSelectedCategory('all')}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              selectedCategory === 'all'
                ? 'bg-emerald-600 text-white'
                : 'bg-white text-emerald-700 hover:bg-emerald-50 border border-emerald-200'
            }`}
          >
            Tất cả
          </button>
          {Object.entries(PARTNER_CATEGORIES).map(([key, label]) => (
            <button
              key={key}
              onClick={() => setSelectedCategory(key)}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                selectedCategory === key
                  ? 'bg-emerald-600 text-white'
                  : 'bg-white text-emerald-700 hover:bg-emerald-50 border border-emerald-200'
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      )}

      {/* Products Grid */}
      {loading ? (
        <div className="p-8 text-center">
          <div className="w-8 h-8 border-4 border-emerald-200 border-t-emerald-600 rounded-full animate-spin mx-auto" />
        </div>
      ) : displayedProducts.length === 0 ? (
        <div className="p-8 text-center bg-white rounded-xl border border-emerald-100">
          <Store className="w-12 h-12 text-emerald-300 mx-auto mb-3" />
          <p className="text-emerald-600">
            {activeTab === 'my' ? 'Bạn chưa đăng sản phẩm nào' : 'Chưa có sản phẩm nào'}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {displayedProducts.map((product) => (
            <div key={product.id} className="bg-white rounded-xl border border-emerald-100 shadow-sm overflow-hidden hover:shadow-md transition-shadow">
              {/* Product Image Placeholder */}
              <div className="h-40 bg-gradient-to-br from-violet-100 to-fuchsia-100 flex items-center justify-center">
                <Package className="w-16 h-16 text-violet-300" />
              </div>

              <div className="p-4">
                {/* Category */}
                <span className="px-2 py-1 bg-emerald-50 text-emerald-600 text-xs rounded-full">
                  {PARTNER_CATEGORIES[product.category as keyof typeof PARTNER_CATEGORIES] || product.category}
                </span>

                {/* Name & Seller */}
                <h3 className="font-bold text-emerald-900 mt-2 line-clamp-2">{product.name}</h3>
                <p className="text-sm text-emerald-600 flex items-center gap-1 mt-1">
                  <Store className="w-3 h-3" />
                  {product.sellerStoreName}
                </p>

                {/* Prices */}
                <div className="mt-3 space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-emerald-600">Giá sỉ:</span>
                    <span className="font-bold text-violet-600">{formatCurrency(product.wholesalePrice)}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-emerald-600">Giá lẻ tham khảo:</span>
                    <span className="text-sm text-emerald-500 line-through">{formatCurrency(product.retailPrice)}</span>
                  </div>
                </div>

                {/* MOQ & Stock */}
                <div className="flex items-center gap-4 mt-3 text-sm text-emerald-500">
                  <span className="flex items-center gap-1">
                    <Boxes className="w-4 h-4" />
                    Tối thiểu: {product.minOrderQuantity}
                  </span>
                  <span className="flex items-center gap-1">
                    <Tag className="w-4 h-4" />
                    Tồn: {product.stock}
                  </span>
                </div>

                {/* Actions */}
                <div className="flex gap-2 mt-4">
                  {activeTab === 'all' ? (
                    <button
                      onClick={() => setShowOrderModal(product)}
                      className="flex-1 py-2 bg-violet-600 text-white rounded-lg font-medium hover:bg-violet-700 flex items-center justify-center gap-2"
                    >
                      <ShoppingCart className="w-4 h-4" />
                      Đặt hàng
                    </button>
                  ) : (
                    <button
                      onClick={() => deleteB2BProduct(product.id!).then(loadProducts)}
                      className="flex-1 py-2 border border-red-200 text-red-600 rounded-lg font-medium hover:bg-red-50 flex items-center justify-center gap-2"
                    >
                      <Trash2 className="w-4 h-4" />
                      Xóa
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Add Product Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white rounded-xl shadow-xl w-full max-lg max-h-[90vh] overflow-y-auto">
            <div className="p-4 border-b border-emerald-100">
              <h3 className="font-semibold text-emerald-900">Đăng bán sản phẩm sỉ</h3>
            </div>
            <form onSubmit={handleAddProduct} className="p-4 space-y-4">
              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Tên sản phẩm</label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Danh mục</label>
                <select
                  value={formData.category}
                  onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  required
                >
                  <option value="">Chọn danh mục</option>
                  {Object.entries(PARTNER_CATEGORIES).map(([key, label]) => (
                    <option key={key} value={key}>{label}</option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-emerald-700 mb-1">Giá sỉ</label>
                  <input
                    type="number"
                    value={formData.wholesalePrice}
                    onChange={(e) => setFormData({ ...formData, wholesalePrice: e.target.value })}
                    className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                    required
                    min="0"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-emerald-700 mb-1">Giá lẻ tham khảo</label>
                  <input
                    type="number"
                    value={formData.retailPrice}
                    onChange={(e) => setFormData({ ...formData, retailPrice: e.target.value })}
                    className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                    required
                    min="0"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-emerald-700 mb-1">Số lượng tối thiểu (MOQ)</label>
                  <input
                    type="number"
                    value={formData.minOrderQuantity}
                    onChange={(e) => setFormData({ ...formData, minOrderQuantity: e.target.value })}
                    className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                    required
                    min="1"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-emerald-700 mb-1">Tồn kho</label>
                  <input
                    type="number"
                    value={formData.stock}
                    onChange={(e) => setFormData({ ...formData, stock: e.target.value })}
                    className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                    required
                    min="0"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Mô tả</label>
                <textarea
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500 h-24 resize-none"
                  placeholder="Mô tả chi tiết sản phẩm..."
                />
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="flex-1 px-4 py-2 border border-emerald-200 text-emerald-700 rounded-lg hover:bg-emerald-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-violet-600 text-white rounded-lg hover:bg-violet-700"
                >
                  Đăng bán
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Order Modal */}
      {showOrderModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md">
            <div className="p-4 border-b border-emerald-100">
              <h3 className="font-semibold text-emerald-900">Đặt hàng sỉ</h3>
            </div>
            <form onSubmit={handleOrder} className="p-4 space-y-4">
              <div className="bg-emerald-50 rounded-lg p-3">
                <p className="font-medium text-emerald-900">{showOrderModal.name}</p>
                <p className="text-sm text-emerald-600">{showOrderModal.sellerStoreName}</p>
                <p className="text-lg font-bold text-violet-600 mt-1">
                  {formatCurrency(showOrderModal.wholesalePrice)} / sản phẩm
                </p>
                <p className="text-sm text-emerald-500">
                  Tối thiểu: {showOrderModal.minOrderQuantity} sản phẩm
                </p>
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">
                  Số lượng đặt
                </label>
                <input
                  type="number"
                  value={orderQuantity}
                  onChange={(e) => setOrderQuantity(e.target.value)}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  placeholder={`Tối thiểu ${showOrderModal.minOrderQuantity}`}
                  required
                  min={showOrderModal.minOrderQuantity}
                />
              </div>

              {orderQuantity && (
                <div className="bg-violet-50 rounded-lg p-3">
                  <p className="text-sm text-violet-600">Tổng tiền:</p>
                  <p className="text-2xl font-bold text-violet-700">
                    {formatCurrency(parseInt(orderQuantity) * showOrderModal.wholesalePrice)}
                  </p>
                </div>
              )}

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowOrderModal(null)}
                  className="flex-1 px-4 py-2 border border-emerald-200 text-emerald-700 rounded-lg hover:bg-emerald-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-violet-600 text-white rounded-lg hover:bg-violet-700"
                >
                  Xác nhận đặt hàng
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
