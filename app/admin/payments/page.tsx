'use client';

import { useEffect, useState, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import { useAuth } from '@/components/AuthProvider';
import { 
  getPendingPayments, 
  verifyPayment, 
  rejectPayment,
  updateUserSubscription,
  getUserSubscription,
  Payment
} from '@/lib/firestore';
import { 
  CheckCircle, 
  XCircle, 
  Clock, 
  Eye,
  Search,
  Download,
  CreditCard,
  Building2,
  ArrowRight,
  Filter,
  ChevronDown
} from 'lucide-react';

interface PaymentWithId extends Payment {
  id: string;
}

function AdminPaymentsContent() {
  const { user } = useAuth();
  const searchParams = useSearchParams();
  const [payments, setPayments] = useState<PaymentWithId[]>([]);
  const [selectedPayment, setSelectedPayment] = useState<PaymentWithId | null>(null);
  const [filter, setFilter] = useState<'all' | 'pending' | 'verified' | 'rejected'>('all');
  const [loading, setLoading] = useState(true);
  const [rejectionReason, setRejectionReason] = useState('');
  const [showRejectModal, setShowRejectModal] = useState(false);

  useEffect(() => {
    loadPayments();
    const paymentId = searchParams.get('id');
    if (paymentId) {
      // Load specific payment
    }
  }, [searchParams]);

  const loadPayments = async () => {
    try {
      const pending = await getPendingPayments();
      setPayments(pending.map(p => ({ ...p, id: p.id })));
    } catch (error) {
      console.error('Error loading payments:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleVerify = async (payment: PaymentWithId) => {
    if (!user || !confirm('Xác nhận duyệt thanh toán này?')) return;

    try {
      const validUntil = new Date();
      if (payment.plan === 'monthly') {
        validUntil.setMonth(validUntil.getMonth() + 1);
      } else {
        validUntil.setFullYear(validUntil.getFullYear() + 1);
      }

      await verifyPayment(payment.id, user.uid, validUntil.toISOString());
      await updateUserSubscription(payment.userId, {
        plan: 'pro',
        status: 'active',
        startedAt: new Date().toISOString(),
        expiresAt: validUntil.toISOString(),
        lastPaymentId: payment.id,
      });

      await loadPayments();
      setSelectedPayment(null);
      alert('Đã duyệt thanh toán và kích hoạt PRO cho user!');
    } catch (error) {
      console.error('Error verifying payment:', error);
      alert('Có lỗi xảy ra khi duyệt thanh toán');
    }
  };

  const handleReject = async (payment: PaymentWithId) => {
    if (!user || !rejectionReason.trim()) return;

    try {
      await rejectPayment(payment.id, user.uid, rejectionReason);
      await loadPayments();
      setShowRejectModal(false);
      setRejectionReason('');
      setSelectedPayment(null);
      alert('Đã từ chối thanh toán');
    } catch (error) {
      console.error('Error rejecting payment:', error);
      alert('Có lỗi xảy ra khi từ chối');
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const filteredPayments = payments.filter(p => {
    if (filter === 'all') return true;
    return p.status === filter;
  });

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'verified':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium bg-gradient-to-r from-emerald-500 to-teal-500 text-white shadow-sm shadow-emerald-500/25">
            <CheckCircle className="w-4 h-4" />
            Đã duyệt
          </span>
        );
      case 'rejected':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium bg-gradient-to-r from-red-500 to-rose-500 text-white shadow-sm shadow-red-500/25">
            <XCircle className="w-4 h-4" />
            Từ chối
          </span>
        );
      case 'pending':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium bg-gradient-to-r from-amber-500 to-orange-500 text-white shadow-sm shadow-amber-500/25">
            <Clock className="w-4 h-4" />
            Chờ duyệt
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium bg-slate-100 text-slate-700">
            {status}
          </span>
        );
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold bg-gradient-to-r from-slate-900 to-slate-600 bg-clip-text text-transparent">
            Quản lý thanh toán
          </h1>
          <p className="text-slate-500 mt-1">Duyệt và quản lý các yêu cầu thanh toán</p>
        </div>
        <div className="flex items-center gap-2">
          <button className="flex items-center gap-2 px-4 py-2.5 bg-white border border-slate-200 rounded-xl text-sm font-medium text-slate-700 hover:bg-slate-50 hover:border-slate-300 transition-all">
            <Download className="w-4 h-4" />
            Export
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
        <div className="bg-gradient-to-br from-violet-500 to-indigo-600 rounded-2xl p-5 text-white shadow-lg shadow-violet-500/25">
          <p className="text-violet-100 text-sm">Tổng thanh toán</p>
          <p className="text-2xl font-bold mt-1">{payments.length}</p>
        </div>
        <div className="bg-white rounded-2xl p-5 border border-slate-100 shadow-sm">
          <p className="text-slate-500 text-sm">Chờ duyệt</p>
          <p className="text-2xl font-bold text-amber-600 mt-1">
            {payments.filter(p => p.status === 'pending').length}
          </p>
        </div>
        <div className="bg-white rounded-2xl p-5 border border-slate-100 shadow-sm">
          <p className="text-slate-500 text-sm">Đã duyệt</p>
          <p className="text-2xl font-bold text-emerald-600 mt-1">
            {payments.filter(p => p.status === 'verified').length}
          </p>
        </div>
        <div className="bg-white rounded-2xl p-5 border border-slate-100 shadow-sm">
          <p className="text-slate-500 text-sm">Từ chối</p>
          <p className="text-2xl font-bold text-red-600 mt-1">
            {payments.filter(p => p.status === 'rejected').length}
          </p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-2">
        {(['all', 'pending', 'verified', 'rejected'] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-2.5 rounded-xl text-sm font-medium transition-all ${
              filter === f
                ? 'bg-gradient-to-r from-violet-600 to-indigo-600 text-white shadow-lg shadow-violet-600/25'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50 hover:border-slate-300'
            }`}
          >
            {f === 'all' && 'Tất cả'}
            {f === 'pending' && 'Chờ duyệt'}
            {f === 'verified' && 'Đã duyệt'}
            {f === 'rejected' && 'Từ chối'}
          </button>
        ))}
      </div>

      {/* Payments Table */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
        {loading ? (
          <div className="p-12 text-center">
            <div className="w-8 h-8 border-2 border-violet-600 border-t-transparent rounded-full animate-spin mx-auto"></div>
            <p className="text-slate-500 mt-3">Đang tải...</p>
          </div>
        ) : filteredPayments.length === 0 ? (
          <div className="p-12 text-center">
            <div className="w-16 h-16 bg-slate-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
              <CreditCard className="w-8 h-8 text-slate-400" />
            </div>
            <p className="text-slate-900 font-medium">Không có thanh toán nào</p>
            <p className="text-sm text-slate-500 mt-1">Chưa có dữ liệu trong hệ thống</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-slate-50/50 border-b border-slate-100">
                <tr>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                    Mã GD
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                    Số tiền
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                    Ngân hàng
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                    Nội dung CK
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                    Ngày tạo
                  </th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                    Trạng thái
                  </th>
                  <th className="px-6 py-4 text-right text-xs font-semibold text-slate-500 uppercase tracking-wider">
                    Thao tác
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredPayments.map((payment) => (
                  <tr key={payment.id} className="hover:bg-slate-50/50 transition-colors">
                    <td className="px-6 py-4">
                      <span className="text-sm font-mono text-slate-600 bg-slate-100 px-2 py-1 rounded">
                        {payment.id.slice(0, 8)}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm font-bold text-slate-900">
                        {formatCurrency(payment.amount)}
                      </span>
                      <span className="text-xs text-slate-500 block">
                        {payment.plan === 'monthly' ? 'Tháng' : 'Năm'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <Building2 className="w-4 h-4 text-slate-400" />
                        <span className="text-sm text-slate-700">{payment.bankCode}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm font-mono text-slate-600 bg-slate-50 px-2 py-1 rounded">
                        {payment.transferContent}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-500">
                      {formatDate(payment.createdAt)}
                    </td>
                    <td className="px-6 py-4">
                      {getStatusBadge(payment.status)}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={() => setSelectedPayment(payment)}
                        className="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-violet-600 bg-violet-50 hover:bg-violet-100 rounded-lg transition-colors"
                      >
                        <Eye className="w-4 h-4" />
                        Chi tiết
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Payment Detail Modal */}
      {selectedPayment && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto shadow-2xl">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between sticky top-0 bg-white">
              <div>
                <h2 className="text-xl font-bold text-slate-900">Chi tiết thanh toán</h2>
                <p className="text-sm text-slate-500">Mã: {selectedPayment.id.slice(0, 12)}...</p>
              </div>
              <button
                onClick={() => setSelectedPayment(null)}
                className="w-10 h-10 flex items-center justify-center text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-xl transition-colors"
              >
                <XCircle className="w-6 h-6" />
              </button>
            </div>

            <div className="p-6 space-y-6">
              {/* Status */}
              <div className="flex items-center justify-between">
                <span className="text-slate-500">Trạng thái</span>
                {getStatusBadge(selectedPayment.status)}
              </div>

              {/* Amount */}
              <div className="bg-gradient-to-br from-slate-50 to-slate-100 rounded-2xl p-6">
                <p className="text-sm text-slate-500 mb-1">Số tiền thanh toán</p>
                <p className="text-4xl font-bold bg-gradient-to-r from-violet-600 to-indigo-600 bg-clip-text text-transparent">
                  {formatCurrency(selectedPayment.amount)}
                </p>
                <p className="text-sm text-slate-500 mt-2">
                  Gói: {selectedPayment.plan === 'monthly' ? 'PRO tháng' : 'PRO năm'}
                </p>
              </div>

              {/* Bank Info */}
              <div className="space-y-4">
                <h3 className="font-semibold text-slate-900 flex items-center gap-2">
                  <Building2 className="w-5 h-5 text-violet-600" />
                  Thông tin chuyển khoản
                </h3>
                <div className="grid grid-cols-2 gap-4 bg-slate-50 rounded-xl p-4">
                  <div>
                    <p className="text-sm text-slate-500">Ngân hàng</p>
                    <p className="font-semibold text-slate-900">{selectedPayment.bankCode}</p>
                  </div>
                  <div>
                    <p className="text-sm text-slate-500">Số tài khoản</p>
                    <p className="font-semibold text-slate-900 font-mono">{selectedPayment.accountNumber}</p>
                  </div>
                  <div className="col-span-2">
                    <p className="text-sm text-slate-500">Chủ tài khoản</p>
                    <p className="font-semibold text-slate-900">{selectedPayment.accountName}</p>
                  </div>
                  <div className="col-span-2">
                    <p className="text-sm text-slate-500">Nội dung CK</p>
                    <p className="font-semibold font-mono bg-amber-100 text-amber-800 px-3 py-2 rounded-lg">
                      {selectedPayment.transferContent}
                    </p>
                  </div>
                </div>
              </div>

              {/* Receipt Image */}
              {selectedPayment.receiptImage && (
                <div className="space-y-3">
                  <h3 className="font-semibold text-slate-900">Ảnh chứng từ</h3>
                  <div className="border-2 border-slate-100 rounded-2xl overflow-hidden">
                    <img
                      src={selectedPayment.receiptImage}
                      alt="Receipt"
                      className="w-full h-auto max-h-96 object-contain"
                    />
                  </div>
                  {selectedPayment.receiptNote && (
                    <p className="text-sm text-slate-600 bg-slate-50 p-4 rounded-xl">
                      <span className="font-medium">Ghi chú:</span> {selectedPayment.receiptNote}
                    </p>
                  )}
                </div>
              )}

              {/* Timestamps */}
              <div className="text-sm text-slate-500 space-y-1 bg-slate-50 rounded-xl p-4">
                <p><span className="font-medium">Tạo lúc:</span> {formatDate(selectedPayment.createdAt)}</p>
                {selectedPayment.transferredAt && (
                  <p><span className="font-medium">Chuyển khoản lúc:</span> {formatDate(selectedPayment.transferredAt)}</p>
                )}
                {selectedPayment.verifiedAt && (
                  <p><span className="font-medium">Duyệt lúc:</span> {formatDate(selectedPayment.verifiedAt)}</p>
                )}
              </div>
            </div>

            {/* Actions */}
            {selectedPayment.status === 'pending' && (
              <div className="p-6 border-t border-slate-100 flex gap-3 sticky bottom-0 bg-white">
                <button
                  onClick={() => setShowRejectModal(true)}
                  className="flex-1 flex items-center justify-center gap-2 px-4 py-3 text-sm font-medium text-red-600 bg-red-50 hover:bg-red-100 rounded-xl transition-colors"
                >
                  <XCircle className="w-5 h-5" />
                  Từ chối
                </button>
                <button
                  onClick={() => handleVerify(selectedPayment)}
                  className="flex-1 flex items-center justify-center gap-2 px-4 py-3 text-sm font-medium text-white bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 rounded-xl shadow-lg shadow-emerald-500/25 transition-all"
                >
                  <CheckCircle className="w-5 h-5" />
                  Duyệt thanh toán
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Reject Modal */}
      {showRejectModal && selectedPayment && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl">
            <h3 className="text-lg font-bold text-slate-900 mb-2">Từ chối thanh toán</h3>
            <p className="text-slate-500 mb-4">
              Vui lòng nhập lý do từ chối để user biết và có thể gửi lại.
            </p>
            <textarea
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              placeholder="Ví dụ: Ảnh không rõ, số tiền không khớp..."
              className="w-full px-4 py-3 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-transparent mb-4"
              rows={3}
            />
            <div className="flex gap-3">
              <button
                onClick={() => setShowRejectModal(false)}
                className="flex-1 px-4 py-2.5 text-sm font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-xl transition-colors"
              >
                Hủy
              </button>
              <button
                onClick={() => handleReject(selectedPayment)}
                disabled={!rejectionReason.trim()}
                className="flex-1 px-4 py-2.5 text-sm font-medium text-white bg-gradient-to-r from-red-500 to-rose-500 hover:from-red-600 hover:to-rose-600 rounded-xl shadow-lg shadow-red-500/25 transition-all disabled:opacity-50 disabled:shadow-none"
              >
                Xác nhận từ chối
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default function AdminPaymentsPage() {
  return (
    <Suspense fallback={<div className="p-8 text-center"><div className="w-8 h-8 border-2 border-violet-600 border-t-transparent rounded-full animate-spin mx-auto"></div></div>}>
      <AdminPaymentsContent />
    </Suspense>
  );
}
