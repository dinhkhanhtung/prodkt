'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { 
  getBankAccounts, 
  addBankAccount, 
  updateBankAccount,
  deleteBankAccount,
  BankAccount 
} from '@/lib/firestore';
import { uploadImageToImgBB } from '@/lib/imgbb';
import { 
  Plus, 
  Edit2, 
  Trash2, 
  Building2,
  CheckCircle,
  Star,
  Upload,
  X
} from 'lucide-react';

interface BankAccountWithId extends BankAccount {
  id: string;
}

const VIETNAM_BANKS = [
  { code: 'VCB', name: 'Vietcombank' },
  { code: 'TCB', name: 'Techcombank' },
  { code: 'VPB', name: 'VPBank' },
  { code: 'MB', name: 'MB Bank' },
  { code: 'ACB', name: 'ACB' },
  { code: 'MSB', name: 'Maritime Bank' },
  { code: 'BIDV', name: 'BIDV' },
  { code: 'VIB', name: 'VIB' },
  { code: 'SHB', name: 'SHB' },
  { code: 'STB', name: 'Sacombank' },
];

export default function AdminBanksPage() {
  const { user } = useAuth();
  const [accounts, setAccounts] = useState<BankAccountWithId[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingAccount, setEditingAccount] = useState<BankAccountWithId | null>(null);
  const [uploadingQR, setUploadingQR] = useState(false);
  
  const [formData, setFormData] = useState<Partial<BankAccount>>({
    bankCode: '',
    bankName: '',
    accountNumber: '',
    accountName: '',
    isActive: true,
    isDefault: false,
    qrImageUrl: '',
  });

  useEffect(() => {
    loadAccounts();
  }, []);

  const loadAccounts = async () => {
    try {
      const data = await getBankAccounts();
      setAccounts(data.map(a => ({ ...a, id: a.id })));
    } catch (error) {
      console.error('Error loading bank accounts:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleBankCodeChange = (code: string) => {
    const bank = VIETNAM_BANKS.find(b => b.code === code);
    setFormData({
      ...formData,
      bankCode: code,
      bankName: bank?.name || '',
    });
  };

  const handleQRUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploadingQR(true);
    try {
      const imageUrl = await uploadImageToImgBB(file);
      setFormData({ ...formData, qrImageUrl: imageUrl });
    } catch (error) {
      console.error('Error uploading QR:', error);
      alert('Có lỗi khi upload ảnh QR');
    } finally {
      setUploadingQR(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.bankCode || !formData.accountNumber || !formData.accountName) {
      alert('Vui lòng điền đầy đủ thông tin');
      return;
    }

    try {
      if (editingAccount) {
        await updateBankAccount(editingAccount.id, formData);
      } else {
        await addBankAccount(formData as BankAccount);
      }
      
      await loadAccounts();
      setShowModal(false);
      setEditingAccount(null);
      resetForm();
      alert(editingAccount ? 'Đã cập nhật tài khoản!' : 'Đã thêm tài khoản mới!');
    } catch (error) {
      console.error('Error saving account:', error);
      alert('Có lỗi xảy ra khi lưu');
    }
  };

  const handleDelete = async (accountId: string) => {
    if (!confirm('Bạn có chắc muốn xóa tài khoản này?')) return;

    try {
      await deleteBankAccount(accountId);
      await loadAccounts();
      alert('Đã xóa tài khoản');
    } catch (error) {
      console.error('Error deleting account:', error);
      alert('Có lỗi xảy ra khi xóa');
    }
  };

  const handleEdit = (account: BankAccountWithId) => {
    setEditingAccount(account);
    setFormData(account);
    setShowModal(true);
  };

  const resetForm = () => {
    setFormData({
      bankCode: '',
      bankName: '',
      accountNumber: '',
      accountName: '',
      isActive: true,
      isDefault: false,
      qrImageUrl: '',
    });
  };

  const openAddModal = () => {
    setEditingAccount(null);
    resetForm();
    setShowModal(true);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Tài khoản ngân hàng</h1>
          <p className="text-gray-500 mt-1">Quản lý các tài khoản nhận thanh toán</p>
        </div>
        <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" />
          Thêm tài khoản
        </button>
      </div>

      {/* Accounts Grid */}
      {loading ? (
        <div className="text-center py-12 text-gray-500">Đang tải...</div>
      ) : accounts.length === 0 ? (
        <div className="text-center py-12 text-gray-500">
          <Building2 className="w-12 h-12 text-gray-300 mx-auto mb-3" />
          <p>Chưa có tài khoản ngân hàng nào</p>
          <button onClick={openAddModal} className="btn-primary mt-4">
            Thêm tài khoản đầu tiên
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {accounts.map((account) => (
            <div 
              key={account.id} 
              className={`bg-white rounded-xl p-6 shadow-sm border-2 transition-all ${
                account.isDefault 
                  ? 'border-primary-500 ring-1 ring-primary-500' 
                  : 'border-gray-100 hover:border-gray-200'
              }`}
            >
              {/* Default Badge */}
              {account.isDefault && (
                <div className="flex items-center gap-1 text-primary-600 text-sm font-medium mb-3">
                  <Star className="w-4 h-4 fill-current" />
                  Mặc định
                </div>
              )}

              {/* Bank Info */}
              <div className="flex items-center gap-3 mb-4">
                <div className="w-12 h-12 bg-primary-100 rounded-lg flex items-center justify-center">
                  <Building2 className="w-6 h-6 text-primary-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900">{account.bankName}</h3>
                  <p className="text-sm text-gray-500">{account.bankCode}</p>
                </div>
              </div>

              {/* Account Details */}
              <div className="space-y-2 mb-4">
                <div>
                  <p className="text-xs text-gray-500">Số tài khoản</p>
                  <p className="font-mono text-sm font-medium text-gray-900">{account.accountNumber}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">Chủ tài khoản</p>
                  <p className="text-sm text-gray-900">{account.accountName}</p>
                </div>
              </div>

              {/* QR Image */}
              {account.qrImageUrl && (
                <div className="mb-4">
                  <img 
                    src={account.qrImageUrl} 
                    alt="QR Code" 
                    className="w-32 h-32 object-contain border rounded-lg mx-auto"
                  />
                </div>
              )}

              {/* Status */}
              <div className="flex items-center gap-2 mb-4">
                <span className={`w-2 h-2 rounded-full ${account.isActive ? 'bg-green-500' : 'bg-gray-400'}`} />
                <span className="text-sm text-gray-600">
                  {account.isActive ? 'Hoạt động' : 'Tạm dừng'}
                </span>
              </div>

              {/* Actions */}
              <div className="flex gap-2">
                <button
                  onClick={() => handleEdit(account)}
                  className="flex-1 flex items-center justify-center gap-2 px-3 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
                >
                  <Edit2 className="w-4 h-4" />
                  Sửa
                </button>
                <button
                  onClick={() => handleDelete(account.id)}
                  className="flex items-center justify-center gap-2 px-3 py-2 text-sm font-medium text-red-600 bg-red-50 rounded-lg hover:bg-red-100 transition-colors"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Add/Edit Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-100 flex items-center justify-between">
              <h2 className="text-xl font-bold text-gray-900">
                {editingAccount ? 'Sửa tài khoản' : 'Thêm tài khoản mới'}
              </h2>
              <button
                onClick={() => setShowModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-4">
              {/* Bank Selection */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Ngân hàng <span className="text-red-500">*</span>
                </label>
                <select
                  value={formData.bankCode}
                  onChange={(e) => handleBankCodeChange(e.target.value)}
                  className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                  required
                >
                  <option value="">Chọn ngân hàng</option>
                  {VIETNAM_BANKS.map((bank) => (
                    <option key={bank.code} value={bank.code}>
                      {bank.name} ({bank.code})
                    </option>
                  ))}
                </select>
              </div>

              {/* Account Number */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Số tài khoản <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={formData.accountNumber}
                  onChange={(e) => setFormData({ ...formData, accountNumber: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                  placeholder="1234567890"
                  required
                />
              </div>

              {/* Account Name */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Chủ tài khoản <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={formData.accountName}
                  onChange={(e) => setFormData({ ...formData, accountName: e.target.value.toUpperCase() })}
                  className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 uppercase"
                  placeholder="NGUYEN VAN A"
                  required
                />
              </div>

              {/* QR Code Upload */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Ảnh QR Code (tùy chọn)
                </label>
                <div className="flex items-center gap-4">
                  {formData.qrImageUrl ? (
                    <div className="relative">
                      <img 
                        src={formData.qrImageUrl} 
                        alt="QR" 
                        className="w-24 h-24 object-contain border rounded-lg"
                      />
                      <button
                        type="button"
                        onClick={() => setFormData({ ...formData, qrImageUrl: '' })}
                        className="absolute -top-2 -right-2 w-6 h-6 bg-red-500 text-white rounded-full flex items-center justify-center text-xs"
                      >
                        ×
                      </button>
                    </div>
                  ) : (
                    <label className="flex items-center justify-center w-24 h-24 border-2 border-dashed border-gray-300 rounded-lg cursor-pointer hover:border-primary-500 transition-colors">
                      {uploadingQR ? (
                        <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-primary-600" />
                      ) : (
                        <Upload className="w-6 h-6 text-gray-400" />
                      )}
                      <input
                        type="file"
                        accept="image/*"
                        onChange={handleQRUpload}
                        className="hidden"
                        disabled={uploadingQR}
                      />
                    </label>
                  )}
                  <p className="text-sm text-gray-500">
                    Upload ảnh QR code để user quét chuyển khoản nhanh
                  </p>
                </div>
              </div>

              {/* Options */}
              <div className="flex items-center gap-6">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formData.isActive}
                    onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                    className="w-4 h-4 text-primary-600 rounded focus:ring-primary-500"
                  />
                  <span className="text-sm text-gray-700">Hoạt động</span>
                </label>

                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formData.isDefault}
                    onChange={(e) => setFormData({ ...formData, isDefault: e.target.checked })}
                    className="w-4 h-4 text-primary-600 rounded focus:ring-primary-500"
                  />
                  <span className="text-sm text-gray-700">Mặc định</span>
                </label>
              </div>

              {/* Actions */}
              <div className="flex gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="flex-1 btn-secondary"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="flex-1 btn-primary"
                >
                  {editingAccount ? 'Cập nhật' : 'Thêm tài khoản'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
