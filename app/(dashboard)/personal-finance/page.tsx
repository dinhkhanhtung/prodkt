'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { 
  getPersonalTransactions, 
  addPersonalTransaction,
  deletePersonalTransaction,
  PERSONAL_CATEGORIES,
  PersonalTransaction,
  WithId 
} from '@/lib/firestore';
import { 
  Wallet, 
  TrendingUp, 
  TrendingDown, 
  Plus, 
  Trash2,
  Calendar,
  Search,
  ArrowUpRight,
  ArrowDownRight
} from 'lucide-react';
import { format, startOfMonth, endOfMonth, parseISO } from 'date-fns';
import { vi } from 'date-fns/locale';

export default function PersonalFinancePage() {
  const { user } = useAuth();
  const [transactions, setTransactions] = useState<WithId<PersonalTransaction>[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [filterType, setFilterType] = useState<'all' | 'income' | 'expense'>('all');
  const [formData, setFormData] = useState({
    type: 'expense' as 'income' | 'expense',
    amount: '',
    category: '',
    note: '',
    date: new Date().toISOString().split('T')[0],
  });

  useEffect(() => {
    if (user?.uid) {
      loadTransactions();
    }
  }, [user?.uid]);

  const loadTransactions = async () => {
    if (!user?.uid) return;
    try {
      const start = startOfMonth(new Date()).toISOString().split('T')[0];
      const end = endOfMonth(new Date()).toISOString().split('T')[0];
      const data = await getPersonalTransactions(user.uid, start, end);
      setTransactions(data);
    } catch (error) {
      console.error('Error loading transactions:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user?.uid || !formData.amount || !formData.category) return;

    try {
      await addPersonalTransaction(user.uid, {
        type: formData.type,
        amount: parseFloat(formData.amount),
        category: formData.category,
        note: formData.note,
        date: formData.date,
      });
      
      setShowModal(false);
      setFormData({
        type: 'expense',
        amount: '',
        category: '',
        note: '',
        date: new Date().toISOString().split('T')[0],
      });
      loadTransactions();
    } catch (error) {
      console.error('Error adding transaction:', error);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Xóa giao dịch này?')) return;
    try {
      await deletePersonalTransaction(id);
      loadTransactions();
    } catch (error) {
      console.error('Error deleting:', error);
    }
  };

  const filteredTransactions = transactions.filter(t => 
    filterType === 'all' || t.type === filterType
  );

  const totalIncome = transactions
    .filter(t => t.type === 'income')
    .reduce((sum, t) => sum + t.amount, 0);
  
  const totalExpense = transactions
    .filter(t => t.type === 'expense')
    .reduce((sum, t) => sum + t.amount, 0);
  
  const balance = totalIncome - totalExpense;

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
      maximumFractionDigits: 0,
    }).format(amount);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center">
            <Wallet className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-emerald-900">Tài chính cá nhân</h1>
            <p className="text-emerald-600/70 text-sm">Quản lý thu chi cá nhân của bạn</p>
          </div>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="px-4 py-2 bg-gradient-to-r from-emerald-600 to-teal-600 text-white rounded-lg font-medium transition-all hover:opacity-90 flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          Thêm giao dịch
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-emerald-600">Tổng thu nhập</p>
              <p className="text-xl font-bold text-emerald-900 mt-1">{formatCurrency(totalIncome)}</p>
            </div>
            <div className="p-2 bg-emerald-50 rounded-lg">
              <TrendingUp className="w-5 h-5 text-emerald-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-red-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-red-600">Tổng chi tiêu</p>
              <p className="text-xl font-bold text-red-900 mt-1">{formatCurrency(totalExpense)}</p>
            </div>
            <div className="p-2 bg-red-50 rounded-lg">
              <TrendingDown className="w-5 h-5 text-red-600" />
            </div>
          </div>
        </div>

        <div className={`bg-white rounded-xl border p-4 shadow-sm ${balance >= 0 ? 'border-emerald-100' : 'border-red-100'}`}>
          <div className="flex items-center justify-between">
            <div>
              <p className={`text-sm ${balance >= 0 ? 'text-emerald-600' : 'text-red-600'}`}>Số dư</p>
              <p className={`text-xl font-bold mt-1 ${balance >= 0 ? 'text-emerald-900' : 'text-red-900'}`}>
                {formatCurrency(balance)}
              </p>
            </div>
            <div className={`p-2 rounded-lg ${balance >= 0 ? 'bg-emerald-50' : 'bg-red-50'}`}>
              <Wallet className={`w-5 h-5 ${balance >= 0 ? 'text-emerald-600' : 'text-red-600'}`} />
            </div>
          </div>
        </div>
      </div>

      {/* Filter */}
      <div className="flex gap-2">
        {(['all', 'income', 'expense'] as const).map((type) => (
          <button
            key={type}
            onClick={() => setFilterType(type)}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              filterType === type
                ? 'bg-emerald-600 text-white'
                : 'bg-white text-emerald-700 hover:bg-emerald-50 border border-emerald-200'
            }`}
          >
            {type === 'all' ? 'Tất cả' : type === 'income' ? 'Thu nhập' : 'Chi tiêu'}
          </button>
        ))}
      </div>

      {/* Transactions List */}
      <div className="bg-white rounded-xl border border-emerald-100 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-emerald-100">
          <h2 className="font-semibold text-emerald-900">Giao dịch tháng này</h2>
        </div>
        
        {loading ? (
          <div className="p-8 text-center">
            <div className="w-8 h-8 border-4 border-emerald-200 border-t-emerald-600 rounded-full animate-spin mx-auto" />
          </div>
        ) : filteredTransactions.length === 0 ? (
          <div className="p-8 text-center">
            <Wallet className="w-12 h-12 text-emerald-300 mx-auto mb-3" />
            <p className="text-emerald-600">Chưa có giao dịch nào</p>
            <p className="text-sm text-emerald-500 mt-1">Thêm giao dịch đầu tiên của bạn</p>
          </div>
        ) : (
          <div className="divide-y divide-emerald-50">
            {filteredTransactions.map((transaction) => (
              <div key={transaction.id} className="p-4 flex items-center justify-between hover:bg-emerald-50/50">
                <div className="flex items-center gap-3">
                  <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                    transaction.type === 'income' ? 'bg-emerald-100' : 'bg-red-100'
                  }`}>
                    {transaction.type === 'income' ? (
                      <ArrowUpRight className="w-5 h-5 text-emerald-600" />
                    ) : (
                      <ArrowDownRight className="w-5 h-5 text-red-600" />
                    )}
                  </div>
                  <div>
                    <p className="font-medium text-emerald-900">
                      {PERSONAL_CATEGORIES[transaction.type][transaction.category as keyof typeof PERSONAL_CATEGORIES['income']] || transaction.category}
                    </p>
                    <p className="text-sm text-emerald-600">{transaction.note}</p>
                    <p className="text-xs text-emerald-400">
                      {format(parseISO(transaction.date), 'dd/MM/yyyy', { locale: vi })}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <p className={`font-bold ${transaction.type === 'income' ? 'text-emerald-600' : 'text-red-600'}`}>
                    {transaction.type === 'income' ? '+' : '-'}{formatCurrency(transaction.amount)}
                  </p>
                  <button
                    onClick={() => handleDelete(transaction.id!)}
                    className="p-2 text-emerald-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md">
            <div className="p-4 border-b border-emerald-100">
              <h3 className="font-semibold text-emerald-900">Thêm giao dịch</h3>
            </div>
            <form onSubmit={handleSubmit} className="p-4 space-y-4">
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
                <label className="block text-sm font-medium text-emerald-700 mb-1">Ghi chú</label>
                <input
                  type="text"
                  value={formData.note}
                  onChange={(e) => setFormData({ ...formData, note: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  placeholder="Ghi chú (tùy chọn)"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Ngày</label>
                <input
                  type="date"
                  value={formData.date}
                  onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  required
                />
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
                  Thêm
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
