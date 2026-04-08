'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { getCustomers, addCustomer, updateCustomer, deleteCustomer, Customer, WithId } from '@/lib/firestore';
import { Plus, Edit2, Trash2, Search, Phone, MapPin, X, DollarSign } from 'lucide-react';

interface CustomerFormData {
  name: string;
  phone: string;
  email: string;
  address: string;
  debtAmount: string;
  note: string;
}

const initialFormData: CustomerFormData = {
  name: '',
  phone: '',
  email: '',
  address: '',
  debtAmount: '',
  note: '',
};

export default function CustomersPage() {
  const { user } = useAuth();
  const [customers, setCustomers] = useState<(Customer & WithId)[]>([]);
  const [filteredCustomers, setFilteredCustomers] = useState<(Customer & WithId)[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingCustomer, setEditingCustomer] = useState<(Customer & WithId) | null>(null);
  const [formData, setFormData] = useState<CustomerFormData>(initialFormData);
  const [submitting, setSubmitting] = useState(false);

  const loadCustomers = useCallback(async () => {
    if (!user?.storeId) return;
    try {
      const data = await getCustomers(user.storeId);
      setCustomers(data);
      setFilteredCustomers(data);
    } catch (error) {
      console.error('Error loading customers:', error);
    } finally {
      setLoading(false);
    }
  }, [user]);

  useEffect(() => {
    loadCustomers();
  }, [loadCustomers]);

  useEffect(() => {
    if (searchQuery.trim() === '') {
      setFilteredCustomers(customers);
    } else {
      const query = searchQuery.toLowerCase();
      setFilteredCustomers(
        customers.filter(
          (c) =>
            c.name.toLowerCase().includes(query) ||
            c.phone?.toLowerCase().includes(query) ||
            c.email?.toLowerCase().includes(query)
        )
      );
    }
  }, [searchQuery, customers]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user?.storeId) return;

    setSubmitting(true);
    try {
      const customerData = {
        name: formData.name,
        phone: formData.phone,
        email: formData.email,
        address: formData.address,
        debtAmount: parseFloat(formData.debtAmount) || 0,
        note: formData.note,
      };

      if (editingCustomer) {
        await updateCustomer(user.storeId, editingCustomer.id, customerData);
      } else {
        await addCustomer(user.storeId, customerData);
      }

      setIsModalOpen(false);
      setEditingCustomer(null);
      setFormData(initialFormData);
      await loadCustomers();
    } catch (error) {
      alert('Lỗi: ' + (error as Error).message);
    } finally {
      setSubmitting(false);
    }
  };

  const handleEdit = (customer: Customer & WithId) => {
    setEditingCustomer(customer);
    setFormData({
      name: customer.name,
      phone: customer.phone || '',
      email: customer.email || '',
      address: customer.address || '',
      debtAmount: customer.debtAmount.toString(),
      note: customer.note || '',
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (customerId: string) => {
    if (!confirm('Bạn có chắc muốn xóa khách hàng này?')) return;
    if (!user?.storeId) return;

    try {
      await deleteCustomer(user.storeId, customerId);
      await loadCustomers();
    } catch (error) {
      alert('Lỗi xóa khách hàng: ' + (error as Error).message);
    }
  };

  const openAddModal = () => {
    setEditingCustomer(null);
    setFormData(initialFormData);
    setIsModalOpen(true);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <h1 className="text-2xl font-bold text-emerald-900">Quản lý khách hàng</h1>
        <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" />
          Thêm khách hàng
        </button>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-emerald-400" />
        <input
          type="text"
          placeholder="Tìm kiếm khách hàng..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="input pl-10"
        />
      </div>

      {/* Customers List */}
      {filteredCustomers.length === 0 ? (
        <div className="card text-center py-12">
          <UsersIcon className="w-12 h-12 text-emerald-300 mx-auto mb-4" />
          <p className="text-emerald-600/70">Chưa có khách hàng nào</p>
          <button onClick={openAddModal} className="btn-primary mt-4">
            Thêm khách hàng đầu tiên
          </button>
        </div>
      ) : (
        <div className="grid gap-4">
          {filteredCustomers.map((customer) => (
            <div key={customer.id} className="card p-4">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <h3 className="font-semibold text-emerald-900">{customer.name}</h3>
                  <div className="mt-2 space-y-1 text-sm text-emerald-700">
                    {customer.phone && (
                      <p className="flex items-center gap-2">
                        <Phone className="w-4 h-4" />
                        {customer.phone}
                      </p>
                    )}
                    {customer.email && <p>Email: {customer.email}</p>}
                    {customer.address && (
                      <p className="flex items-center gap-2">
                        <MapPin className="w-4 h-4" />
                        {customer.address}
                      </p>
                    )}
                    {customer.note && <p className="text-emerald-600/70">{customer.note}</p>}
                  </div>
                  {customer.debtAmount > 0 && (
                    <div className="mt-3 inline-flex items-center gap-1 px-3 py-1 bg-red-100 text-red-700 rounded-full text-sm">
                      <DollarSign className="w-4 h-4" />
                      Công nợ: {formatCurrency(customer.debtAmount)}
                    </div>
                  )}
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => handleEdit(customer)}
                    className="p-2 text-emerald-700 hover:bg-emerald-50 rounded-lg"
                  >
                    <Edit2 className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => handleDelete(customer.id)}
                    className="p-2 text-red-600 hover:bg-red-50 rounded-lg"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex items-center justify-center min-h-screen px-4">
            <div className="fixed inset-0 bg-gray-900/50" onClick={() => setIsModalOpen(false)} />
            <div className="relative bg-white rounded-lg shadow-xl max-w-lg w-full p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-emerald-900">
                  {editingCustomer ? 'Sửa khách hàng' : 'Thêm khách hàng'}
                </h2>
                <button onClick={() => setIsModalOpen(false)} className="p-2 text-emerald-400 hover:text-emerald-700">
                  <X className="w-5 h-5" />
                </button>
              </div>

              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">Tên khách hàng *</label>
                  <input
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) => setFormData((prev) => ({ ...prev, name: e.target.value }))}
                    className="input mt-1"
                    placeholder="Nhập tên khách hàng"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Số điện thoại</label>
                    <input
                      type="tel"
                      value={formData.phone}
                      onChange={(e) => setFormData((prev) => ({ ...prev, phone: e.target.value }))}
                      className="input mt-1"
                      placeholder="0xxx xxx xxx"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Email</label>
                    <input
                      type="email"
                      value={formData.email}
                      onChange={(e) => setFormData((prev) => ({ ...prev, email: e.target.value }))}
                      className="input mt-1"
                      placeholder="email@example.com"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700">Địa chỉ</label>
                  <input
                    type="text"
                    value={formData.address}
                    onChange={(e) => setFormData((prev) => ({ ...prev, address: e.target.value }))}
                    className="input mt-1"
                    placeholder="Nhập địa chỉ"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700">Công nợ hiện tại</label>
                  <input
                    type="number"
                    min="0"
                    value={formData.debtAmount}
                    onChange={(e) => setFormData((prev) => ({ ...prev, debtAmount: e.target.value }))}
                    className="input mt-1"
                    placeholder="0"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700">Ghi chú</label>
                  <textarea
                    rows={2}
                    value={formData.note}
                    onChange={(e) => setFormData((prev) => ({ ...prev, note: e.target.value }))}
                    className="input mt-1"
                    placeholder="Ghi chú (tùy chọn)"
                  />
                </div>

                <div className="flex gap-3 pt-4">
                  <button type="button" onClick={() => setIsModalOpen(false)} className="flex-1 btn-secondary">
                    Hủy
                  </button>
                  <button
                    type="submit"
                    disabled={submitting}
                    className="flex-1 btn-primary flex justify-center items-center gap-2"
                  >
                    {submitting && <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />}
                    {editingCustomer ? 'Cập nhật' : 'Thêm mới'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function UsersIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
    </svg>
  );
}

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
  }).format(amount);
}
