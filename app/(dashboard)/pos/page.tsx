'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { getProducts, addOrder, Product, WithId } from '@/lib/firestore';
import { Plus, Minus, Trash2, ShoppingCart, User, X, Search, Calculator } from 'lucide-react';

interface CartItem extends Product {
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
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Bán hàng POS</h1>

      <div className="grid lg:grid-cols-3 gap-6">
        {/* Products Section */}
        <div className="lg:col-span-2 space-y-4">
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Tìm sản phẩm..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="input pl-10"
            />
          </div>

          {/* Products Grid */}
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            {filteredProducts.map((product) => (
              <button
                key={product.id}
                onClick={() => addToCart(product)}
                disabled={product.stock <= 0}
                className={`card p-4 text-left transition-all ${
                  product.stock > 0
                    ? 'hover:shadow-md hover:border-primary-300'
                    : 'opacity-50 cursor-not-allowed'
                }`}
              >
                {product.imageURL && (
                  <img
                    src={product.imageURL}
                    alt={product.name}
                    className="w-full h-24 object-cover rounded-lg mb-2"
                  />
                )}
                <h3 className="font-medium text-gray-900 text-sm truncate">{product.name}</h3>
                <p className="text-primary-600 font-bold">{formatCurrency(product.price)}</p>
                <p className="text-xs text-gray-500">Tồn: {product.stock}</p>
              </button>
            ))}
          </div>
        </div>

        {/* Cart Section */}
        <div className="space-y-4">
          <div className="card">
            <h2 className="font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <ShoppingCart className="w-5 h-5" />
              Giỏ hàng ({cart.length})
            </h2>

            {cart.length === 0 ? (
              <p className="text-gray-500 text-center py-8">Chưa có sản phẩm</p>
            ) : (
              <div className="space-y-3 max-h-64 overflow-y-auto">
                {cart.map((item) => (
                  <div key={item.id} className="flex items-center gap-3 p-2 bg-gray-50 rounded-lg">
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-sm text-gray-900 truncate">{item.name}</p>
                      <p className="text-xs text-gray-500">{formatCurrency(item.price)}</p>
                    </div>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => updateQuantity(item.id, -1)}
                        className="p-1 text-gray-600 hover:bg-gray-200 rounded"
                      >
                        <Minus className="w-4 h-4" />
                      </button>
                      <span className="w-8 text-center text-sm">{item.quantity}</span>
                      <button
                        onClick={() => updateQuantity(item.id, 1)}
                        className="p-1 text-gray-600 hover:bg-gray-200 rounded"
                      >
                        <Plus className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => removeFromCart(item.id)}
                        className="p-1 text-red-600 hover:bg-red-50 rounded"
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
          <div className="card space-y-3">
            <h3 className="font-medium text-gray-900 flex items-center gap-2">
              <User className="w-4 h-4" />
              Thông tin khách hàng
            </h3>
            <input
              type="text"
              placeholder="Tên khách hàng"
              value={customer.name}
              onChange={(e) => setCustomer((prev) => ({ ...prev, name: e.target.value }))}
              className="input"
            />
            <input
              type="tel"
              placeholder="Số điện thoại"
              value={customer.phone}
              onChange={(e) => setCustomer((prev) => ({ ...prev, phone: e.target.value }))}
              className="input"
            />
          </div>

          {/* Payment */}
          <div className="card space-y-4">
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Tạm tính:</span>
              <span className="font-medium">{formatCurrency(subtotal)}</span>
            </div>

            <div className="flex items-center gap-2">
              <span className="text-sm text-gray-600">Giảm giá:</span>
              <input
                type="number"
                min="0"
                max={subtotal}
                value={discount}
                onChange={(e) => setDiscount(parseFloat(e.target.value) || 0)}
                className="input w-32 text-right"
              />
            </div>

            <div className="flex justify-between text-lg font-bold">
              <span className="text-gray-900">Tổng cộng:</span>
              <span className="text-primary-600">{formatCurrency(finalAmount)}</span>
            </div>

            <div className="space-y-2">
              <label className="text-sm text-gray-600">Phương thức thanh toán:</label>
              <div className="grid grid-cols-3 gap-2">
                {[
                  { key: 'cash', label: 'Tiền mặt' },
                  { key: 'transfer', label: 'Chuyển khoản' },
                  { key: 'debt', label: 'Công nợ' },
                ].map((method) => (
                  <button
                    key={method.key}
                    onClick={() => setPaymentMethod(method.key as any)}
                    className={`py-2 px-3 text-sm rounded-lg border ${
                      paymentMethod === method.key
                        ? 'bg-primary-50 border-primary-500 text-primary-700'
                        : 'border-gray-200 text-gray-700 hover:bg-gray-50'
                    }`}
                  >
                    {method.label}
                  </button>
                ))}
              </div>
            </div>

            {paymentMethod !== 'debt' && (
              <div className="flex items-center gap-2">
                <span className="text-sm text-gray-600">Khách trả:</span>
                <input
                  type="number"
                  min="0"
                  value={paidAmount}
                  onChange={(e) => setPaidAmount(parseFloat(e.target.value) || 0)}
                  className="input w-32 text-right"
                />
              </div>
            )}

            {debtAmount > 0 && (
              <div className="flex justify-between text-sm text-red-600">
                <span>Còn nợ:</span>
                <span className="font-medium">{formatCurrency(debtAmount)}</span>
              </div>
            )}

            {paidAmount > finalAmount && (
              <div className="flex justify-between text-sm text-green-600">
                <span>Tiền thừa:</span>
                <span className="font-medium">{formatCurrency(paidAmount - finalAmount)}</span>
              </div>
            )}

            <textarea
              placeholder="Ghi chú (tùy chọn)"
              value={note}
              onChange={(e) => setNote(e.target.value)}
              className="input text-sm"
              rows={2}
            />

            <div className="flex gap-2">
              <button
                onClick={clearCart}
                disabled={cart.length === 0}
                className="flex-1 btn-secondary py-3"
              >
                Hủy
              </button>
              <button
                onClick={handleSubmit}
                disabled={cart.length === 0 || submitting}
                className="flex-1 btn-primary py-3 flex justify-center items-center gap-2"
              >
                {submitting && <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />}
                Thanh toán
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Receipt Modal */}
      {showReceipt && lastOrder && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-gray-900/50" onClick={() => setShowReceipt(false)} />
          <div className="relative bg-white rounded-lg shadow-xl max-w-sm w-full p-6">
            <div className="text-center mb-4">
              <h2 className="text-xl font-bold">HÓA ĐƠN</h2>
              <p className="text-sm text-gray-500">#{lastOrder.id.slice(-6)}</p>
            </div>

            <div className="space-y-1 text-sm mb-4">
              <p>Khách hàng: {lastOrder.customerName}</p>
              <p>Ngày: {new Date().toLocaleString('vi-VN')}</p>
            </div>

            <div className="border-t border-b border-gray-200 py-2 mb-4">
              {lastOrder.items.map((item: any, idx: number) => (
                <div key={idx} className="flex justify-between text-sm py-1">
                  <span>
                    {item.name} x {item.quantity}
                  </span>
                  <span>{formatCurrency(item.subtotal)}</span>
                </div>
              ))}
            </div>

            <div className="space-y-1 text-sm mb-4">
              <div className="flex justify-between">
                <span>Tạm tính:</span>
                <span>{formatCurrency(lastOrder.totalAmount)}</span>
              </div>
              {lastOrder.discount > 0 && (
                <div className="flex justify-between">
                  <span>Giảm giá:</span>
                  <span>-{formatCurrency(lastOrder.discount)}</span>
                </div>
              )}
              <div className="flex justify-between font-bold text-lg">
                <span>Tổng cộng:</span>
                <span>{formatCurrency(lastOrder.finalAmount)}</span>
              </div>
            </div>

            <button
              onClick={() => setShowReceipt(false)}
              className="w-full btn-primary"
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
