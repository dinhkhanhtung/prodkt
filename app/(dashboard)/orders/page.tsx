'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { getOrders, Order, WithId } from '@/lib/firestore';
import { Search, Receipt, Calendar, User } from 'lucide-react';

export default function OrdersPage() {
  const { user } = useAuth();
  const [orders, setOrders] = useState<(Order & WithId)[]>([]);
  const [filteredOrders, setFilteredOrders] = useState<(Order & WithId)[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [dateFilter, setDateFilter] = useState('');

  const loadOrders = useCallback(async () => {
    if (!user?.storeId) return;
    try {
      const data = await getOrders(user.storeId);
      setOrders(data);
      setFilteredOrders(data);
    } catch (error) {
      console.error('Error loading orders:', error);
    } finally {
      setLoading(false);
    }
  }, [user]);

  useEffect(() => {
    loadOrders();
  }, [loadOrders]);

  useEffect(() => {
    let filtered = orders;

    if (searchQuery.trim() !== '') {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(
        (o) =>
          o.customerName.toLowerCase().includes(query) ||
          o.id.toLowerCase().includes(query)
      );
    }

    if (dateFilter) {
      filtered = filtered.filter((o) => o.createdAt?.startsWith(dateFilter));
    }

    setFilteredOrders(filtered);
  }, [searchQuery, dateFilter, orders]);

  const totalRevenue = filteredOrders.reduce((sum, o) => sum + o.finalAmount, 0);
  const totalDebt = filteredOrders.reduce((sum, o) => sum + o.debtAmount, 0);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <h1 className="text-2xl font-bold text-gray-900">Quản lý hóa đơn</h1>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="card">
          <p className="text-sm text-gray-600">Tổng số đơn</p>
          <p className="text-2xl font-bold text-gray-900">{filteredOrders.length}</p>
        </div>
        <div className="card">
          <p className="text-sm text-gray-600">Tổng doanh thu</p>
          <p className="text-2xl font-bold text-primary-600">{formatCurrency(totalRevenue)}</p>
        </div>
        <div className="card">
          <p className="text-sm text-gray-600">Tổng công nợ phát sinh</p>
          <p className="text-2xl font-bold text-red-600">{formatCurrency(totalDebt)}</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="Tìm kiếm theo tên KH hoặc mã đơn..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="input pl-10"
          />
        </div>
        <div className="flex items-center gap-2">
          <Calendar className="w-5 h-5 text-gray-400" />
          <input
            type="date"
            value={dateFilter}
            onChange={(e) => setDateFilter(e.target.value)}
            className="input"
          />
          {dateFilter && (
            <button onClick={() => setDateFilter('')} className="p-2 text-gray-400 hover:text-gray-600">
              ✕
            </button>
          )}
        </div>
      </div>

      {/* Orders List */}
      {filteredOrders.length === 0 ? (
        <div className="card text-center py-12">
          <Receipt className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <p className="text-gray-500">Chưa có hóa đơn nào</p>
        </div>
      ) : (
        <div className="space-y-4">
          {filteredOrders.map((order) => (
            <div key={order.id} className="card p-4">
              <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                  <div className="flex items-center gap-3">
                    <span className="font-semibold text-gray-900">#{order.id.slice(-6)}</span>
                    <span
                      className={`inline-flex px-2 py-1 text-xs rounded-full ${
                        order.paymentMethod === 'cash'
                          ? 'bg-green-100 text-green-800'
                          : order.paymentMethod === 'transfer'
                          ? 'bg-blue-100 text-blue-800'
                          : 'bg-yellow-100 text-yellow-800'
                      }`}
                    >
                      {order.paymentMethod === 'cash'
                        ? 'Tiền mặt'
                        : order.paymentMethod === 'transfer'
                        ? 'Chuyển khoản'
                        : 'Công nợ'}
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 mt-1 flex items-center gap-1">
                    <User className="w-4 h-4" />
                    {order.customerName}
                  </p>
                  <p className="text-xs text-gray-500 mt-1">
                    {order.createdAt ? new Date(order.createdAt).toLocaleString('vi-VN') : '-'}
                  </p>
                </div>

                <div className="flex items-center gap-6">
                  <div className="text-right">
                    <p className="text-xs text-gray-500">Tổng tiền</p>
                    <p className="font-bold text-lg text-gray-900">{formatCurrency(order.finalAmount)}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-xs text-gray-500">Đã thanh toán</p>
                    <p className="font-medium text-green-600">{formatCurrency(order.paidAmount)}</p>
                  </div>
                  {order.debtAmount > 0 && (
                    <div className="text-right">
                      <p className="text-xs text-gray-500">Còn nợ</p>
                      <p className="font-medium text-red-600">{formatCurrency(order.debtAmount)}</p>
                    </div>
                  )}
                </div>
              </div>

              {/* Order Items */}
              <div className="mt-4 pt-4 border-t border-gray-200">
                <p className="text-sm font-medium text-gray-700 mb-2">Chi tiết đơn hàng:</p>
                <div className="space-y-1">
                  {order.items.map((item, idx) => (
                    <div key={idx} className="flex justify-between text-sm">
                      <span className="text-gray-600">
                        {item.name} x {item.quantity}
                      </span>
                      <span className="text-gray-900">{formatCurrency(item.subtotal)}</span>
                    </div>
                  ))}
                </div>
                {order.discount > 0 && (
                  <div className="flex justify-between text-sm mt-2 pt-2 border-t border-gray-100">
                    <span className="text-gray-600">Giảm giá</span>
                    <span className="text-red-600">-{formatCurrency(order.discount)}</span>
                  </div>
                )}
              </div>
            </div>
          ))}
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
