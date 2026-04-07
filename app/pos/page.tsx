'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { getProducts, addOrder, Product, WithId } from '@/lib/firestore';
import { 
  Plus, 
  Minus, 
  Trash2, 
  ShoppingCart, 
  User, 
  X, 
  Search, 
  CreditCard,
  Banknote,
  Receipt,
  Calculator,
  Package,
  ArrowRight,
  CheckCircle
} from 'lucide-react';

interface CartItem extends Product, WithId {
  quantity: number;
}

interface CustomerInfo {
  name: string;
  phone: string;
}

export default function POSPage() {
  const { user } = useAuth();
  const [products, setProducts] = useState<(Product & WithId)[]>([]);
  const [filteredProducts, setFilteredProducts] = useState<(Product & WithId)[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [cart, setCart] = useState<CartItem[]>([]);
  const [customer, setCustomer] = useState<CustomerInfo>({ name: '', phone: '' });
  const [discount, setDiscount] = useState(0);
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'transfer' | 'debt'>('cash');
  const [paidAmount, setPaidAmount] = useState(0);
  const [note, setNote] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [showReceipt, setShowReceipt] = useState(false);
  const [lastOrder, setLastOrder] = useState<any>(null);

  const loadProducts = useCallback(async () => {
    if (!user?.storeId) return;
    try {
      const data = await getProducts(user.storeId);
      setProducts(data);
      setFilteredProducts(data);
    } catch (error) {
      console.error('Error loading products:', error);
    }
  }, [user]);

  useEffect(() => {
    loadProducts();
  }, [loadProducts]);

  useEffect(() => {
    if (searchQuery.trim() === '') {
      setFilteredProducts(products);
    } else {
      const query = searchQuery.toLowerCase();
      setFilteredProducts(
        products.filter((p) =>
          p.name.toLowerCase().includes(query) && p.stock > 0
        )
      );
    }
  }, [searchQuery, products]);

  const addToCart = (product: Product & WithId) => {
    if (product.stock <= 0) return;

    setCart((prev) => {
      const existing = prev.find((item) => item.id === product.id);
      if (existing) {
        if (existing.quantity >= product.stock) return prev;
        return prev.map((item) =>
          item.id === product.id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
      }
      return [...prev, { ...product, quantity: 1 }];
    });
  };

  const updateQuantity = (productId: string, delta: number) => {
    setCart((prev) =>
      prev
        .map((item) => {
          if (item.id === productId) {
            const newQuantity = item.quantity + delta;
            if (newQuantity <= 0) return null;
            if (newQuantity > item.stock) return item;
            return { ...item, quantity: newQuantity };
          }
          return item;
        })
        .filter(Boolean) as CartItem[]
    );
  };

  const removeFromCart = (productId: string) => {
    setCart((prev) => prev.filter((item) => item.id !== productId));
  };

  const clearCart = () => {
    setCart([]);
    setCustomer({ name: '', phone: '' });
    setDiscount(0);
    setPaymentMethod('cash');
    setPaidAmount(0);
    setNote('');
  };

  const subtotal = cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const finalAmount = Math.max(0, subtotal - discount);
  const debtAmount = Math.max(0, finalAmount - paidAmount);

  const handleSubmit = async () => {
    if (cart.length === 0) return;
    if (!user?.storeId) return;

    setSubmitting(true);
    try {
      const orderData = {
        customerId: null,
        customerName: customer.name || 'Khách lẻ',
        items: cart.map((item) => ({
          productId: item.id,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
          subtotal: item.price * item.quantity,
        })),
        totalAmount: subtotal,
        discount,
        finalAmount,
        paymentMethod,
        paidAmount,
        debtAmount,
        note,
        status: 'completed' as const,
      };

      const orderId = await addOrder(user.storeId, orderData);
      setLastOrder({ id: orderId, ...orderData });
      setShowReceipt(true);
      clearCart();
      await loadProducts();
    } catch (error) {
      alert('Lỗi tạo đơn hàng: ' + (error as Error).message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 -m-4 sm:-m-6 lg:-m-8 p-4 sm:p-6 lg:p-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Bán hàng POS</h1>
          <p className="text-slate-500 mt-1">Tạo đơn hàng nhanh chóng</p>
        </div>
        <div className="flex items-center gap-2 text-sm text-slate-500">
          <ShoppingCart className="w-4 h-4" />
          <span>{cart.length} sản phẩm</span>
        </div>
      </div>

      <div className="grid lg:grid-cols-3 gap-6">
        {/* Products Section */}
        <div className="lg:col-span-2 space-y-4">
          {/* Search */}
          <div className="bg-white rounded-xl border border-slate-200 p-1">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
              <input
                type="text"
                placeholder="Tìm sản phẩm theo tên..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-3 border-0 rounded-lg focus:outline-none focus:ring-2 focus:ring-violet-500 text-slate-900 placeholder-slate-400"
              />
            </div>
          </div>

          {/* Products Grid */}
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
            {filteredProducts.map((product) => (
              <button
                key={product.id}
                onClick={() => addToCart(product)}
                disabled={product.stock <= 0}
                className={`group bg-white rounded-xl border border-slate-200 p-3 text-left transition-all ${
                  product.stock > 0
                    ? 'hover:shadow-lg hover:border-violet-300 hover:scale-[1.02]'
                    : 'opacity-50 cursor-not-allowed'
                }`}
              >
                {product.imageURL ? (
                  <img
                    src={product.imageURL}
                    alt={product.name}
                    className="w-full h-28 object-cover rounded-lg mb-3"
                  />
                ) : (
                  <div className="w-full h-28 bg-gradient-to-br from-slate-100 to-slate-200 rounded-lg mb-3 flex items-center justify-center">
                    <Package className="w-10 h-10 text-slate-400" />
                  </div>
                )}
                <h3 className="font-medium text-slate-900 text-sm truncate mb-1">{product.name}</h3>
                <div className="flex items-center justify-between">
                  <p className="text-violet-600 font-bold">{formatCurrency(product.price)}</p>
                  <span className={`text-xs px-2 py-0.5 rounded-full ${
                    product.stock > 10 
                      ? 'bg-emerald-100 text-emerald-700' 
                      : product.stock > 0 
                        ? 'bg-amber-100 text-amber-700'
                        : 'bg-red-100 text-red-700'
                  }`}>
                    {product.stock}
                  </span>
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Cart Section */}
        <div className="space-y-4">
          {/* Cart Items */}
          <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
            <div className="px-4 py-3 border-b border-slate-100 flex items-center justify-between">
              <h2 className="font-semibold text-slate-900 flex items-center gap-2">
                <ShoppingCart className="w-5 h-5 text-violet-600" />
                Giỏ hàng ({cart.length})
              </h2>
              {cart.length > 0 && (
                <button 
                  onClick={clearCart}
                  className="text-xs text-red-500 hover:text-red-600 hover:bg-red-50 px-2 py-1 rounded"
                >
                  Xóa tất cả
                </button>
              )}
            </div>

            {cart.length === 0 ? (
              <div className="p-8 text-center">
                <ShoppingCart className="w-12 h-12 text-slate-300 mx-auto mb-3" />
                <p className="text-slate-500">Chưa có sản phẩm</p>
                <p className="text-xs text-slate-400 mt-1">Click sản phẩm bên trái để thêm</p>
              </div>
            ) : (
              <div className="max-h-48 overflow-y-auto">
                {cart.map((item) => (
                  <div key={item.id} className="flex items-center gap-3 p-3 border-b border-slate-50 last:border-0">
                    {item.imageURL ? (
                      <img src={item.imageURL} alt={item.name} className="w-12 h-12 rounded-lg object-cover" />
                    ) : (
                      <div className="w-12 h-12 rounded-lg bg-slate-100 flex items-center justify-center">
                        <Package className="w-5 h-5 text-slate-400" />
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-sm text-slate-900 truncate">{item.name}</p>
                      <p className="text-xs text-violet-600 font-semibold">{formatCurrency(item.price)}</p>
                    </div>
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => updateQuantity(item.id, -1)}
                        className="w-7 h-7 flex items-center justify-center text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                      >
                        <Minus className="w-4 h-4" />
                      </button>
                      <span className="w-8 text-center text-sm font-medium">{item.quantity}</span>
                      <button
                        onClick={() => updateQuantity(item.id, 1)}
                        className="w-7 h-7 flex items-center justify-center text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                      >
                        <Plus className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => removeFromCart(item.id)}
                        className="w-7 h-7 flex items-center justify-center text-red-500 hover:bg-red-50 rounded-lg transition-colors ml-1"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Customer Info */}
          <div className="bg-white rounded-xl border border-slate-200 p-4 space-y-3">
            <h3 className="font-medium text-slate-900 flex items-center gap-2">
              <User className="w-4 h-4 text-slate-500" />
              Thông tin khách hàng
            </h3>
            <input
              type="text"
              placeholder="Tên khách hàng"
              value={customer.name}
              onChange={(e) => setCustomer((prev) => ({ ...prev, name: e.target.value }))}
              className="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-transparent"
            />
            <input
              type="tel"
              placeholder="Số điện thoại"
              value={customer.phone}
              onChange={(e) => setCustomer((prev) => ({ ...prev, phone: e.target.value }))}
              className="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-transparent"
            />
          </div>

          {/* Payment Summary */}
          <div className="bg-white rounded-xl border border-slate-200 p-4 space-y-4">
            {/* Amounts */}
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-slate-500">Tạm tính:</span>
                <span className="font-medium text-slate-900">{formatCurrency(subtotal)}</span>
              </div>
              
              <div className="flex items-center justify-between">
                <span className="text-sm text-slate-500">Giảm giá:</span>
                <div className="flex items-center gap-2">
                  <input
                    type="number"
                    min="0"
                    max={subtotal}
                    value={discount}
                    onChange={(e) => setDiscount(parseFloat(e.target.value) || 0)}
                    className="w-24 border border-slate-200 rounded-lg px-2 py-1.5 text-sm text-right focus:outline-none focus:ring-2 focus:ring-violet-500"
                  />
                  <span className="text-slate-500">đ</span>
                </div>
              </div>
              
              <div className="flex justify-between text-lg font-bold pt-2 border-t border-slate-100">
                <span className="text-slate-900">Tổng cộng:</span>
                <span className="text-violet-600">{formatCurrency(finalAmount)}</span>
              </div>
            </div>

            {/* Payment Method */}
            <div className="space-y-2">
              <label className="text-sm text-slate-500">Phương thức thanh toán:</label>
              <div className="grid grid-cols-3 gap-2">
                {[
                  { key: 'cash', label: 'Tiền mặt', icon: Banknote },
                  { key: 'transfer', label: 'Chuyển khoản', icon: CreditCard },
                  { key: 'debt', label: 'Công nợ', icon: Receipt },
                ].map((method) => {
                  const Icon = method.icon;
                  return (
                    <button
                      key={method.key}
                      onClick={() => setPaymentMethod(method.key as any)}
                      className={`flex flex-col items-center gap-1 py-2 px-2 text-xs rounded-lg border transition-colors ${
                        paymentMethod === method.key
                          ? 'bg-violet-50 border-violet-500 text-violet-700'
                          : 'border-slate-200 text-slate-600 hover:bg-slate-50'
                      }`}
                    >
                      <Icon className="w-4 h-4" />
                      {method.label}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Paid Amount */}
            {paymentMethod !== 'debt' && (
              <div className="flex items-center justify-between">
                <span className="text-sm text-slate-500">Khách trả:</span>
                <div className="flex items-center gap-2">
                  <input
                    type="number"
                    min="0"
                    value={paidAmount}
                    onChange={(e) => setPaidAmount(parseFloat(e.target.value) || 0)}
                    className="w-24 border border-slate-200 rounded-lg px-2 py-1.5 text-sm text-right focus:outline-none focus:ring-2 focus:ring-violet-500"
                  />
                  <span className="text-slate-500">đ</span>
                </div>
              </div>
            )}

            {/* Debt/Change */}
            {debtAmount > 0 && (
              <div className="flex justify-between text-sm bg-red-50 p-2 rounded-lg">
                <span className="text-red-600">Còn nợ:</span>
                <span className="font-semibold text-red-600">{formatCurrency(debtAmount)}</span>
              </div>
            )}
            {paidAmount > finalAmount && (
              <div className="flex justify-between text-sm bg-emerald-50 p-2 rounded-lg">
                <span className="text-emerald-600">Tiền thừa:</span>
                <span className="font-semibold text-emerald-600">{formatCurrency(paidAmount - finalAmount)}</span>
              </div>
            )}

            {/* Note */}
            <textarea
              placeholder="Ghi chú (tùy chọn)"
              value={note}
              onChange={(e) => setNote(e.target.value)}
              className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-violet-500 resize-none"
              rows={2}
            />

            {/* Action Buttons */}
            <div className="flex gap-3 pt-2">
              <button
                onClick={clearCart}
                disabled={cart.length === 0}
                className="flex-1 py-3 text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-xl font-medium transition-colors disabled:opacity-50"
              >
                Hủy
              </button>
              <button
                onClick={handleSubmit}
                disabled={cart.length === 0 || submitting}
                className="flex-[2] py-3 bg-gradient-to-r from-violet-600 to-indigo-600 hover:from-violet-700 hover:to-indigo-700 text-white rounded-xl font-medium transition-all disabled:opacity-50 flex items-center justify-center gap-2 shadow-lg shadow-violet-500/25"
              >
                {submitting ? (
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                ) : (
                  <>
                    <CheckCircle className="w-5 h-5" />
                    Thanh toán
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Receipt Modal */}
      {showReceipt && lastOrder && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm" onClick={() => setShowReceipt(false)} />
          <div className="relative bg-white rounded-2xl shadow-2xl max-w-sm w-full p-6">
            <div className="text-center mb-6">
              <div className="w-16 h-16 bg-gradient-to-br from-emerald-400 to-emerald-600 rounded-full flex items-center justify-center mx-auto mb-3">
                <CheckCircle className="w-8 h-8 text-white" />
              </div>
              <h2 className="text-xl font-bold text-slate-900">HÓA ĐƠN</h2>
              <p className="text-sm text-slate-500">#{lastOrder.id.slice(-6).toUpperCase()}</p>
            </div>

            <div className="space-y-1 text-sm text-slate-600 mb-4 bg-slate-50 p-3 rounded-xl">
              <p><span className="font-medium">Khách hàng:</span> {lastOrder.customerName}</p>
              <p><span className="font-medium">Ngày:</span> {new Date().toLocaleString('vi-VN')}</p>
            </div>

            <div className="border-t border-b border-slate-100 py-3 mb-4 max-h-40 overflow-y-auto">
              {lastOrder.items.map((item: any, idx: number) => (
                <div key={idx} className="flex justify-between text-sm py-1.5">
                  <span className="text-slate-700">
                    {item.name} <span className="text-slate-400">x{item.quantity}</span>
                  </span>
                  <span className="font-medium text-slate-900">{formatCurrency(item.subtotal)}</span>
                </div>
              ))}
            </div>

            <div className="space-y-1 text-sm mb-6">
              <div className="flex justify-between text-slate-600">
                <span>Tạm tính:</span>
                <span>{formatCurrency(lastOrder.totalAmount)}</span>
              </div>
              {lastOrder.discount > 0 && (
                <div className="flex justify-between text-red-500">
                  <span>Giảm giá:</span>
                  <span>-{formatCurrency(lastOrder.discount)}</span>
                </div>
              )}
              <div className="flex justify-between text-lg font-bold pt-2 border-t border-slate-100">
                <span className="text-slate-900">Tổng cộng:</span>
                <span className="text-violet-600">{formatCurrency(lastOrder.finalAmount)}</span>
              </div>
            </div>

            <button
              onClick={() => setShowReceipt(false)}
              className="w-full py-3 bg-gradient-to-r from-violet-600 to-indigo-600 text-white rounded-xl font-medium hover:opacity-90 transition-opacity"
            >
              Đóng
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
  }).format(amount);
}
