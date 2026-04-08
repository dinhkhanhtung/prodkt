'use client';

import { useEffect, useState, useMemo } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { getProducts, getCustomers, getOrders, getExpenses, Product, Customer, Order, Expense } from '@/lib/firestore';
import { 
  Package, Users, ShoppingCart, TrendingUp, DollarSign, 
  ArrowUpRight, ArrowDownRight, Wallet, AlertCircle,
  Sparkles, BarChart3
} from 'lucide-react';
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, BarChart, Bar
} from 'recharts';

interface DashboardStats {
  totalProducts: number;
  lowStockProducts: number;
  totalCustomers: number;
  totalCustomersWithDebt: number;
  todayOrders: number;
  todayRevenue: number;
  totalDebt: number;
  todayExpenses: number;
  todayProfit: number;
  monthlyRevenue: number;
  monthlyExpenses: number;
  monthlyProfit: number;
}

const COLORS = ['#10b981', '#3b82f6', '#f59e0b', '#ef4444', '#8b5cf6'];

export default function DashboardPage() {
  const { user } = useAuth();
  const storeId = user?.storeId;
  const [stats, setStats] = useState<DashboardStats>({
    totalProducts: 0, lowStockProducts: 0, totalCustomers: 0,
    totalCustomersWithDebt: 0, todayOrders: 0, todayRevenue: 0, totalDebt: 0,
    todayExpenses: 0, todayProfit: 0, monthlyRevenue: 0, monthlyExpenses: 0, monthlyProfit: 0,
  });
  const [recentOrders, setRecentOrders] = useState<(Order & { id: string })[]>([]);
  const [orders, setOrders] = useState<(Order & { id: string })[]>([]);
  const [expenses, setExpenses] = useState<(Expense & { id: string })[]>([]);
  const [products, setProducts] = useState<(Product & { id: string })[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!storeId) return;
    loadDashboardData();
  }, [storeId]);

  async function loadDashboardData() {
    try {
      const [productsData, customersData, ordersData, expensesData] = await Promise.all([
        getProducts(storeId),
        getCustomers(storeId),
        getOrders(storeId),
        getExpenses(storeId),
      ]);

      setProducts(productsData);
      setOrders(ordersData);
      setExpenses(expensesData);

      const today = new Date().toISOString().split('T')[0];
      const todayOrders = ordersData.filter((o) => o.createdAt?.startsWith(today));
      const todayExpenses = expensesData.filter((e) => e.date === today);

      const thisMonth = today.slice(0, 7);
      const monthlyOrders = ordersData.filter((o) => o.createdAt?.startsWith(thisMonth));
      const monthlyExp = expensesData.filter((e) => e.date.startsWith(thisMonth));

      const todayRev = todayOrders.reduce((sum, o) => sum + o.totalAmount, 0);
      const todayExp = todayExpenses.reduce((sum, e) => sum + e.amount, 0);
      const monthRev = monthlyOrders.reduce((sum, o) => sum + o.totalAmount, 0);
      const monthExp = monthlyExp.reduce((sum, e) => sum + e.amount, 0);

      setStats({
        totalProducts: productsData.length,
        lowStockProducts: productsData.filter((p) => p.stock < 10).length,
        totalCustomers: customersData.length,
        totalCustomersWithDebt: customersData.filter((c) => c.debtAmount > 0).length,
        todayOrders: todayOrders.length,
        todayRevenue: todayRev,
        totalDebt: customersData.reduce((sum, c) => sum + c.debtAmount, 0),
        todayExpenses: todayExp,
        todayProfit: todayRev - todayExp,
        monthlyRevenue: monthRev,
        monthlyExpenses: monthExp,
        monthlyProfit: monthRev - monthExp,
      });

      setRecentOrders(ordersData.slice(0, 5));
    } catch (error) {
      console.error('Error loading dashboard:', error);
    } finally {
      setLoading(false);
    }
  }

  // Weekly chart data
  const weeklyData = useMemo(() => {
    const data: { day: string; revenue: number; expenses: number }[] = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      const dayName = date.toLocaleDateString('vi-VN', { weekday: 'short' });
      
      const dayOrders = orders.filter((o) => o.createdAt?.startsWith(dateStr));
      const dayExp = expenses.filter((e) => e.date === dateStr);
      
      data.push({
        day: dayName,
        revenue: dayOrders.reduce((sum, o) => sum + o.totalAmount, 0),
        expenses: dayExp.reduce((sum, e) => sum + e.amount, 0),
      });
    }
    return data;
  }, [orders, expenses]);

  // Top products
  const topProducts = useMemo(() => {
    const productSales: Record<string, { name: string; sales: number }> = {};
    orders.forEach((order) => {
      order.items.forEach((item) => {
        if (!productSales[item.productId]) {
          productSales[item.productId] = { name: item.productName, sales: 0 };
        }
        productSales[item.productId].sales += item.subtotal;
      });
    });
    return Object.values(productSales)
      .sort((a, b) => b.sales - a.sales)
      .slice(0, 5);
  }, [orders]);

  const formatCurrency = (amount: number) => 
    new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(amount);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="w-12 h-12 border-4 border-emerald-200 border-t-emerald-600 rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-emerald-900">Tổng quan</h1>
        <div className="flex items-center gap-2">
          <Sparkles className="w-5 h-5 text-amber-500" />
          <span className="text-sm text-emerald-600">AI đang phân tích dữ liệu của bạn</span>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard 
          title="Doanh thu hôm nay" 
          value={formatCurrency(stats.todayRevenue)}
          icon={DollarSign}
          trend={stats.todayRevenue > stats.todayExpenses ? 'up' : 'down'}
          trendValue={`${stats.todayOrders} đơn`}
          color="emerald"
        />
        <StatCard 
          title="Chi phí hôm nay" 
          value={formatCurrency(stats.todayExpenses)}
          icon={Wallet}
          trend={stats.todayExpenses > stats.todayRevenue ? 'up' : 'down'}
          trendValue={`Lợi nhuận: ${formatCurrency(stats.todayProfit)}`}
          color="red"
        />
        <StatCard 
          title="Doanh thu tháng" 
          value={formatCurrency(stats.monthlyRevenue)}
          icon={TrendingUp}
          trend="up"
          trendValue={`${formatCurrency(stats.monthlyProfit)} lợi nhuận`}
          color="emerald"
        />
        <StatCard 
          title="Sản phẩm sắp hết" 
          value={stats.lowStockProducts}
          icon={AlertCircle}
          trend={stats.lowStockProducts > 0 ? 'up' : 'down'}
          trendValue={`/ ${stats.totalProducts} tổng`}
          color="amber"
        />
      </div>

      {/* Charts Row */}
      <div className="grid lg:grid-cols-3 gap-6">
        {/* Revenue Chart */}
        <div className="lg:col-span-2 bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-emerald-900 flex items-center gap-2">
              <BarChart3 className="w-5 h-5 text-emerald-600" />
              Doanh thu 7 ngày qua
            </h3>
          </div>
          <ResponsiveContainer width="100%" height={250}>
            <AreaChart data={weeklyData}>
              <defs>
                <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#d1fae5" />
              <XAxis dataKey="day" stroke="#059669" />
              <YAxis tickFormatter={(v) => `${v/1000000}M`} stroke="#059669" />
              <Tooltip formatter={(v: number) => formatCurrency(v)} />
              <Area type="monotone" dataKey="revenue" stroke="#10b981" fillOpacity={1} fill="url(#colorRevenue)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Top Products */}
        <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
          <h3 className="font-semibold text-emerald-900 mb-4">Top sản phẩm</h3>
          <div className="space-y-3">
            {topProducts.map((p, i) => (
              <div key={i} className="flex items-center gap-3">
                <div className="w-6 h-6 rounded-full bg-emerald-100 flex items-center justify-center text-xs font-semibold text-emerald-700">
                  {i + 1}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm text-emerald-900 truncate">{p.name}</p>
                </div>
                <p className="text-sm font-medium text-emerald-600">{formatCurrency(p.sales)}</p>
              </div>
            ))}
            {topProducts.length === 0 && (
              <p className="text-sm text-emerald-400 text-center py-4">Chưa có dữ liệu</p>
            )}
          </div>
        </div>
      </div>

      {/* Recent Orders */}
      <div className="bg-white rounded-xl border border-emerald-100 overflow-hidden shadow-sm">
        <div className="p-4 border-b border-emerald-50">
          <h3 className="font-semibold text-emerald-900">Đơn hàng gần đây</h3>
        </div>
        <div className="divide-y divide-emerald-50">
          {recentOrders.map((order) => (
            <div key={order.id} className="flex items-center justify-between p-4 hover:bg-emerald-50/30">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-emerald-100 flex items-center justify-center">
                  <ShoppingCart className="w-5 h-5 text-emerald-600" />
                </div>
                <div>
                  <p className="font-medium text-emerald-900">{order.customerName || 'Khách vãng lai'}</p>
                  <p className="text-xs text-emerald-600/70">
                    {new Date(order.createdAt).toLocaleString('vi-VN')}
                  </p>
                </div>
              </div>
              <div className="text-right">
                <p className="font-semibold text-emerald-900">{formatCurrency(order.totalAmount)}</p>
                <p className="text-xs text-emerald-600/70">{order.items.length} sản phẩm</p>
              </div>
            </div>
          ))}
          {recentOrders.length === 0 && (
            <div className="p-8 text-center text-emerald-400">
              <Package className="w-12 h-12 mx-auto mb-2" />
              <p>Chưa có đơn hàng nào</p>
            </div>
          )}
        </div>
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
        <h2 className="text-lg font-semibold text-emerald-900 mb-4">Đơn hàng gần đây</h2>
        {recentOrders.length === 0 ? (
          <p className="text-emerald-600/70">Chưa có đơn hàng nào</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-emerald-100">
                  <th className="text-left py-2 px-4 text-sm font-medium text-emerald-700">Mã đơn</th>
                  <th className="text-left py-2 px-4 text-sm font-medium text-emerald-700">Khách hàng</th>
                  <th className="text-right py-2 px-4 text-sm font-medium text-emerald-700">Tổng tiền</th>
                  <th className="text-left py-2 px-4 text-sm font-medium text-emerald-700">Thanh toán</th>
                  <th className="text-left py-2 px-4 text-sm font-medium text-emerald-700">Ngày</th>
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
                    <td className="py-2 px-4 text-sm text-emerald-600/70">
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
  icon: Icon,
  trend,
  trendValue,
  color = 'emerald',
}: {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: any;
  trend?: 'up' | 'down';
  trendValue?: string;
  color?: 'emerald' | 'red' | 'amber' | 'blue';
}) {
  const colorClasses = {
    emerald: 'bg-emerald-50 text-emerald-600',
    red: 'bg-red-50 text-red-600',
    amber: 'bg-amber-50 text-amber-600',
    blue: 'bg-blue-50 text-blue-600',
  };

  return (
    <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <p className="text-sm text-emerald-600">{title}</p>
          <p className="text-xl font-bold text-emerald-900 mt-1">{value}</p>
          {trendValue && (
            <div className="flex items-center gap-1 mt-1">
              {trend === 'up' ? (
                <ArrowUpRight className="w-3 h-3 text-emerald-500" />
              ) : trend === 'down' ? (
                <ArrowDownRight className="w-3 h-3 text-red-500" />
              ) : null}
              <span className={`text-xs ${trend === 'up' ? 'text-emerald-600' : trend === 'down' ? 'text-red-600' : 'text-emerald-600/70'}`}>
                {trendValue}
              </span>
            </div>
          )}
          {subtitle && !trendValue && (
            <p className="text-xs text-emerald-600/70 mt-1">{subtitle}</p>
          )}
        </div>
        <div className={`p-2 rounded-lg ${colorClasses[color]}`}>
          <Icon className="w-5 h-5" />
        </div>
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
