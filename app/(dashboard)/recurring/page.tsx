'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { 
  getRecurringTransactions, 
  addRecurringTransaction,
  updateRecurringTransaction,
  deleteRecurringTransaction,
  PERSONAL_CATEGORIES,
  RecurringTransaction,
  WithId 
} from '@/lib/firestore';
import { 
  Repeat, 
  Plus, 
  Trash2,
  Edit3,
  Calendar,
  CheckCircle2,
  XCircle,
  Clock
} from 'lucide-react';
import { format, addDays, addWeeks, addMonths, addYears, parseISO } from 'date-fns';
import { vi } from 'date-fns/locale';

export default function RecurringPage() {
  const { user } = useAuth();
  const [transactions, setTransactions] = useState<WithId<RecurringTransaction>[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    type: 'expense' as 'income' | 'expense',
    amount: '',
    category: '',
    frequency: 'monthly' as RecurringTransaction['frequency'],
    startDate: new Date().toISOString().split('T')[0],
    note: '',
    active: true,
  });

  useEffect(() => {
    if (user?.uid) {
      loadTransactions();
    }
  }, [user?.uid]);

  const loadTransactions = async () => {
    if (!user?.uid) return;
    try {
      const data = await getRecurringTransactions(user.uid);
      setTransactions(data);
    } catch (error) {
      console.error('Error loading recurring:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user?.uid || !formData.amount || !formData.name || !formData.category) return;

    const data = {
      name: formData.name,
      type: formData.type,
      amount: parseFloat(formData.amount),
      category: formData.category,
      frequency: formData.frequency,
      startDate: formData.startDate,
      nextDate: formData.startDate,
      active: formData.active,
      note: formData.note,
    };

    try {
      if (editingId) {
        await updateRecurringTransaction(editingId, data);
      } else {
        await addRecurringTransaction(user.uid, data);
      }
      
      setShowModal(false);
      setEditingId(null);
      resetForm();
      loadTransactions();
    } catch (error) {
      console.error('Error saving:', error);
    }
  };

  const resetForm = () => {
    setFormData({
      name: '',
      type: 'expense',
      amount: '',
      category: '',
      frequency: 'monthly',
      startDate: new Date().toISOString().split('T')[0],
      note: '',
      active: true,
    });
  };

  const handleEdit = (transaction: WithId<RecurringTransaction>) => {
    setEditingId(transaction.id!);
    setFormData({
      name: transaction.name,
      type: transaction.type,
      amount: transaction.amount.toString(),
      category: transaction.category,
      frequency: transaction.frequency,
      startDate: transaction.startDate,
      note: transaction.note,
      active: transaction.active,
    });
    setShowModal(true);
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Xóa giao dịch định kỳ này?')) return;
    try {
      await deleteRecurringTransaction(id);
      loadTransactions();
    } catch (error) {
      console.error('Error deleting:', error);
    }
  };

  const toggleActive = async (transaction: WithId<RecurringTransaction>) => {
    try {
      await updateRecurringTransaction(transaction.id!, { active: !transaction.active });
      loadTransactions();
    } catch (error) {
      console.error('Error toggling:', error);
    }
  };

  const getFrequencyLabel = (freq: string) => {
    const labels: Record<string, string> = {
      daily: 'Hàng ngày',
      weekly: 'Hàng tuần',
      monthly: 'Hàng tháng',
      yearly: 'Hàng năm',
    };
    return labels[freq] || freq;
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const activeCount = transactions.filter(t => t.active).length;
  const monthlyTotal = transactions
    .filter(t => t.active && t.frequency === 'monthly')
    .reduce((sum, t) => sum + (t.type === 'expense' ? -t.amount : t.amount), 0);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center">
            <Repeat className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-emerald-900">Giao dịch định kỳ</h1>
            <p className="text-emerald-600/70 text-sm">Tự động hóa thu chi lặp lại</p>
          </div>
        </div>
        <button
          onClick={() => { setEditingId(null); resetForm(); setShowModal(true); }}
          className="px-4 py-2 bg-gradient-to-r from-blue-500 to-indigo-600 text-white rounded-lg font-medium transition-all hover:opacity-90 flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          Thêm mới
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white rounded-xl border border-blue-100 p-4 shadow-sm">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-50 rounded-lg">
              <CheckCircle2 className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-sm text-blue-600">Đang hoạt động</p>
              <p className="text-xl font-bold text-blue-900">{activeCount}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-emerald-50 rounded-lg">
              <Calendar className="w-5 h-5 text-emerald-600" />
            </div>
            <div>
              <p className="text-sm text-emerald-600">Tổng tháng này</p>
              <p className={`text-xl font-bold ${monthlyTotal >= 0 ? 'text-emerald-900' : 'text-red-900'}`}>
                {formatCurrency(Math.abs(monthlyTotal))}
              </p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-amber-100 p-4 shadow-sm">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-amber-50 rounded-lg">
              <Clock className="w-5 h-5 text-amber-600" />
            </div>
            <div>
              <p className="text-sm text-amber-600">Tổng giao dịch</p>
              <p className="text-xl font-bold text-amber-900">{transactions.length}</p>
            </div>
          </div>
        </div>
      </div>

      {/* List */}
      <div className="bg-white rounded-xl border border-emerald-100 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-emerald-100">
          <h2 className="font-semibold text-emerald-900">Danh sách giao dịch</h2>
        </div>
        
        {loading ? (
          <div className="p-8 text-center">
            <div className="w-8 h-8 border-4 border-emerald-200 border-t-emerald-600 rounded-full animate-spin mx-auto" />
          </div>
        ) : transactions.length === 0 ? (
          <div className="p-8 text-center">
            <Repeat className="w-12 h-12 text-emerald-300 mx-auto mb-3" />
            <p className="text-emerald-600">Chưa có giao dịch định kỳ</p>
            <p className="text-sm text-emerald-500 mt-1">Thêm để tự động hóa thu chi</p>
          </div>
        ) : (
          <div className="divide-y divide-emerald-50">
            {transactions.map((transaction) => (
              <div key={transaction.id} className="p-4 hover:bg-emerald-50/50">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <button
                      onClick={() => toggleActive(transaction)}
                      className={`w-10 h-10 rounded-full flex items-center justify-center transition-colors ${
                        transaction.active 
                          ? 'bg-emerald-100 hover:bg-emerald-200' 
                          : 'bg-gray-100 hover:bg-gray-200'
                      }`}
                    >
                      {transaction.active ? (
                        <CheckCircle2 className="w-5 h-5 text-emerald-600" />
                      ) : (
                        <XCircle className="w-5 h-5 text-gray-400" />
                      )}
                    </button>
                    <div>
                      <div className="flex items-center gap-2">
                        <p className="font-medium text-emerald-900">{transaction.name}</p>
                        <span className={`px-2 py-0.5 text-xs rounded-full ${
                          transaction.type === 'income' 
                            ? 'bg-emerald-100 text-emerald-700' 
                            : 'bg-red-100 text-red-700'
                        }`}>
                          {transaction.type === 'income' ? 'Thu' : 'Chi'}
                        </span>
                        <span className="px-2 py-0.5 bg-blue-100 text-blue-700 text-xs rounded-full">
                          {getFrequencyLabel(transaction.frequency)}
                        </span>
                      </div>
                      <p className="text-sm text-emerald-600">
                        {PERSONAL_CATEGORIES[transaction.type][transaction.category]} • {transaction.note}
                      </p>
                      <p className="text-xs text-emerald-400">
                        Lần tới: {format(parseISO(transaction.nextDate), 'dd/MM/yyyy', { locale: vi })}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <p className={`font-bold ${transaction.type === 'income' ? 'text-emerald-600' : 'text-red-600'}`}>
                      {transaction.type === 'income' ? '+' : '-'}{formatCurrency(transaction.amount)}
                    </p>
                    <button
                      onClick={() => handleEdit(transaction)}
                      className="p-2 text-emerald-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg"
                    >
                      <Edit3 className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => handleDelete(transaction.id!)}
                      className="p-2 text-emerald-400 hover:text-red-500 hover:bg-red-50 rounded-lg"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md max-h-[90vh] overflow-y-auto">
            <div className="p-4 border-b border-emerald-100">
              <h3 className="font-semibold text-emerald-900">
                {editingId ? 'Sửa giao dịch' : 'Thêm giao dịch định kỳ'}
              </h3>
            </div>
            <form onSubmit={handleSubmit} className="p-4 space-y-4">
              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Tên giao dịch</label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  placeholder="VD: Tiền thuê nhà, Lương..."
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Loại</label>
                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => setFormData({ ...formData, type: 'income', category: '' })}
                    className={`flex-1 py-2 rounded-lg border ${
                      formData.type === 'income'
                        ? 'bg-emerald-50 border-emerald-500 text-emerald-700'
                        : 'border-emerald-200 text-emerald-600'
                    }`}
                  >
                    Thu nhập
                  </button>
                  <button
                    type="button"
                    onClick={() => setFormData({ ...formData, type: 'expense', category: '' })}
                    className={`flex-1 py-2 rounded-lg border ${
                      formData.type === 'expense'
                        ? 'bg-red-50 border-red-500 text-red-700'
                        : 'border-red-200 text-red-600'
                    }`}
                  >
                    Chi tiêu
                  </button>
                </div>
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
                  {Object.entries(PERSONAL_CATEGORIES[formData.type]).map(([key, label]) => (
                    <option key={key} value={key}>{label}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Số tiền</label>
                <input
                  type="number"
                  value={formData.amount}
                  onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  placeholder="Nhập số tiền"
                  required
                  min="0"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Tần suất</label>
                <select
                  value={formData.frequency}
                  onChange={(e) => setFormData({ ...formData, frequency: e.target.value as RecurringTransaction['frequency'] })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  required
                >
                  <option value="daily">Hàng ngày</option>
                  <option value="weekly">Hàng tuần</option>
                  <option value="monthly">Hàng tháng</option>
                  <option value="yearly">Hàng năm</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Bắt đầu từ</label>
                <input
                  type="date"
                  value={formData.startDate}
                  onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Ghi chú</label>
                <input
                  type="text"
                  value={formData.note}
                  onChange={(e) => setFormData({ ...formData, note: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  placeholder="Ghi chú (tùy chọn)"
                />
              </div>

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="active"
                  checked={formData.active}
                  onChange={(e) => setFormData({ ...formData, active: e.target.checked })}
                  className="w-4 h-4 text-emerald-600 rounded"
                />
                <label htmlFor="active" className="text-sm text-emerald-700">
                  Kích hoạt ngay
                </label>
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="flex-1 px-4 py-2 border border-emerald-200 text-emerald-700 rounded-lg hover:bg-emerald-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700"
                >
                  {editingId ? 'Lưu' : 'Thêm'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
