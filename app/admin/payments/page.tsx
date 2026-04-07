'use client';

import { useEffect, useState, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import { useAuth } from '@/components/AuthProvider';
import { 
  getPendingPayments, 
  getUserPayments, 
  Payment, 
  verifyPayment, 
  rejectPayment,
  updateUserSubscription,
  getUserSubscription
} from '@/lib/firestore';
import { 
  CheckCircle, 
  XCircle, 
  Clock, 
  Eye,
  Search,
  Download,
  CreditCard,
  Calendar,
  User,
  Building2
} from 'lucide-react';
import Image from 'next/image';

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
    
    // Check if specific payment ID in URL
    const paymentId = searchParams.get('id');
    if (paymentId) {
      // Will load and select this payment
    }
  }, [searchParams]);

  const loadPayments = async () => {
    try {
      // For now, get all pending payments
      // TODO: Add function to get all payments with pagination
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
      // Calculate validUntil based on plan
      const validUntil = new Date();
      if (payment.plan === 'monthly') {
        validUntil.setMonth(validUntil.getMonth() + 1);
      } else {
        validUntil.setFullYear(validUntil.getFullYear() + 1);
      }

      // Update payment status
      await verifyPayment(payment.id, user.uid, validUntil.toISOString());

      // Update user subscription
      const currentSub = await getUserSubscription(payment.userId);
      await updateUserSubscription(payment.userId, {
        plan: 'pro',
        status: 'active',
        startedAt: new Date().toISOString(),
        expiresAt: validUntil.toISOString(),
        lastPaymentId: payment.id,
      });

      // Reload payments
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
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-700">
            <CheckCircle className="w-4 h-4" />
            Đã duyệt
          </span>
        );
      case 'rejected':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-sm font-medium bg-red-100 text-red-700">
            <XCircle className="w-4 h-4" />
            Từ chối
          </span>
        );
      case 'pending':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-sm font-medium bg-yellow-100 text-yellow-700">
            <Clock className="w-4 h-4" />
            Chờ duyệt
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-sm font-medium bg-gray-100 text-gray-700">
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
          <h1 className="text-2xl font-bold text-gray-900">Quản lý thanh toán</h1>
          <p className="text-gray-500 mt-1">Duyệt và quản lý các yêu cầu thanh toán</p>
        </div>
        <div className="flex items-center gap-2">
          <button className="btn-secondary flex items-center gap-2">
            <Download className="w-4 h-4" />
            Export
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-2">
        {(['all', 'pending', 'verified', 'rejected'] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              filter === f
                ? 'bg-primary-600 text-white'
                : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
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
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-gray-500">Đang tải...</div>
        ) : filteredPayments.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            <CreditCard className="w-12 h-12 text-gray-300 mx-auto mb-3" />
            <p>Không có thanh toán nào</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-100">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Mã
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Số tiền
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Ngân hàng
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Nội dung CK
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Ngày tạo
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Trạng thái
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Thao tác
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filteredPayments.map((payment) => (
                  <tr key={payment.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="text-sm font-mono text-gray-900">
                        {payment.id.slice(0, 8)}...
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="text-sm font-semibold text-gray-900">
                        {formatCurrency(payment.amount)}
                      </span>
                      <span className="text-xs text-gray-500 block">
                        {payment.plan === 'monthly' ? 'Tháng' : 'Năm'}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center gap-2">
                        <Building2 className="w-4 h-4 text-gray-400" />
                        <span className="text-sm text-gray-900">{payment.bankCode}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="text-sm text-gray-900 font-mono">
                        {payment.transferContent}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(payment.createdAt)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {getStatusBadge(payment.status)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right">
                      <button
                        onClick={() => setSelectedPayment(payment)}
                        className="text-primary-600 hover:text-primary-700 font-medium"
                      >
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
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-100 flex items-center justify-between">
              <h2 className="text-xl font-bold text-gray-900">Chi tiết thanh toán</h2>
              <button
                onClick={() => setSelectedPayment(null)}
                className="text-gray-400 hover:text-gray-600"
              >
                <XCircle className="w-6 h-6" />
              </button>
            </div>

            <div className="p-6 space-y-6">
              {/* Status */}
              <div className="flex items-center justify-between">
                <span className="text-gray-500">Trạng thái</span>
                {getStatusBadge(selectedPayment.status)}
              </div>

              {/* Amount */}
              <div className="bg-gray-50 rounded-xl p-4">
                <p className="text-sm text-gray-500 mb-1">Số tiền thanh toán</p>
                <p className="text-3xl font-bold text-gray-900">
                  {formatCurrency(selectedPayment.amount)}
                </p>
                <p className="text-sm text-gray-500 mt-1">
                  Gói: {selectedPayment.plan === 'monthly' ? 'PRO tháng' : 'PRO năm'}
                </p>
              </div>

              {/* Bank Info */}
              <div className="space-y-3">
                <h3 className="font-semibold text-gray-900">Thông tin chuyển khoản</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-gray-500">Ngân hàng</p>
                    <p className="font-medium text-gray-900">{selectedPayment.bankCode}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">Số tài khoản</p>
                    <p className="font-medium text-gray-900 font-mono">{selectedPayment.accountNumber}</p>
                  </div>
                  <div className="col-span-2">
                    <p className="text-sm text-gray-500">Chủ tài khoản</p>
                    <p className="font-medium text-gray-900">{selectedPayment.accountName}</p>
                  </div>
                  <div className="col-span-2">
                    <p className="text-sm text-gray-500">Nội dung CK</p>
                    <p className="font-medium text-gray-900 font-mono bg-yellow-50 p-2 rounded">
                      {selectedPayment.transferContent}
                    </p>
                  </div>
                </div>
              </div>

              {/* Receipt Image */}
              {selectedPayment.receiptImage && (
                <div className="space-y-3">
                  <h3 className="font-semibold text-gray-900">Ảnh chứng từ</h3>
                  <div className="border rounded-xl overflow-hidden">
                    <img
                      src={selectedPayment.receiptImage}
                      alt="Receipt"
                      className="w-full h-auto max-h-96 object-contain"
                    />
                  </div>
                  {selectedPayment.receiptNote && (
                    <p className="text-sm text-gray-600 bg-gray-50 p-3 rounded">
                      <span className="font-medium">Ghi chú:</span> {selectedPayment.receiptNote}
                    </p>
                  )}
                </div>
              )}

              {/* Timestamps */}
              <div className="text-sm text-gray-500 space-y-1">
                <p>Tạo lúc: {formatDate(selectedPayment.createdAt)}</p>
                {selectedPayment.transferredAt && (
                  <p>Chuyển khoản lúc: {formatDate(selectedPayment.transferredAt)}</p>
                )}
                {selectedPayment.verifiedAt && (
                  <p>Duyệt lúc: {formatDate(selectedPayment.verifiedAt)}</p>
                )}
                {selectedPayment.verifiedBy && (
                  <p>Bởi: {selectedPayment.verifiedBy}</p>
                )}
              </div>
            </div>

            {/* Actions */}
            {selectedPayment.status === 'pending' && (
              <div className="p-6 border-t border-gray-100 flex gap-3">
                <button
                  onClick={() => setShowRejectModal(true)}
                  className="flex-1 btn-secondary flex items-center justify-center gap-2 text-red-600 border-red-200 hover:bg-red-50"
                >
                  <XCircle className="w-5 h-5" />
                  Từ chối
                </button>
                <button
                  onClick={() => handleVerify(selectedPayment)}
                  className="flex-1 btn-primary flex items-center justify-center gap-2"
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
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6">
            <h3 className="text-lg font-bold text-gray-900 mb-4">Từ chối thanh toán</h3>
            <p className="text-gray-600 mb-4">
              Vui lòng nhập lý do từ chối để user biết và có thể gửi lại.
            </p>
            <textarea
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              placeholder="Ví dụ: Ảnh không rõ, số tiền không khớp..."
              className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-500 mb-4"
              rows={3}
            />
            <div className="flex gap-3">
              <button
                onClick={() => setShowRejectModal(false)}
                className="flex-1 btn-secondary"
              >
                Hủy
              </button>
              <button
                onClick={() => handleReject(selectedPayment)}
                disabled={!rejectionReason.trim()}
                className="flex-1 btn-primary bg-red-600 hover:bg-red-700 disabled:opacity-50"
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
    <Suspense fallback={<div className="p-8 text-center">Đang tải...</div>}>
      <AdminPaymentsContent />
    </Suspense>
  );
}
