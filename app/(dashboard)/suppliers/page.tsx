'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { getSuppliers, addSupplier, updateSupplier, deleteSupplier, Supplier, WithId } from '@/lib/firestore';
import { Plus, Edit2, Trash2, Search, Phone, MapPin, X, DollarSign } from 'lucide-react';

interface SupplierFormData {
  name: string;
  phone: string;
  email: string;
  address: string;
  debtAmount: string;
  note: string;
}

const initialFormData: SupplierFormData = {
  name: '',
  phone: '',
  email: '',
  address: '',
  debtAmount: '',
  note: '',
};

export default function SuppliersPage() {
  const { user } = useAuth();
  const [suppliers, setSuppliers] = useState<(Supplier & WithId)[]>([]);
  const [filteredSuppliers, setFilteredSuppliers] = useState<(Supplier & WithId)[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingSupplier, setEditingSupplier] = useState<(Supplier & WithId) | null>(null);
  const [formData, setFormData] = useState<SupplierFormData>(initialFormData);
  const [submitting, setSubmitting] = useState(false);

  const loadSuppliers = useCallback(async () => {
    if (!user?.storeId) return;
    try {
      const data = await getSuppliers(user.storeId);
      setSuppliers(data);
      setFilteredSuppliers(data);
    } catch (error) {
      console.error('Error loading suppliers:', error);
    } finally {
      setLoading(false);
    }
  }, [user]);

  useEffect(() => {
    loadSuppliers();
  }, [loadSuppliers]);

  useEffect(() => {
    if (searchQuery.trim() === '') {
      setFilteredSuppliers(suppliers);
    } else {
      const query = searchQuery.toLowerCase();
      setFilteredSuppliers(
        suppliers.filter(
          (s) =>
            s.name.toLowerCase().includes(query) ||
            s.phone?.toLowerCase().includes(query) ||
            s.email?.toLowerCase().includes(query)
        )
      );
    }
  }, [searchQuery, suppliers]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user?.storeId) return;

    setSubmitting(true);
    try {
      const supplierData = {
        name: formData.name,
        phone: formData.phone,
        email: formData.email,
        address: formData.address,
        debtAmount: parseFloat(formData.debtAmount) || 0,
        note: formData.note,
      };

      if (editingSupplier) {
        await updateSupplier(user.storeId, editingSupplier.id, supplierData);
      } else {
        await addSupplier(user.storeId, supplierData);
      }

      setIsModalOpen(false);
      setEditingSupplier(null);
      setFormData(initialFormData);
      await loadSuppliers();
    } catch (error) {
      alert('Lỗi: ' + (error as Error).message);
    } finally {
      setSubmitting(false);
    }
  };

  const handleEdit = (supplier: Supplier & WithId) => {
    setEditingSupplier(supplier);
    setFormData({
      name: supplier.name,
      phone: supplier.phone || '',
      email: supplier.email || '',
      address: supplier.address || '',
      debtAmount: supplier.debtAmount.toString(),
      note: supplier.note || '',
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (supplierId: string) => {
    if (!confirm('Bạn có chắc muốn xóa nhà cung cấp này?')) return;
    if (!user?.storeId) return;

    try {
      await deleteSupplier(user.storeId, supplierId);
      await loadSuppliers();
    } catch (error) {
      alert('Lỗi xóa nhà cung cấp: ' + (error as Error).message);
    }
  };

  const openAddModal = () => {
    setEditingSupplier(null);
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
        <h1 className="text-2xl font-bold text-emerald-900">Quản lý nhà cung cấp</h1>
        <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" />
          Thêm nhà cung cấp
        </button>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
        <input
          type="text"
          placeholder="Tìm kiếm nhà cung cấp..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="input pl-10"
        />
      </div>

      {/* Suppliers List */}
      {filteredSuppliers.length === 0 ? (
        <div className="card text-center py-12">
          <TruckIcon className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <p className="text-emerald-600/70">Chưa có nhà cung cấp nào</p>
          <button onClick={openAddModal} className="btn-primary mt-4">
            Thêm nhà cung cấp đầu tiên
          </button>
        </div>
      ) : (
        <div className="grid gap-4">
          {filteredSuppliers.map((supplier) => (
            <div key={supplier.id} className="card p-4">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <h3 className="font-semibold text-emerald-900">{supplier.name}</h3>
                  <div className="mt-2 space-y-1 text-sm text-emerald-700">
                    {supplier.phone && (
                      <p className="flex items-center gap-2">
                        <Phone className="w-4 h-4" />
                        {supplier.phone}
                      </p>
                    )}
                    {supplier.email && <p>Email: {supplier.email}</p>}
                    {supplier.address && (
                      <p className="flex items-center gap-2">
                        <MapPin className="w-4 h-4" />
                        {supplier.address}
                      </p>
                    )}
                    {supplier.note && <p className="text-emerald-600/70">{supplier.note}</p>}
                  </div>
                  {supplier.debtAmount > 0 && (
                    <div className="mt-3 inline-flex items-center gap-1 px-3 py-1 bg-orange-100 text-orange-700 rounded-full text-sm">
                      <DollarSign className="w-4 h-4" />
                      Nợ NCC: {formatCurrency(supplier.debtAmount)}
                    </div>
                  )}
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => handleEdit(supplier)}
                    className="p-2 text-emerald-700 hover:bg-emerald-50 rounded-lg"
                  >
                    <Edit2 className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => handleDelete(supplier.id)}
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
                  {editingSupplier ? 'Sửa nhà cung cấp' : 'Thêm nhà cung cấp'}
                </h2>
                <button onClick={() => setIsModalOpen(false)} className="p-2 text-gray-400 hover:text-emerald-700">
                  <X className="w-5 h-5" />
                </button>
              </div>

              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">Tên nhà cung cấp *</label>
                  <input
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) => setFormData((prev) => ({ ...prev, name: e.target.value }))}
                    className="input mt-1"
                    placeholder="Nhập tên nhà cung cấp"
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
                  <label className="block text-sm font-medium text-gray-700">Công nợ (Nợ nhà cung cấp)</label>
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
                    {editingSupplier ? 'Cập nhật' : 'Thêm mới'}
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

function TruckIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 17a2 2 0 11-4 0 2 2 0 014 0zM19 17a2 2 0 11-4 0 2 2 0 014 0z" />
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16V6a1 1 0 00-1-1H4a1 1 0 00-1 1v10a1 1 0 001 1h1m8-1a1 1 0 01-1 1H9m4-1V8a1 1 0 011-1h2.586a1 1 0 01.707.293l3.414 3.414a1 1 0 01.293.707V16a1 1 0 01-1 1h-1m-6-1a1 1 0 001 1h1M5 17a2 2 0 104 0m-4 0a2 2 0 114 0m6 0a2 2 0 104 0m-4 0a2 2 0 114 0" />
    </svg>
  );
}

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
  }).format(amount);
}
