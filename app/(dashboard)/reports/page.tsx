'use client';

import { useEffect, useState, useMemo } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { getOrders, getProducts, getCustomers, getExpenses, Order, Product, Customer, Expense } from '@/lib/firestore';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip as RechartsTooltip, 
  Legend, 
  ResponsiveContainer,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  Area,
  AreaChart
} from 'recharts';
import { 
  TrendingUp, 
  TrendingDown, 
  Package, 
  Users, 
  DollarSign,
  Calendar,
  Download,
  Filter,
  BarChart3,
  PieChart as PieChartIcon,
  LineChart as LineChartIcon,
  ArrowUpRight,
  ArrowDownRight
} from 'lucide-react';

const COLORS = ['#10b981', '#3b82f6', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#14b8a6', '#6366f1'];

interface ReportData {
  revenue: number;
  expenses: number;
  profit: number;
  orders: number;
  products: number;
  customers: number;
}

export default function ReportsPage() {
  const { user } = useAuth();
  const storeId = user?.storeId;
  const [loading, setLoading] = useState(true);
  const [timeRange, setTimeRange] = useState<'7days' | '30days' | '90days' | '1year'>('30days');
  const [activeTab, setActiveTab] = useState<'overview' | 'revenue' | 'products' | 'customers'>('overview');
  
  const [orders, setOrders] = useState<(Order & { id: string })[]>([]);
  const [products, setProducts] = useState<(Product & { id: string })[]>([]);
  const [customers, setCustomers] = useState<(Customer & { id: string })[]>([]);
  const [expenses, setExpenses] = useState<(Expense & { id: string })[]>([]);

  useEffect(() => {
    if (storeId) {
      loadData();
    }
  }, [storeId, timeRange]);

  const loadData = async () => {
    if (!storeId) return;
    setLoading(true);
    try {
      const [ordersData, productsData, customersData, expensesData] = await Promise.all([
        getOrders(storeId),
        Promise.resolve([]), // We'll get products from orders or separately
        Promise.resolve([]), // Customers from orders
        getExpenses(storeId),
      ]);
      setOrders(ordersData);
      setExpenses(expensesData);
      // Products and customers will be derived from orders
    } catch (error) {
      console.error('Error loading report data:', error);
    } finally {
      setLoading(false);
    }
  };

  // Calculate date range
  const getDateRange = () => {
    const end = new Date();
    const start = new Date();
    switch (timeRange) {
      case '7days': start.setDate(end.getDate() - 7); break;
      case '30days': start.setDate(end.getDate() - 30); break;
      case '90days': start.setDate(end.getDate() - 90); break;
      case '1year': start.setFullYear(end.getFullYear() - 1); break;
    }
    return { start, end };
  };

  const { start: startDate, end: endDate } = getDateRange();

  // Filter data by date range
  const filteredOrders = useMemo(() => {
    return orders.filter(order => {
      const orderDate = new Date(order.createdAt);
      return orderDate >= startDate && orderDate <= endDate;
    });
  }, [orders, startDate, endDate]);

  const filteredExpenses = useMemo(() => {
    return expenses.filter(expense => {
      const expenseDate = new Date(expense.date);
      return expenseDate >= startDate && expenseDate <= endDate;
    });
  }, [expenses, startDate, endDate]);

  // Calculate statistics
  const stats = useMemo(() => {
    const revenue = filteredOrders.reduce((sum, o) => sum + o.totalAmount, 0);
    const expenses = filteredExpenses.reduce((sum, e) => sum + e.amount, 0);
    const profit = revenue - expenses;
    const orderCount = filteredOrders.length;
    
    // Unique customers
    const uniqueCustomers = new Set(filteredOrders.map(o => o.customerId).filter(Boolean)).size;
    
    // Products sold
    const productsSold = filteredOrders.reduce((sum, o) => 
      sum + o.items.reduce((itemSum, item) => itemSum + item.quantity, 0), 0
    );

    return {
      revenue,
      expenses,
      profit,
      orderCount,
      uniqueCustomers,
      productsSold,
      avgOrderValue: orderCount > 0 ? revenue / orderCount : 0,
    };
  }, [filteredOrders, filteredExpenses]);

  // Revenue by day chart data
  const revenueByDay = useMemo(() => {
    const data: Record<string, { date: string; revenue: number; expenses: number; profit: number }> = {};
    
    // Initialize all days in range
    const days = Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24));
    for (let i = 0; i <= days; i++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + i);
      const dateStr = date.toISOString().split('T')[0];
      data[dateStr] = { date: dateStr, revenue: 0, expenses: 0, profit: 0 };
    }
    
    // Add orders
    filteredOrders.forEach(order => {
      const dateStr = new Date(order.createdAt).toISOString().split('T')[0];
      if (data[dateStr]) {
        data[dateStr].revenue += order.totalAmount;
      }
    });
    
    // Add expenses
    filteredExpenses.forEach(expense => {
      const dateStr = expense.date;
      if (data[dateStr]) {
        data[dateStr].expenses += expense.amount;
      }
    });
    
    // Calculate profit
    Object.values(data).forEach(day => {
      day.profit = day.revenue - day.expenses;
    });
    
    return Object.values(data).sort((a, b) => a.date.localeCompare(b.date));
  }, [filteredOrders, filteredExpenses, startDate, endDate]);

  // Top products
  const topProducts = useMemo(() => {
    const productSales: Record<string, { name: string; quantity: number; revenue: number }> = {};
    
    filteredOrders.forEach(order => {
      order.items.forEach(item => {
        if (!productSales[item.productId]) {
          productSales[item.productId] = { name: item.productName, quantity: 0, revenue: 0 };
        }
        productSales[item.productId].quantity += item.quantity;
        productSales[item.productId].revenue += item.subtotal;
      });
    });
    
    return Object.values(productSales)
      .sort((a, b) => b.revenue - a.revenue)
      .slice(0, 10);
  }, [filteredOrders]);

  // Payment methods
  const paymentMethods = useMemo(() => {
    const methods: Record<string, { name: string; value: number; count: number }> = {
      cash: { name: 'Tiền mặt', value: 0, count: 0 },
      transfer: { name: 'Chuyển khoản', value: 0, count: 0 },
      debt: { name: 'Công nợ', value: 0, count: 0 },
    };
    
    filteredOrders.forEach(order => {
      const method = order.paymentMethod || 'cash';
      if (methods[method]) {
        methods[method].value += order.totalAmount;
        methods[method].count += 1;
      }
    });
    
    return Object.values(methods).filter(m => m.count > 0);
  }, [filteredOrders]);

  // Expense categories
  const expenseCategories = useMemo(() => {
    const categories: Record<string, { name: string; value: number }> = {};
    
    filteredExpenses.forEach(expense => {
      const categoryNames: Record<string, string> = {
        rent: 'Tiền thuê',
        salary: 'Lương',
        utilities: 'Điện nước',
        marketing: 'Marketing',
        inventory: 'Nhập hàng',
        equipment: 'Thiết bị',
        maintenance: 'Sửa chữa',
        other: 'Khác',
      };
      
      const name = categoryNames[expense.category] || expense.category;
      categories[name] = { name, value: (categories[name]?.value || 0) + expense.amount };
    });
    
    return Object.values(categories).sort((a, b) => b.value - a.value);
  }, [filteredExpenses]);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(amount);
  };

  const formatNumber = (num: number) => {
    return new Intl.NumberFormat('vi-VN').format(num);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="flex flex-col items-center gap-4">
          <div className="w-10 h-10 border-4 border-emerald-200 border-t-emerald-600 rounded-full animate-spin" />
          <p className="text-emerald-600">Đang tải báo cáo...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center">
            <BarChart3 className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-emerald-900">Báo cáo & Phân tích</h1>
            <p className="text-emerald-600/70 text-sm">Thống kê chi tiết cửa hàng</p>
          </div>
        </div>
        
        <div className="flex items-center gap-3">
          <select
            value={timeRange}
            onChange={(e) => setTimeRange(e.target.value as any)}
            className="px-4 py-2.5 border border-emerald-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900 bg-white"
          >
            <option value="7days">7 ngày qua</option>
            <option value="30days">30 ngày qua</option>
            <option value="90days">90 ngày qua</option>
            <option value="1year">1 năm qua</option>
          </select>
          <button className="px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-medium transition-colors flex items-center gap-2">
            <Download className="w-4 h-4" />
            Xuất Excel
          </button>
        </div>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-emerald-600">Doanh thu</p>
              <p className="text-xl font-bold text-emerald-900">{formatCurrency(stats.revenue)}</p>
              <div className="flex items-center gap-1 mt-1">
                <ArrowUpRight className="w-3 h-3 text-emerald-500" />
                <span className="text-xs text-emerald-600">+12.5%</span>
              </div>
            </div>
            <div className="w-12 h-12 rounded-xl bg-emerald-50 flex items-center justify-center">
              <DollarSign className="w-6 h-6 text-emerald-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-emerald-600">Chi phí</p>
              <p className="text-xl font-bold text-emerald-900">{formatCurrency(stats.expenses)}</p>
              <div className="flex items-center gap-1 mt-1">
                <ArrowDownRight className="w-3 h-3 text-red-500" />
                <span className="text-xs text-red-600">+5.2%</span>
              </div>
            </div>
            <div className="w-12 h-12 rounded-xl bg-red-50 flex items-center justify-center">
              <TrendingDown className="w-6 h-6 text-red-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-emerald-600">Lợi nhuận</p>
              <p className="text-xl font-bold text-emerald-900">{formatCurrency(stats.profit)}</p>
              <div className="flex items-center gap-1 mt-1">
                <ArrowUpRight className="w-3 h-3 text-emerald-500" />
                <span className="text-xs text-emerald-600">+18.3%</span>
              </div>
            </div>
            <div className="w-12 h-12 rounded-xl bg-emerald-50 flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-emerald-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-emerald-600">Đơn hàng</p>
              <p className="text-xl font-bold text-emerald-900">{formatNumber(stats.orderCount)}</p>
              <p className="text-xs text-emerald-600/70 mt-1">TB: {formatCurrency(stats.avgOrderValue)}</p>
            </div>
            <div className="w-12 h-12 rounded-xl bg-emerald-50 flex items-center justify-center">
              <Package className="w-6 h-6 text-emerald-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-emerald-100">
        <nav className="flex gap-1">
          {[
            { id: 'overview', label: 'Tổng quan', icon: BarChart3 },
            { id: 'revenue', label: 'Doanh thu', icon: LineChartIcon },
            { id: 'products', label: 'Sản phẩm', icon: Package },
            { id: 'customers', label: 'Khách hàng', icon: Users },
          ].map((tab) => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
                  activeTab === tab.id
                    ? 'border-emerald-500 text-emerald-600'
                    : 'border-transparent text-emerald-600/60 hover:text-emerald-700'
                }`}
              >
                <Icon className="w-4 h-4" />
                {tab.label}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Overview Tab */}
      {activeTab === 'overview' && (
        <div className="grid lg:grid-cols-2 gap-6">
          {/* Revenue vs Expenses Chart */}
          <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm lg:col-span-2">
            <h3 className="font-semibold text-emerald-900 mb-4">Doanh thu & Chi phí theo thời gian</h3>
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={revenueByDay}>
                <defs>
                  <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                  </linearGradient>
                  <linearGradient id="colorProfit" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#d1fae5" />
                <XAxis dataKey="date" tickFormatter={(date) => new Date(date).getDate().toString()} stroke="#059669" />
                <YAxis tickFormatter={(value) => `${(value / 1000000).toFixed(0)}M`} stroke="#059669" />
                <RechartsTooltip 
                  formatter={(value: number) => formatCurrency(value)}
                  labelFormatter={(label) => new Date(label).toLocaleDateString('vi-VN')}
                />
                <Legend />
                <Area type="monotone" dataKey="revenue" stroke="#10b981" fillOpacity={1} fill="url(#colorRevenue)" name="Doanh thu" />
                <Area type="monotone" dataKey="profit" stroke="#3b82f6" fillOpacity={1} fill="url(#colorProfit)" name="Lợi nhuận" />
              </AreaChart>
            </ResponsiveContainer>
          </div>

          {/* Payment Methods */}
          <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
            <h3 className="font-semibold text-emerald-900 mb-4">Phương thức thanh toán</h3>
            {paymentMethods.length > 0 ? (
              <ResponsiveContainer width="100%" height={250}>
                <PieChart>
                  <Pie
                    data={paymentMethods}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={100}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {paymentMethods.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <RechartsTooltip formatter={(value: number) => formatCurrency(value)} />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-[250px] flex items-center justify-center">
                <p className="text-emerald-400">Chưa có dữ liệu</p>
              </div>
            )}
          </div>

          {/* Expense Categories */}
          <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
            <h3 className="font-semibold text-emerald-900 mb-4">Phân bổ chi phí</h3>
            {expenseCategories.length > 0 ? (
              <ResponsiveContainer width="100%" height={250}>
                <PieChart>
                  <Pie
                    data={expenseCategories}
                    cx="50%"
                    cy="50%"
                    outerRadius={100}
                    dataKey="value"
                  >
                    {expenseCategories.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <RechartsTooltip formatter={(value: number) => formatCurrency(value)} />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-[250px] flex items-center justify-center">
                <p className="text-emerald-400">Chưa có dữ liệu chi phí</p>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Revenue Tab */}
      {activeTab === 'revenue' && (
        <div className="space-y-6">
          <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
            <h3 className="font-semibold text-emerald-900 mb-4">Chi tiết doanh thu theo ngày</h3>
            <ResponsiveContainer width="100%" height={400}>
              <BarChart data={revenueByDay}>
                <CartesianGrid strokeDasharray="3 3" stroke="#d1fae5" />
                <XAxis dataKey="date" tickFormatter={(date) => new Date(date).getDate().toString()} stroke="#059669" />
                <YAxis tickFormatter={(value) => `${(value / 1000000).toFixed(0)}M`} stroke="#059669" />
                <RechartsTooltip formatter={(value: number) => formatCurrency(value)} />
                <Legend />
                <Bar dataKey="revenue" fill="#10b981" name="Doanh thu" radius={[4, 4, 0, 0]} />
                <Bar dataKey="expenses" fill="#ef4444" name="Chi phí" radius={[4, 4, 0, 0]} />
                <Bar dataKey="profit" fill="#3b82f6" name="Lợi nhuận" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      {/* Products Tab */}
      {activeTab === 'products' && (
        <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
          <h3 className="font-semibold text-emerald-900 mb-4">Top 10 sản phẩm bán chạy</h3>
          {topProducts.length > 0 ? (
            <div className="space-y-3">
              {topProducts.map((product, index) => (
                <div key={index} className="flex items-center gap-4 p-3 bg-emerald-50/30 rounded-lg">
                  <div className="w-8 h-8 rounded-full bg-emerald-100 flex items-center justify-center font-semibold text-emerald-700">
                    {index + 1}
                  </div>
                  <div className="flex-1">
                    <p className="font-medium text-emerald-900">{product.name}</p>
                    <p className="text-sm text-emerald-600">{formatNumber(product.quantity)} sản phẩm</p>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-emerald-900">{formatCurrency(product.revenue)}</p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="p-8 text-center">
              <Package className="w-12 h-12 text-emerald-300 mx-auto mb-3" />
              <p className="text-emerald-600">Chưa có dữ liệu sản phẩm</p>
            </div>
          )}
        </div>
      )}

      {/* Customers Tab */}
      {activeTab === 'customers' && (
        <div className="grid lg:grid-cols-2 gap-6">
          <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
            <h3 className="font-semibold text-emerald-900 mb-4">Thống kê khách hàng</h3>
            <div className="grid grid-cols-2 gap-4">
              <div className="p-4 bg-emerald-50/50 rounded-xl">
                <p className="text-sm text-emerald-600">Khách hàng mới</p>
                <p className="text-2xl font-bold text-emerald-900">{formatNumber(stats.uniqueCustomers)}</p>
              </div>
              <div className="p-4 bg-emerald-50/50 rounded-xl">
                <p className="text-sm text-emerald-600">Giá trị TB/đơn</p>
                <p className="text-2xl font-bold text-emerald-900">{formatCurrency(stats.avgOrderValue)}</p>
              </div>
              <div className="p-4 bg-emerald-50/50 rounded-xl">
                <p className="text-sm text-emerald-600">Tổng SP đã bán</p>
                <p className="text-2xl font-bold text-emerald-900">{formatNumber(stats.productsSold)}</p>
              </div>
              <div className="p-4 bg-emerald-50/50 rounded-xl">
                <p className="text-sm text-emerald-600">Tỷ suất lợi nhuận</p>
                <p className="text-2xl font-bold text-emerald-900">
                  {stats.revenue > 0 ? ((stats.profit / stats.revenue) * 100).toFixed(1) : 0}%
                </p>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
