'use client';

import { useEffect, useState, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/components/AuthProvider';
import { getBankAccounts, getDefaultBankAccount, createPayment, BankAccount } from '@/lib/firestore';
import { uploadImageToImgBB } from '@/lib/imgbb';
import { 
  ArrowLeft, 
  Copy, 
  CheckCircle, 
  Upload, 
  Building2,
  CreditCard,
  Clock,
  AlertCircle,
  Loader2
} from 'lucide-react';

interface BankAccountWithId extends BankAccount {
  id: string;
}

function PaymentContent() {
  const { user } = useAuth();
  const searchParams = useSearchParams();
  const plan = searchParams.get('plan') || 'monthly';
  
  const [accounts, setAccounts] = useState<BankAccountWithId[]>([]);
  const [selectedAccount, setSelectedAccount] = useState<BankAccountWithId | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  
  // Payment form state
  const [receiptImage, setReceiptImage] = useState<string>('');
  const [receiptNote, setReceiptNote] = useState('');
  const [transferredAt, setTransferredAt] = useState('');
  const [uploading, setUploading] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  const amount = plan === 'yearly' ? 990000 : 99000;
  const planName = plan === 'yearly' ? 'PRO năm' : 'PRO tháng';

  useEffect(() => {
    loadBankAccounts();
    // Set default date to now
    setTransferredAt(new Date().toISOString().slice(0, 16));
  }, []);

  const loadBankAccounts = async () => {
    try {
      const data = await getBankAccounts();
      const accountsWithId = data.map(a => ({ ...a, id: a.id }));
      setAccounts(accountsWithId);
      
      // Select default account or first one
      const defaultAcc = accountsWithId.find(a => a.isDefault) || accountsWithId[0];
      setSelectedAccount(defaultAcc || null);
    } catch (error) {
      console.error('Error loading bank accounts:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCopy = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    alert(`Đã copy ${label}: ${text}`);
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(true);
    try {
      const imageUrl = await uploadImageToImgBB(file);
      setReceiptImage(imageUrl);
    } catch (error) {
      console.error('Error uploading:', error);
      alert('Có lỗi khi upload ảnh. Vui lòng thử lại.');
    } finally {
      setUploading(false);
    }
  };

  const handleSubmit = async () => {
    if (!user || !selectedAccount || !receiptImage) {
      alert('Vui lòng upload ảnh chụp màn hình chuyển khoản');
      return;
    }

    setSubmitting(true);
    try {
      // Generate transfer content
      const transferContent = `PRODKT-${user.uid.slice(0, 8)}`;
      
      // Calculate validUntil
      const validUntil = new Date();
      if (plan === 'monthly') {
        validUntil.setMonth(validUntil.getMonth() + 1);
      } else {
        validUntil.setFullYear(validUntil.getFullYear() + 1);
      }

      // Create payment record
      await createPayment({
        userId: user.uid,
        storeId: user.storeId || '',
        amount,
        plan: plan as 'monthly' | 'yearly',
        status: 'pending',
        bankCode: selectedAccount.bankCode,
        accountNumber: selectedAccount.accountNumber,
        accountName: selectedAccount.accountName,
        transferContent,
        receiptImage,
        receiptNote,
        transferredAt,
        validUntil: validUntil.toISOString(),
      });

      setSubmitted(true);
    } catch (error) {
      console.error('Error creating payment:', error);
      alert('Có lỗi xảy ra. Vui lòng thử lại.');
    } finally {
      setSubmitting(false);
    }
  };

  if (submitted) {
    return (
      <div className="min-h-screen bg-emerald-50/50 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl p-8 max-w-md w-full text-center">
          <div className="w-16 h-16 bg-yellow-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <Clock className="w-8 h-8 text-yellow-600" />
          </div>
          <h2 className="text-2xl font-bold text-emerald-900 mb-2">Đã nhận thanh toán!</h2>
          <p className="text-emerald-700 mb-6">
            Chúng tôi đã nhận được chứng từ thanh toán của bạn. 
            Admin sẽ kiểm tra và kích hoạt PRO trong vòng 24 giờ.
          </p>
          <div className="bg-emerald-50/50 rounded-lg p-4 mb-6 text-left">
            <p className="text-sm text-emerald-700">Mã thanh toán:</p>
            <p className="font-mono font-medium text-emerald-900">PRODKT-{user?.uid?.slice(0, 8)}</p>
          </div>
          <Link href="/dashboard" className="btn-primary block w-full">
            Về Dashboard
          </Link>
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-emerald-50/50 flex items-center justify-center">
        <Loader2 className="w-8 h-8 text-primary-600 animate-spin" />
      </div>
    );
  }

  if (accounts.length === 0) {
    return (
      <div className="min-h-screen bg-emerald-50/50 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl p-8 max-w-md w-full text-center">
          <AlertCircle className="w-12 h-12 text-yellow-500 mx-auto mb-4" />
          <h2 className="text-xl font-bold text-emerald-900 mb-2">Chưa có tài khoản ngân hàng</h2>
          <p className="text-emerald-700 mb-4">
            Hệ thống đang cập nhật phương thức thanh toán. Vui lòng quay lại sau.
          </p>
          <Link href="/upgrade" className="btn-secondary block w-full">
            Quay lại
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-emerald-50/50 py-8 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto">
        {/* Back Link */}
        <Link href="/upgrade" className="inline-flex items-center gap-2 text-emerald-700 hover:text-emerald-900 mb-6">
          <ArrowLeft className="w-4 h-4" />
          Quay lại chọn gói
        </Link>

        {/* Header */}
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-emerald-900">Thanh toán {planName}</h1>
          <p className="text-emerald-700 mt-1">Chuyển khoản và upload chứng từ để kích hoạt PRO</p>
        </div>

        <div className="grid md:grid-cols-2 gap-6">
          {/* Left: Payment Info */}
          <div className="space-y-6">
            {/* Amount Card */}
            <div className="bg-gradient-to-br from-primary-600 to-secondary-600 rounded-2xl p-6 text-white">
              <p className="text-white/80 text-sm mb-1">Số tiền cần chuyển</p>
              <p className="text-4xl font-bold">
                {new Intl.NumberFormat('vi-VN').format(amount)}đ
              </p>
              <p className="text-white/80 text-sm mt-2">Gói: {planName}</p>
            </div>

            {/* Bank Selection */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <h3 className="font-semibold text-emerald-900 mb-4 flex items-center gap-2">
                <Building2 className="w-5 h-5 text-primary-600" />
                Chọn ngân hàng
              </h3>
              <div className="space-y-2">
                {accounts.map((account) => (
                  <button
                    key={account.id}
                    onClick={() => setSelectedAccount(account)}
                    className={`w-full flex items-center gap-3 p-3 rounded-xl border-2 transition-colors text-left ${
                      selectedAccount?.id === account.id
                        ? 'border-primary-500 bg-primary-50'
                        : 'border-gray-100 hover:border-emerald-100'
                    }`}
                  >
                    <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                      selectedAccount?.id === account.id
                        ? 'border-primary-500'
                        : 'border-emerald-200'
                    }`}>
                      {selectedAccount?.id === account.id && (
                        <div className="w-2.5 h-2.5 bg-primary-500 rounded-full" />
                      )}
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-emerald-900">{account.bankName}</p>
                      {account.isDefault && (
                        <span className="text-xs text-primary-600">Mặc định</span>
                      )}
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* Bank Details */}
            {selectedAccount && (
              <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
                <h3 className="font-semibold text-emerald-900 mb-4">Thông tin chuyển khoản</h3>
                
                {/* QR Code */}
                {selectedAccount.qrImageUrl && (
                  <div className="mb-4 text-center">
                    <img
                      src={selectedAccount.qrImageUrl}
                      alt="QR Code"
                      className="w-48 h-48 object-contain mx-auto border rounded-xl"
                    />
                    <p className="text-sm text-emerald-600/70 mt-2">Quét mã QR để chuyển khoản nhanh</p>
                  </div>
                )}

                <div className="space-y-4">
                  <div>
                    <p className="text-sm text-emerald-600/70 mb-1">Chủ tài khoản</p>
                    <div className="flex items-center justify-between bg-emerald-50/50 rounded-lg p-3">
                      <span className="font-medium text-emerald-900">{selectedAccount.accountName}</span>
                      <button
                        onClick={() => handleCopy(selectedAccount.accountName, 'chủ TK')}
                        className="text-primary-600 hover:text-primary-700"
                      >
                        <Copy className="w-4 h-4" />
                      </button>
                    </div>
                  </div>

                  <div>
                    <p className="text-sm text-emerald-600/70 mb-1">Số tài khoản</p>
                    <div className="flex items-center justify-between bg-emerald-50/50 rounded-lg p-3">
                      <span className="font-medium text-emerald-900 font-mono">{selectedAccount.accountNumber}</span>
                      <button
                        onClick={() => handleCopy(selectedAccount.accountNumber, 'STK')}
                        className="text-primary-600 hover:text-primary-700"
                      >
                        <Copy className="w-4 h-4" />
                      </button>
                    </div>
                  </div>

                  <div>
                    <p className="text-sm text-emerald-600/70 mb-1">Nội dung chuyển khoản</p>
                    <div className="flex items-center justify-between bg-yellow-50 border border-yellow-200 rounded-lg p-3">
                      <span className="font-medium text-emerald-900 font-mono">
                        PRODKT-{user?.uid?.slice(0, 8)}
                      </span>
                      <button
                        onClick={() => handleCopy(`PRODKT-${user?.uid?.slice(0, 8)}`, 'nội dung')}
                        className="text-yellow-700 hover:text-yellow-800"
                      >
                        <Copy className="w-4 h-4" />
                      </button>
                    </div>
                    <p className="text-xs text-yellow-600 mt-1">
                      ⚠️ Bắt buộc ghi đúng nội dung này để được duyệt nhanh
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Right: Upload Form */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 h-fit">
            <h3 className="font-semibold text-emerald-900 mb-4 flex items-center gap-2">
              <Upload className="w-5 h-5 text-primary-600" />
              Xác nhận thanh toán
            </h3>

            <div className="space-y-4">
              {/* Receipt Image Upload */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Ảnh chụp màn hình chuyển khoản <span className="text-red-500">*</span>
                </label>
                {receiptImage ? (
                  <div className="relative">
                    <img
                      src={receiptImage}
                      alt="Receipt"
                      className="w-full h-48 object-contain border rounded-xl"
                    />
                    <button
                      onClick={() => setReceiptImage('')}
                      className="absolute top-2 right-2 w-8 h-8 bg-red-500 text-white rounded-full flex items-center justify-center hover:bg-red-600"
                    >
                      ×
                    </button>
                  </div>
                ) : (
                  <label className="flex flex-col items-center justify-center w-full h-48 border-2 border-dashed border-emerald-200 rounded-xl cursor-pointer hover:border-primary-500 hover:bg-emerald-50/50 transition-colors">
                    {uploading ? (
                      <Loader2 className="w-8 h-8 text-primary-600 animate-spin" />
                    ) : (
                      <>
                        <Upload className="w-8 h-8 text-emerald-400 mb-2" />
                        <p className="text-sm text-emerald-600/70">Click để upload ảnh</p>
                        <p className="text-xs text-emerald-400 mt-1">Hỗ trợ JPG, PNG</p>
                      </>
                    )}
                    <input
                      type="file"
                      accept="image/*"
                      onChange={handleImageUpload}
                      className="hidden"
                      disabled={uploading}
                    />
                  </label>
                )}
              </div>

              {/* Transfer Date/Time */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Thời gian chuyển khoản
                </label>
                <input
                  type="datetime-local"
                  value={transferredAt}
                  onChange={(e) => setTransferredAt(e.target.value)}
                  className="w-full px-4 py-2 border border-emerald-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
              </div>

              {/* Note */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Ghi chú (tùy chọn)
                </label>
                <textarea
                  value={receiptNote}
                  onChange={(e) => setReceiptNote(e.target.value)}
                  placeholder="Ví dụ: Chuyển từ Momo, tên khác trên TK..."
                  className="w-full px-4 py-2 border border-emerald-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                  rows={3}
                />
              </div>

              {/* Submit Button */}
              <button
                onClick={handleSubmit}
                disabled={!receiptImage || submitting}
                className="w-full btn-primary py-3 flex items-center justify-center gap-2 disabled:opacity-50"
              >
                {submitting ? (
                  <>
                    <Loader2 className="w-5 h-5 animate-spin" />
                    Đang xử lý...
                  </>
                ) : (
                  <>
                    <CheckCircle className="w-5 h-5" />
                    Xác nhận đã chuyển khoản
                  </>
                )}
              </button>

              <p className="text-xs text-emerald-600/70 text-center">
                Admin sẽ kiểm tra và kích hoạt PRO trong vòng 24 giờ
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function PaymentPage() {
  return (
    <Suspense fallback={<div className="min-h-screen flex items-center justify-center"><Loader2 className="w-8 h-8 text-primary-600 animate-spin" /></div>}>
      <PaymentContent />
    </Suspense>
  );
}
