'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { getProducts, getCustomers, getOrders, Product, Customer, Order, WithId } from '@/lib/firestore';
import { Package, Users, ShoppingCart, TrendingUp, DollarSign } from 'lucide-react';

interface DashboardStats {
  totalProducts: number;
  lowStockProducts: number;
  totalCustomers: number;
  totalCustomersWithDebt: number;
  todayOrders: number;
  todayRevenue: number;
  totalDebt: number;
}

export default function DashboardPage() {
  const { user } = useAuth();
  const [stats, setStats] = useState<DashboardStats>({
    totalProducts: 0,
    lowStockProducts: 0,
    totalCustomers: 0,
    totalCustomersWithDebt: 0,
    todayOrders: 0,
    todayRevenue: 0,
    totalDebt: 0,
  });
  const [recentOrders, setRecentOrders] = useState<(Order & WithId)[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user?.storeId) return;

    async function loadDashboardData() {
      try {
        const [products, customers, orders] = await Promise.all([
          getProducts(user!.storeId!),
          getCustomers(user!.storeId!),
          getOrders(user!.storeId!),
        ]);

        const today = new Date().toISOString().split('T')[0];
        const todayOrders = orders.filter((o) => o.createdAt?.startsWith(today));

        setStats({
          totalProducts: products.length,
          lowStockProducts: products.filter((p) => p.stock < 10).length,
          totalCustomers: customers.length,
          totalCustomersWithDebt: customers.filter((c) => c.debtAmount > 0).length,
          todayOrders: todayOrders.length,
          todayRevenue: todayOrders.reduce((sum, o) => sum + o.finalAmount, 0),
          totalDebt: customers.reduce((sum, c) => sum + c.debtAmount, 0),
        });

        setRecentOrders(orders.slice(0, 5));
      } catch (error) {
        console.error('Error loading dashboard:', error);
      } finally {
        setLoading(false);
      }
    }

    loadDashboardData();
  }, [user]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title="Tổng sản phẩm"
          value={stats.totalProducts}
          subtitle={`${stats.lowStockProducts} sản phẩm sắp hết hàng`}
          icon={<Package className="w-6 h-6 text-blue-600" />}
          color="blue"
        />
        <StatCard
          title="Khách hàng"
          value={stats.totalCustomers}
          subtitle={`${stats.totalCustomersWithDebt} có công nợ`}
          icon={<Users className="w-6 h-6 text-green-600" />}
          color="green"
        />
        <StatCard
          title="Đơn hàng hôm nay"
          value={stats.todayOrders}
          subtitle={`Doanh thu: ${formatCurrency(stats.todayRevenue)}`}
          icon={<ShoppingCart className="w-6 h-6 text-purple-600" />}
          color="purple"
        />
        <StatCard
          title="Tổng công nợ"
          value={formatCurrency(stats.totalDebt)}
          subtitle="Cần thu từ khách hàng"
          icon={<DollarSign className="w-6 h-6 text-red-600" />}
          color="red"
        />
      </div>

      {/* Recent Orders */}
      <div className="card">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Đơn hàng gần đây</h2>
        {recentOrders.length === 0 ? (
          <p className="text-gray-500">Chưa có đơn hàng nào</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="text-left py-2 px-4 text-sm font-medium text-gray-600">Mã đơn</th>
                  <th className="text-left py-2 px-4 text-sm font-medium text-gray-600">Khách hàng</th>
                  <th className="text-right py-2 px-4 text-sm font-medium text-gray-600">Tổng tiền</th>
                  <th className="text-left py-2 px-4 text-sm font-medium text-gray-600">Thanh toán</th>
                  <th className="text-left py-2 px-4 text-sm font-medium text-gray-600">Ngày</th>
                </tr>
              </thead>
              <tbody>
                {recentOrders.map((order) => (
                  <tr key={order.id} className="border-b border-gray-100">
                    <td className="py-2 px-4 text-sm">#{order.id.slice(-6)}</td>
                    <td className="py-2 px-4 text-sm">{order.customerName || 'Khách lẻ'}</td>
                    <td className="py-2 px-4 text-sm text-right font-medium">
                      {formatCurrency(order.finalAmount)}
                    </td>
                    <td className="py-2 px-4 text-sm">
                      <span className={`inline-flex px-2 py-1 text-xs rounded-full ${
                        order.paymentMethod === 'cash'
                          ? 'bg-green-100 text-green-800'
                          : order.paymentMethod === 'transfer'
                          ? 'bg-blue-100 text-blue-800'
                          : 'bg-yellow-100 text-yellow-800'
                      }`}>
                        {order.paymentMethod === 'cash'
                          ? 'Tiền mặt'
                          : order.paymentMethod === 'transfer'
                          ? 'Chuyển khoản'
                          : 'Công nợ'}
                      </span>
                    </td>
                    <td className="py-2 px-4 text-sm text-gray-500">
                      {order.createdAt ? new Date(order.createdAt).toLocaleDateString('vi-VN') : '-'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

function StatCard({
  title,
  value,
  subtitle,
  icon,
  color,
}: {
  title: string;
  value: string | number;
  subtitle: string;
  icon: React.ReactNode;
  color: 'blue' | 'green' | 'purple' | 'red';
}) {
  const colorClasses = {
    blue: 'bg-blue-50',
    green: 'bg-green-50',
    purple: 'bg-purple-50',
    red: 'bg-red-50',
  };

  return (
    <div className="card">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-gray-600">{title}</p>
          <p className="text-2xl font-bold text-gray-900 mt-1">{value}</p>
          <p className="text-xs text-gray-500 mt-1">{subtitle}</p>
        </div>
        <div className={`p-2 rounded-lg ${colorClasses[color]}`}>{icon}</div>
      </div>
    </div>
  );
}

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
  }).format(amount);
}
