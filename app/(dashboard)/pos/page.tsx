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
    <div className="h-[calc(100vh-4rem)] bg-emerald-50/50 -m-4 sm:-m-6 lg:-m-8 p-3 sm:p-4 lg:p-5 overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <h1 className="text-lg font-bold text-emerald-900">Bán hàng POS</h1>
          <span className="text-xs text-emerald-600 bg-emerald-100 px-2 py-0.5 rounded-full">{cart.length} SP</span>
        </div>
      </div>

      <div className="grid lg:grid-cols-3 gap-3 h-[calc(100%-2rem)]">
        {/* Products Section */}
        <div className="lg:col-span-2 space-y-4">
          {/* Search */}
          <div className="bg-white rounded-lg border border-emerald-100 shadow-sm">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-emerald-400" />
              <input
                type="text"
                placeholder="Tìm sản phẩm..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-9 pr-3 py-2 border-0 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm text-emerald-900 placeholder-emerald-400/70"
              />
            </div>
          </div>

          {/* Products Grid */}
          <div className="grid grid-cols-3 sm:grid-cols-4 gap-2 overflow-y-auto max-h-[calc(100%-3rem)]">
            {filteredProducts.map((product) => (
              <button
                key={product.id}
                onClick={() => addToCart(product)}
                disabled={product.stock <= 0}
                className={`group bg-white rounded-lg border border-emerald-100 p-2 text-left transition-all shadow-sm ${
                  product.stock > 0
                    ? 'hover:shadow-md hover:border-emerald-300 hover:ring-1 hover:ring-emerald-200'
                    : 'opacity-50 cursor-not-allowed'
                }`}
              >
                {product.imageURL ? (
                  <img
                    src={product.imageURL}
                    alt={product.name}
                    className="w-full h-16 object-cover rounded-md mb-2"
                  />
                ) : (
                  <div className="w-full h-16 bg-gradient-to-br from-emerald-50 to-emerald-100 rounded-md mb-2 flex items-center justify-center">
                    <Package className="w-6 h-6 text-emerald-400" />
                  </div>
                )}
                <h3 className="font-medium text-emerald-900 text-xs truncate">{product.name}</h3>
                <div className="flex items-center justify-between mt-1">
                  <p className="text-orange-600 font-bold text-xs">{formatCurrency(product.price)}</p>
                  <span className={`text-[10px] px-1.5 py-0.5 rounded-full ${
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
        <div className="space-y-2 overflow-y-auto max-h-full">
          {/* Cart Items */}
          <div className="bg-white rounded-lg border border-emerald-100 overflow-hidden shadow-sm">
            <div className="px-3 py-2 border-b border-emerald-50 flex items-center justify-between">
              <h2 className="font-semibold text-sm text-emerald-900 flex items-center gap-1.5">
                <ShoppingCart className="w-4 h-4 text-emerald-600" />
                Giỏ ({cart.length})
              </h2>
              {cart.length > 0 && (
                <button 
                  onClick={clearCart}
                  className="text-[10px] text-red-500 hover:text-red-600 px-1.5 py-0.5 rounded"
                >
                  Xóa
                </button>
              )}
            </div>

            {cart.length === 0 ? (
              <div className="p-4 text-center">
                <p className="text-xs text-slate-400">Chưa có sản phẩm</p>
              </div>
            ) : (
              <div className="max-h-32 overflow-y-auto">
                {cart.map((item) => (
                  <div key={item.id} className="flex items-center gap-2 p-2 border-b border-slate-50 last:border-0">
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-xs text-emerald-900 truncate">{item.name}</p>
                      <p className="text-[10px] text-emerald-600">{formatCurrency(item.price)}</p>
                    </div>
                    <div className="flex items-center gap-0.5">
                      <button onClick={() => updateQuantity(item.id, -1)} className="w-6 h-6 flex items-center justify-center text-slate-600 hover:bg-slate-100 rounded">
                        <Minus className="w-3 h-3" />
                      </button>
                      <span className="w-6 text-center text-xs font-medium">{item.quantity}</span>
                      <button onClick={() => updateQuantity(item.id, 1)} className="w-6 h-6 flex items-center justify-center text-slate-600 hover:bg-slate-100 rounded">
                        <Plus className="w-3 h-3" />
                      </button>
                      <button onClick={() => removeFromCart(item.id)} className="w-6 h-6 flex items-center justify-center text-red-500 hover:bg-red-50 rounded ml-0.5">
                        <Trash2 className="w-3 h-3" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Customer Info */}
          <div className="bg-white rounded-lg border border-emerald-100 p-2 space-y-2 shadow-sm">
            <input
              type="text"
              placeholder="Tên KH"
              value={customer.name}
              onChange={(e) => setCustomer((prev) => ({ ...prev, name: e.target.value }))}
              className="w-full border border-emerald-200 rounded-lg px-2 py-1.5 text-xs focus:outline-none focus:ring-1 focus:ring-emerald-500 text-emerald-900 placeholder-emerald-400/70"
            />
            <input
              type="tel"
              placeholder="SĐT"
              value={customer.phone}
              onChange={(e) => setCustomer((prev) => ({ ...prev, phone: e.target.value }))}
              className="w-full border border-emerald-200 rounded-lg px-2 py-1.5 text-xs focus:outline-none focus:ring-1 focus:ring-emerald-500 text-emerald-900 placeholder-emerald-400/70"
            />
          </div>

          {/* Payment Summary */}
          <div className="bg-white rounded-lg border border-emerald-100 p-3 space-y-2 shadow-sm">
            <div className="flex justify-between text-sm">
              <span className="text-emerald-600">Tạm tính:</span>
              <span className="font-medium text-emerald-900">{formatCurrency(subtotal)}</span>
            </div>
            
            <div className="flex items-center justify-between text-sm">
              <span className="text-emerald-600">Giảm:</span>
              <input
                type="number"
                min="0"
                max={subtotal}
                value={discount}
                onChange={(e) => setDiscount(parseFloat(e.target.value) || 0)}
                className="w-20 border border-emerald-200 rounded-lg px-2 py-1 text-xs text-right text-emerald-900 focus:outline-none focus:ring-1 focus:ring-emerald-500"
              />
            </div>
            
            <div className="flex justify-between font-bold text-base border-t border-emerald-100 pt-1">
              <span className="text-emerald-900">Tổng:</span>
              <span className="text-emerald-600">{formatCurrency(finalAmount)}</span>
            </div>

            {/* Payment Method */}
            <div className="grid grid-cols-3 gap-1 pt-1">
              {[
                { key: 'cash', label: 'Tiền mặt' },
                { key: 'transfer', label: 'CK' },
                { key: 'debt', label: 'Nợ' },
              ].map((method) => (
                <button
                  key={method.key}
                  onClick={() => setPaymentMethod(method.key as any)}
                  className={`py-1.5 px-1 text-[10px] rounded-lg border ${
                    paymentMethod === method.key
                      ? 'bg-emerald-500 border-emerald-500 text-white'
                      : 'border-emerald-200 text-emerald-600 hover:bg-emerald-50'
                  }`}
                >
                  {method.label}
                </button>
              ))}
            </div>

            {paymentMethod !== 'debt' && (
              <div className="flex items-center justify-between text-sm">
                <span className="text-emerald-600">Khách trả:</span>
                <input
                  type="number"
                  min="0"
                  value={paidAmount}
                  onChange={(e) => setPaidAmount(parseFloat(e.target.value) || 0)}
                  className="w-20 border border-emerald-200 rounded-lg px-2 py-1 text-xs text-right text-emerald-900 focus:outline-none focus:ring-1 focus:ring-emerald-500"
                />
              </div>
            )}

            {debtAmount > 0 && (
              <div className="flex justify-between text-xs bg-red-50 p-1.5 rounded-lg">
                <span className="text-red-600">Còn nợ:</span>
                <span className="font-semibold text-red-600">{formatCurrency(debtAmount)}</span>
              </div>
            )}
            {paidAmount > finalAmount && (
              <div className="flex justify-between text-xs bg-emerald-50 p-1.5 rounded-lg">
                <span className="text-emerald-600">Thừa:</span>
                <span className="font-semibold text-emerald-600">{formatCurrency(paidAmount - finalAmount)}</span>
              </div>
            )}

            <div className="flex gap-2 pt-1">
              <button
                onClick={clearCart}
                disabled={cart.length === 0}
                className="flex-1 py-2 text-xs text-emerald-600 bg-emerald-50 hover:bg-emerald-100 rounded-lg font-medium disabled:opacity-50"
              >
                Hủy
              </button>
              <button
                onClick={handleSubmit}
                disabled={cart.length === 0 || submitting}
                className="flex-[2] py-2 bg-orange-500 hover:bg-orange-600 text-white rounded-lg font-medium text-xs disabled:opacity-50 flex items-center justify-center gap-1 shadow-lg shadow-orange-500/30"
              >
                {submitting ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  : <><CheckCircle className="w-4 h-4" /> Thanh toán</>}
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
