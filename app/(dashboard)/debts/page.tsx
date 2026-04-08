'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { 
  getPersonalDebts, 
  addPersonalDebt,
  updateDebtPayment,
  deletePersonalDebt,
  PersonalDebt,
  WithId 
} from '@/lib/firestore';
import { 
  HandCoins, 
  Plus, 
  Trash2,
  ArrowRightLeft,
  CheckCircle2,
  AlertCircle,
  User
} from 'lucide-react';
import { format, parseISO, isPast } from 'date-fns';
import { vi } from 'date-fns/locale';

export default function DebtsPage() {
  const { user } = useAuth();
  const [debts, setDebts] = useState<WithId<PersonalDebt>[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [showPaymentModal, setShowPaymentModal] = useState<string | null>(null);
  const [paymentAmount, setPaymentAmount] = useState('');
  const [filter, setFilter] = useState<'all' | 'borrow' | 'lend'>('all');
  const [formData, setFormData] = useState({
    type: 'borrow' as 'borrow' | 'lend',
    personName: '',
    personPhone: '',
    amount: '',
    dueDate: '',
    note: '',
  });

  useEffect(() => {
    if (user?.uid) {
      loadDebts();
    }
  }, [user?.uid]);

  const loadDebts = async () => {
    if (!user?.uid) return;
    try {
      const data = await getPersonalDebts(user.uid);
      setDebts(data);
    } catch (error) {
      console.error('Error loading debts:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user?.uid || !formData.amount || !formData.personName) return;

    try {
      await addPersonalDebt(user.uid, {
        type: formData.type,
        personName: formData.personName,
        personPhone: formData.personPhone,
        amount: parseFloat(formData.amount),
        dueDate: formData.dueDate || undefined,
        note: formData.note,
        status: 'active',
      });
      
      setShowModal(false);
      setFormData({
        type: 'borrow',
        personName: '',
        personPhone: '',
        amount: '',
        dueDate: '',
        note: '',
      });
      loadDebts();
    } catch (error) {
      console.error('Error adding debt:', error);
    }
  };

  const handlePayment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!showPaymentModal || !paymentAmount) return;

    try {
      await updateDebtPayment(showPaymentModal, parseFloat(paymentAmount));
      setShowPaymentModal(null);
      setPaymentAmount('');
      loadDebts();
    } catch (error) {
      console.error('Error updating payment:', error);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Xóa khoản nợ này?')) return;
    try {
      await deletePersonalDebt(id);
      loadDebts();
    } catch (error) {
      console.error('Error deleting:', error);
    }
  };

  const filteredDebts = debts.filter(d => 
    filter === 'all' || d.type === filter
  );

  const totalBorrow = debts
    .filter(d => d.type === 'borrow' && d.status !== 'paid')
    .reduce((sum, d) => sum + (d.amount - d.paidAmount), 0);
  
  const totalLend = debts
    .filter(d => d.type === 'lend' && d.status !== 'paid')
    .reduce((sum, d) => sum + (d.amount - d.paidAmount), 0);

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
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center">
            <HandCoins className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-emerald-900">Quản lý nợ</h1>
            <p className="text-emerald-600/70 text-sm">Theo dõi khoản vay và cho vay</p>
          </div>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="px-4 py-2 bg-gradient-to-r from-amber-500 to-orange-500 text-white rounded-lg font-medium transition-all hover:opacity-90 flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          Thêm khoản nợ
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="bg-white rounded-xl border border-red-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-red-600">Đang nợ người khác</p>
              <p className="text-xl font-bold text-red-900 mt-1">{formatCurrency(totalBorrow)}</p>
            </div>
            <div className="p-2 bg-red-50 rounded-lg">
              <ArrowRightLeft className="w-5 h-5 text-red-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-emerald-600">Người khác nợ bạn</p>
              <p className="text-xl font-bold text-emerald-900 mt-1">{formatCurrency(totalLend)}</p>
            </div>
            <div className="p-2 bg-emerald-50 rounded-lg">
              <HandCoins className="w-5 h-5 text-emerald-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Filter */}
      <div className="flex gap-2">
        {(['all', 'borrow', 'lend'] as const).map((type) => (
          <button
            key={type}
            onClick={() => setFilter(type)}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              filter === type
                ? 'bg-amber-500 text-white'
                : 'bg-white text-amber-700 hover:bg-amber-50 border border-amber-200'
            }`}
          >
            {type === 'all' ? 'Tất cả' : type === 'borrow' ? 'Đang nợ' : 'Cho vay'}
          </button>
        ))}
      </div>

      {/* Debts List */}
      <div className="bg-white rounded-xl border border-emerald-100 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-emerald-100">
          <h2 className="font-semibold text-emerald-900">Danh sách khoản nợ</h2>
        </div>
        
        {loading ? (
          <div className="p-8 text-center">
            <div className="w-8 h-8 border-4 border-emerald-200 border-t-emerald-600 rounded-full animate-spin mx-auto" />
          </div>
        ) : filteredDebts.length === 0 ? (
          <div className="p-8 text-center">
            <HandCoins className="w-12 h-12 text-emerald-300 mx-auto mb-3" />
            <p className="text-emerald-600">Chưa có khoản nợ nào</p>
          </div>
        ) : (
          <div className="divide-y divide-emerald-50">
            {filteredDebts.map((debt) => {
              const remaining = debt.amount - debt.paidAmount;
              const isOverdue = debt.dueDate && isPast(parseISO(debt.dueDate)) && debt.status !== 'paid';
              
              return (
                <div key={debt.id} className="p-4 hover:bg-emerald-50/50">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-3">
                      <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                        debt.type === 'borrow' ? 'bg-red-100' : 'bg-emerald-100'
                      }`}>
                        <User className={`w-5 h-5 ${debt.type === 'borrow' ? 'text-red-600' : 'text-emerald-600'}`} />
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <p className="font-medium text-emerald-900">{debt.personName}</p>
                          {debt.status === 'paid' ? (
                            <span className="px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs rounded-full">Đã trả</span>
                          ) : isOverdue ? (
                            <span className="px-2 py-0.5 bg-red-100 text-red-700 text-xs rounded-full flex items-center gap-1">
                              <AlertCircle className="w-3 h-3" />
                              Quá hạn
                            </span>
                          ) : null}
                        </div>
                        <p className="text-sm text-emerald-600">{debt.note}</p>
                        {debt.dueDate && (
                          <p className="text-xs text-emerald-400">
                            Hạn trả: {format(parseISO(debt.dueDate), 'dd/MM/yyyy', { locale: vi })}
                          </p>
                        )}
                      </div>
                    </div>
                    <div className="text-right">
                      <p className={`font-bold ${debt.type === 'borrow' ? 'text-red-600' : 'text-emerald-600'}`}>
                        {formatCurrency(debt.amount)}
                      </p>
                      {debt.paidAmount > 0 && (
                        <p className="text-sm text-emerald-500">
                          Đã trả: {formatCurrency(debt.paidAmount)}
                        </p>
                      )}
                      {debt.status !== 'paid' && (
                        <p className="text-sm font-medium text-amber-600">
                          Còn: {formatCurrency(remaining)}
                        </p>
                      )}
                    </div>
                  </div>
                  
                  {debt.status !== 'paid' && (
                    <div className="flex gap-2 mt-3">
                      <button
                        onClick={() => setShowPaymentModal(debt.id!)}
                        className="flex-1 py-2 bg-emerald-50 text-emerald-700 rounded-lg text-sm font-medium hover:bg-emerald-100"
                      >
                        Trả nợ
                      </button>
                      <button
                        onClick={() => handleDelete(debt.id!)}
                        className="p-2 text-emerald-400 hover:text-red-500 hover:bg-red-50 rounded-lg"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Add Debt Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md">
            <div className="p-4 border-b border-emerald-100">
              <h3 className="font-semibold text-emerald-900">Thêm khoản nợ</h3>
            </div>
            <form onSubmit={handleSubmit} className="p-4 space-y-4">
              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Loại</label>
                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => setFormData({ ...formData, type: 'borrow' })}
                    className={`flex-1 py-2 rounded-lg border ${
                      formData.type === 'borrow'
                        ? 'bg-red-50 border-red-500 text-red-700'
                        : 'border-red-200 text-red-600'
                    }`}
                  >
                    Đang nợ
                  </button>
                  <button
                    type="button"
                    onClick={() => setFormData({ ...formData, type: 'lend' })}
                    className={`flex-1 py-2 rounded-lg border ${
                      formData.type === 'lend'
                        ? 'bg-emerald-50 border-emerald-500 text-emerald-700'
                        : 'border-emerald-200 text-emerald-600'
                    }`}
                  >
                    Cho vay
                  </button>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Tên người</label>
                <input
                  type="text"
                  value={formData.personName}
                  onChange={(e) => setFormData({ ...formData, personName: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  placeholder="Nhập tên"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Số điện thoại</label>
                <input
                  type="tel"
                  value={formData.personPhone}
                  onChange={(e) => setFormData({ ...formData, personPhone: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  placeholder="SĐT (tùy chọn)"
                />
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
                <label className="block text-sm font-medium text-emerald-700 mb-1">Hạn trả</label>
                <input
                  type="date"
                  value={formData.dueDate}
                  onChange={(e) => setFormData({ ...formData, dueDate: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Ghi chú</label>
                <input
                  type="text"
                  value={formData.note}
                  onChange={(e) => setFormData({ ...formData, note: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  placeholder="Lý do vay/cho vay"
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

      {/* Payment Modal */}
      {showPaymentModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-sm">
            <div className="p-4 border-b border-emerald-100">
              <h3 className="font-semibold text-emerald-900">Trả nợ</h3>
            </div>
            <form onSubmit={handlePayment} className="p-4 space-y-4">
              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1">Số tiền trả</label>
                <input
                  type="number"
                  value={paymentAmount}
                  onChange={(e) => setPaymentAmount(e.target.value)}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  placeholder="Nhập số tiền"
                  required
                  min="0"
                  autoFocus
                />
              </div>
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setShowPaymentModal(null)}
                  className="flex-1 px-4 py-2 border border-emerald-200 text-emerald-700 rounded-lg hover:bg-emerald-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700"
                >
                  Xác nhận
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
