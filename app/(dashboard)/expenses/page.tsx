'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { 
  getExpenses, 
  addExpense, 
  updateExpense, 
  deleteExpense,
  EXPENSE_CATEGORIES,
  Expense,
  WithId 
} from '@/lib/firestore';
import { 
  Plus, 
  Search, 
  Trash2, 
  Edit2, 
  X, 
  TrendingUp,
  TrendingDown,
  Wallet,
  Calendar,
  Filter,
  ArrowLeftRight,
  DollarSign
} from 'lucide-react';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip as RechartsTooltip, Legend } from 'recharts';

const COLORS = ['#10b981', '#3b82f6', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#6b7280', '#14b8a6'];

export default function ExpensesPage() {
  const { user } = useAuth();
  const storeId = user?.storeId;
  const [expenses, setExpenses] = useState<WithId<Expense>[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedMonth, setSelectedMonth] = useState(new Date().toISOString().slice(0, 7));
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  
  // Modal states
  const [showModal, setShowModal] = useState(false);
  const [editingExpense, setEditingExpense] = useState<WithId<Expense> | null>(null);
  const [formData, setFormData] = useState({
    category: 'rent' as Expense['category'],
    amount: '',
    description: '',
    date: new Date().toISOString().slice(0, 10),
    notes: '',
  });

  useEffect(() => {
    if (storeId) {
      loadExpenses();
    }
  }, [storeId, selectedMonth]);

  const loadExpenses = async () => {
    if (!storeId) return;
    setLoading(true);
    try {
      const startDate = `${selectedMonth}-01`;
      const endDate = `${selectedMonth}-31`;
      const data = await getExpenses(storeId, startDate, endDate);
      setExpenses(data);
    } catch (error) {
      console.error('Error loading expenses:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!storeId || !user) return;

    const amount = parseFloat(formData.amount);
    if (isNaN(amount) || amount <= 0) {
      alert('Vui lòng nhập số tiền hợp lệ');
      return;
    }

    try {
      if (editingExpense) {
        await updateExpense(storeId, editingExpense.id, {
          category: formData.category,
          amount,
          description: formData.description,
          date: formData.date,
          notes: formData.notes,
        });
      } else {
        await addExpense(user.uid, storeId, {
          category: formData.category,
          amount,
          description: formData.description,
          date: formData.date,
          notes: formData.notes,
        });
      }
      setShowModal(false);
      setEditingExpense(null);
      resetForm();
      loadExpenses();
    } catch (error) {
      console.error('Error saving expense:', error);
      alert('Có lỗi xảy ra khi lưu chi phí');
    }
  };

  const handleDelete = async (id: string) => {
    if (!storeId) return;
    if (!confirm('Bạn có chắc chắn muốn xóa chi phí này?')) return;

    try {
      await deleteExpense(storeId, id);
      loadExpenses();
    } catch (error) {
      console.error('Error deleting expense:', error);
      alert('Có lỗi xảy ra khi xóa chi phí');
    }
  };

  const handleEdit = (expense: WithId<Expense>) => {
    setEditingExpense(expense);
    setFormData({
      category: expense.category,
      amount: expense.amount.toString(),
      description: expense.description,
      date: expense.date,
      notes: expense.notes || '',
    });
    setShowModal(true);
  };

  const resetForm = () => {
    setFormData({
      category: 'rent',
      amount: '',
      description: '',
      date: new Date().toISOString().slice(0, 10),
      notes: '',
    });
  };

  const filteredExpenses = expenses.filter(expense => {
    const matchesSearch = expense.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         EXPENSE_CATEGORIES[expense.category].toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = selectedCategory === 'all' || expense.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  // Calculate statistics
  const totalAmount = expenses.reduce((sum, e) => sum + e.amount, 0);
  const categoryData = expenses.reduce((acc, expense) => {
    const category = EXPENSE_CATEGORIES[expense.category];
    acc[category] = (acc[category] || 0) + expense.amount;
    return acc;
  }, {} as Record<string, number>);

  const chartData = Object.entries(categoryData).map(([name, value]) => ({ name, value }));

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
  };

  const getCategoryIcon = (category: string) => {
    const icons: Record<string, string> = {
      rent: '🏢',
      salary: '💰',
      utilities: '💡',
      marketing: '📢',
      inventory: '📦',
      equipment: '🔧',
      maintenance: '🛠️',
      other: '📝',
    };
    return icons[category] || '📝';
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center">
            <Wallet className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-emerald-900">Quản lý chi phí</h1>
            <p className="text-emerald-600/70 text-sm">Theo dõi và quản lý chi phí cửa hàng</p>
          </div>
        </div>
        <button
          onClick={() => {
            setEditingExpense(null);
            resetForm();
            setShowModal(true);
          }}
          className="px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-medium transition-colors flex items-center gap-2 shadow-lg shadow-emerald-500/25"
        >
          <Plus className="w-5 h-5" />
          Thêm chi phí
        </button>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-emerald-600">Tổng chi phí tháng</p>
              <p className="text-2xl font-bold text-emerald-900">{formatCurrency(totalAmount)}</p>
            </div>
            <div className="w-12 h-12 rounded-xl bg-emerald-50 flex items-center justify-center">
              <TrendingDown className="w-6 h-6 text-emerald-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-emerald-600">Số giao dịch</p>
              <p className="text-2xl font-bold text-emerald-900">{expenses.length}</p>
            </div>
            <div className="w-12 h-12 rounded-xl bg-emerald-50 flex items-center justify-center">
              <ArrowLeftRight className="w-6 h-6 text-emerald-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-emerald-600">Chi phí trung bình</p>
              <p className="text-2xl font-bold text-emerald-900">
                {formatCurrency(expenses.length > 0 ? totalAmount / expenses.length : 0)}
              </p>
            </div>
            <div className="w-12 h-12 rounded-xl bg-emerald-50 flex items-center justify-center">
              <DollarSign className="w-6 h-6 text-emerald-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-emerald-600">Danh mục chi phí</p>
              <p className="text-2xl font-bold text-emerald-900">{Object.keys(categoryData).length}</p>
            </div>
            <div className="w-12 h-12 rounded-xl bg-emerald-50 flex items-center justify-center">
              <Filter className="w-6 h-6 text-emerald-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Filters and Chart */}
      <div className="grid lg:grid-cols-3 gap-6">
        {/* Filters */}
        <div className="lg:col-span-2 space-y-4">
          <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
            <div className="flex flex-col sm:flex-row gap-4">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-emerald-400" />
                <input
                  type="text"
                  placeholder="Tìm kiếm chi phí..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 border border-emerald-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900 placeholder-emerald-400/70"
                />
              </div>
              <div className="flex gap-2">
                <input
                  type="month"
                  value={selectedMonth}
                  onChange={(e) => setSelectedMonth(e.target.value)}
                  className="px-4 py-2.5 border border-emerald-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900"
                />
                <select
                  value={selectedCategory}
                  onChange={(e) => setSelectedCategory(e.target.value)}
                  className="px-4 py-2.5 border border-emerald-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900"
                >
                  <option value="all">Tất cả danh mục</option>
                  {Object.entries(EXPENSE_CATEGORIES).map(([key, label]) => (
                    <option key={key} value={key}>{label}</option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          {/* Expenses List */}
          <div className="bg-white rounded-xl border border-emerald-100 overflow-hidden shadow-sm">
            {loading ? (
              <div className="p-8 text-center">
                <div className="w-8 h-8 border-4 border-emerald-200 border-t-emerald-600 rounded-full animate-spin mx-auto" />
                <p className="text-emerald-600 mt-2">Đang tải...</p>
              </div>
            ) : filteredExpenses.length === 0 ? (
              <div className="p-8 text-center">
                <Wallet className="w-12 h-12 text-emerald-300 mx-auto mb-3" />
                <p className="text-emerald-600">Chưa có chi phí nào trong tháng này</p>
                <button
                  onClick={() => setShowModal(true)}
                  className="mt-3 text-emerald-600 hover:text-emerald-700 font-medium"
                >
                  Thêm chi phí đầu tiên
                </button>
              </div>
            ) : (
              <table className="w-full">
                <thead className="bg-emerald-50/50 border-b border-emerald-100">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-semibold text-emerald-700 uppercase">Ngày</th>
                    <th className="px-4 py-3 text-left text-xs font-semibold text-emerald-700 uppercase">Danh mục</th>
                    <th className="px-4 py-3 text-left text-xs font-semibold text-emerald-700 uppercase">Mô tả</th>
                    <th className="px-4 py-3 text-right text-xs font-semibold text-emerald-700 uppercase">Số tiền</th>
                    <th className="px-4 py-3 text-right text-xs font-semibold text-emerald-700 uppercase">Hành động</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-emerald-50">
                  {filteredExpenses.map((expense) => (
                    <tr key={expense.id} className="hover:bg-emerald-50/30">
                      <td className="px-4 py-3 text-sm text-emerald-700">
                        {new Date(expense.date).toLocaleDateString('vi-VN')}
                      </td>
                      <td className="px-4 py-3">
                        <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-sm font-medium bg-emerald-100 text-emerald-700">
                          <span>{getCategoryIcon(expense.category)}</span>
                          {EXPENSE_CATEGORIES[expense.category]}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-sm text-emerald-900">
                        {expense.description}
                        {expense.notes && (
                          <p className="text-xs text-emerald-600/70 mt-1">{expense.notes}</p>
                        )}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <span className="text-sm font-semibold text-emerald-900">
                          {formatCurrency(expense.amount)}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-right">
                        <div className="flex items-center justify-end gap-1">
                          <button
                            onClick={() => handleEdit(expense)}
                            className="p-1.5 text-emerald-600 hover:bg-emerald-100 rounded-lg transition-colors"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleDelete(expense.id)}
                            className="p-1.5 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* Chart */}
        <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
          <h3 className="font-semibold text-emerald-900 mb-4">Phân bổ chi phí</h3>
          {chartData.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={chartData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {chartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <RechartsTooltip 
                  formatter={(value) => typeof value === 'number' ? formatCurrency(value) : value}
                  contentStyle={{ borderRadius: '8px', border: '1px solid #d1fae5' }}
                />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-[300px] flex items-center justify-center">
              <p className="text-emerald-400">Chưa có dữ liệu</p>
            </div>
          )}
        </div>
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-emerald-950/50 backdrop-blur-sm" onClick={() => setShowModal(false)} />
          <div className="relative bg-white rounded-2xl shadow-2xl max-w-lg w-full p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-emerald-900">
                {editingExpense ? 'Chỉnh sửa chi phí' : 'Thêm chi phí mới'}
              </h2>
              <button onClick={() => setShowModal(false)} className="p-2 hover:bg-emerald-50 rounded-lg">
                <X className="w-5 h-5 text-emerald-600" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1.5">Danh mục</label>
                <select
                  value={formData.category}
                  onChange={(e) => setFormData({ ...formData, category: e.target.value as Expense['category'] })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900"
                >
                  {Object.entries(EXPENSE_CATEGORIES).map(([key, label]) => (
                    <option key={key} value={key}>{getCategoryIcon(key)} {label}</option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-emerald-700 mb-1.5">Số tiền</label>
                  <input
                    type="number"
                    min="0"
                    step="1000"
                    required
                    value={formData.amount}
                    onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                    className="w-full border border-emerald-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900"
                    placeholder="0"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-emerald-700 mb-1.5">Ngày</label>
                  <input
                    type="date"
                    required
                    value={formData.date}
                    onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                    className="w-full border border-emerald-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1.5">Mô tả</label>
                <input
                  type="text"
                  required
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900"
                  placeholder="Nhập mô tả chi phí..."
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1.5">Ghi chú (tùy chọn)</label>
                <textarea
                  value={formData.notes}
                  onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                  rows={3}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900 resize-none"
                  placeholder="Thêm ghi chú nếu cần..."
                />
              </div>

              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="flex-1 py-2.5 text-emerald-600 bg-emerald-50 hover:bg-emerald-100 rounded-lg font-medium transition-colors"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-medium transition-colors"
                >
                  {editingExpense ? 'Cập nhật' : 'Thêm chi phí'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
