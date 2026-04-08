'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { 
  getCustomFields, 
  addCustomField, 
  updateCustomField, 
  deleteCustomField,
  CustomField,
  WithId 
} from '@/lib/firestore';
import { 
  Plus, 
  Trash2, 
  Edit2, 
  X, 
  Settings,
  Package,
  Users,
  Truck,
  GripVertical,
  Check
} from 'lucide-react';

const ENTITY_TYPES = [
  { key: 'product', label: 'Sản phẩm', icon: Package },
  { key: 'customer', label: 'Khách hàng', icon: Users },
  { key: 'supplier', label: 'Nhà cung cấp', icon: Truck },
] as const;

const FIELD_TYPES = [
  { key: 'text', label: 'Văn bản' },
  { key: 'number', label: 'Số' },
  { key: 'date', label: 'Ngày tháng' },
  { key: 'select', label: 'Lựa chọn' },
  { key: 'checkbox', label: 'Hộp kiểm' },
] as const;

export default function CustomFieldsPage() {
  const { user } = useAuth();
  const storeId = user?.storeId;
  const [fields, setFields] = useState<WithId<CustomField>[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedEntity, setSelectedEntity] = useState<'product' | 'customer' | 'supplier'>('product');
  
  const [showModal, setShowModal] = useState(false);
  const [editingField, setEditingField] = useState<WithId<CustomField> | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    label: '',
    type: 'text' as CustomField['type'],
    required: false,
    options: [''] as string[],
  });

  useEffect(() => {
    if (storeId) {
      loadFields();
    }
  }, [storeId, selectedEntity]);

  const loadFields = async () => {
    if (!storeId) return;
    setLoading(true);
    try {
      const data = await getCustomFields(storeId, selectedEntity);
      setFields(data);
    } catch (error) {
      console.error('Error loading custom fields:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!storeId || !user) return;

    // Validate name (no spaces, lowercase)
    const validatedName = formData.name.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
    if (!validatedName) {
      alert('Tên trường không hợp lệ. Chỉ chấp nhận chữ cái, số và dấu gạch dưới.');
      return;
    }

    // Check for duplicate names
    const existingField = fields.find(f => f.name === validatedName && f.id !== editingField?.id);
    if (existingField) {
      alert('Tên trường này đã tồn tại');
      return;
    }

    const cleanOptions = formData.options.filter(opt => opt.trim() !== '');

    try {
      if (editingField) {
        await updateCustomField(storeId, editingField.id, {
          name: validatedName,
          label: formData.label,
          type: formData.type,
          required: formData.required,
          options: formData.type === 'select' ? cleanOptions : undefined,
        });
      } else {
        await addCustomField(user.uid, storeId, {
          entityType: selectedEntity,
          name: validatedName,
          label: formData.label,
          type: formData.type,
          required: formData.required,
          options: formData.type === 'select' ? cleanOptions : undefined,
          order: fields.length,
        });
      }
      setShowModal(false);
      setEditingField(null);
      resetForm();
      loadFields();
    } catch (error) {
      console.error('Error saving custom field:', error);
      alert('Có lỗi xảy ra khi lưu trường tùy chỉnh');
    }
  };

  const handleDelete = async (id: string) => {
    if (!storeId) return;
    if (!confirm('Bạn có chắc chắn muốn xóa trường này? Dữ liệu trong các sản phẩm/khách hàng hiện có có thể bị mất.')) return;

    try {
      await deleteCustomField(storeId, id);
      loadFields();
    } catch (error) {
      console.error('Error deleting custom field:', error);
      alert('Có lỗi xảy ra khi xóa trường');
    }
  };

  const handleEdit = (field: WithId<CustomField>) => {
    setEditingField(field);
    setFormData({
      name: field.name,
      label: field.label,
      type: field.type,
      required: field.required,
      options: field.options?.length ? field.options : [''],
    });
    setShowModal(true);
  };

  const resetForm = () => {
    setFormData({
      name: '',
      label: '',
      type: 'text',
      required: false,
      options: [''],
    });
  };

  const addOption = () => {
    setFormData({ ...formData, options: [...formData.options, ''] });
  };

  const updateOption = (index: number, value: string) => {
    const newOptions = [...formData.options];
    newOptions[index] = value;
    setFormData({ ...formData, options: newOptions });
  };

  const removeOption = (index: number) => {
    const newOptions = formData.options.filter((_, i) => i !== index);
    if (newOptions.length === 0) newOptions.push('');
    setFormData({ ...formData, options: newOptions });
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center">
            <Settings className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-emerald-900">Trường tùy chỉnh</h1>
            <p className="text-emerald-600/70 text-sm">Thêm thuộc tính mở rộng cho sản phẩm, khách hàng, NCC</p>
          </div>
        </div>
        <button
          onClick={() => {
            setEditingField(null);
            resetForm();
            setShowModal(true);
          }}
          className="px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-medium transition-colors flex items-center gap-2 shadow-lg shadow-emerald-500/25"
        >
          <Plus className="w-5 h-5" />
          Thêm trường
        </button>
      </div>

      {/* Entity Type Tabs */}
      <div className="border-b border-emerald-100">
        <nav className="flex gap-1">
          {ENTITY_TYPES.map((entity) => {
            const Icon = entity.icon;
            return (
              <button
                key={entity.key}
                onClick={() => setSelectedEntity(entity.key as any)}
                className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
                  selectedEntity === entity.key
                    ? 'border-emerald-500 text-emerald-600'
                    : 'border-transparent text-emerald-600/60 hover:text-emerald-700'
                }`}
              >
                <Icon className="w-4 h-4" />
                {entity.label}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Fields List */}
      <div className="bg-white rounded-xl border border-emerald-100 shadow-sm">
        {loading ? (
          <div className="p-8 text-center">
            <div className="w-8 h-8 border-4 border-emerald-200 border-t-emerald-600 rounded-full animate-spin mx-auto" />
            <p className="text-emerald-600 mt-2">Đang tải...</p>
          </div>
        ) : fields.length === 0 ? (
          <div className="p-8 text-center">
            <Settings className="w-12 h-12 text-emerald-300 mx-auto mb-3" />
            <p className="text-emerald-600">Chưa có trường tùy chỉnh nào</p>
            <button
              onClick={() => setShowModal(true)}
              className="mt-3 text-emerald-600 hover:text-emerald-700 font-medium"
            >
              Thêm trường đầu tiên
            </button>
          </div>
        ) : (
          <div className="divide-y divide-emerald-50">
            {fields.map((field, index) => (
              <div key={field.id} className="flex items-center gap-4 p-4 hover:bg-emerald-50/30">
                <div className="text-emerald-400">
                  <GripVertical className="w-5 h-5" />
                </div>
                
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-emerald-900">{field.label}</span>
                    <span className="text-xs text-emerald-600/70 bg-emerald-100 px-2 py-0.5 rounded">
                      {field.name}
                    </span>
                    {field.required && (
                      <span className="text-xs text-red-600 bg-red-50 px-2 py-0.5 rounded">
                        Bắt buộc
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-emerald-600/70">
                    {FIELD_TYPES.find(t => t.key === field.type)?.label}
                    {field.options && field.options.length > 0 && ` (${field.options.length} lựa chọn)`}
                  </p>
                </div>

                <div className="flex items-center gap-1">
                  <button
                    onClick={() => handleEdit(field)}
                    className="p-2 text-emerald-600 hover:bg-emerald-100 rounded-lg transition-colors"
                  >
                    <Edit2 className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => handleDelete(field.id)}
                    className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
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
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-emerald-950/50 backdrop-blur-sm" onClick={() => setShowModal(false)} />
          <div className="relative bg-white rounded-2xl shadow-2xl max-w-lg w-full p-6 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-emerald-900">
                {editingField ? 'Chỉnh sửa trường' : 'Thêm trường mới'}
              </h2>
              <button onClick={() => setShowModal(false)} className="p-2 hover:bg-emerald-50 rounded-lg">
                <X className="w-5 h-5 text-emerald-600" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1.5">
                  Tên trường (không dấu, không khoảng cách)
                </label>
                <input
                  type="text"
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900"
                  placeholder="vd: ma_vach, xuat_xu, bao_hanh"
                />
                <p className="text-xs text-emerald-500 mt-1">
                  Tên sẽ được chuyển thành: {formData.name.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '')}
                </p>
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1.5">
                  Nhãn hiển thị
                </label>
                <input
                  type="text"
                  required
                  value={formData.label}
                  onChange={(e) => setFormData({ ...formData, label: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900"
                  placeholder="vd: Mã vạch, Xuất xứ, Bảo hành"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1.5">
                  Kiểu dữ liệu
                </label>
                <select
                  value={formData.type}
                  onChange={(e) => setFormData({ ...formData, type: e.target.value as any })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900"
                >
                  {FIELD_TYPES.map((type) => (
                    <option key={type.key} value={type.key}>{type.label}</option>
                  ))}
                </select>
              </div>

              {formData.type === 'select' && (
                <div>
                  <label className="block text-sm font-medium text-emerald-700 mb-1.5">
                    Các lựa chọn
                  </label>
                  <div className="space-y-2">
                    {formData.options.map((option, index) => (
                      <div key={index} className="flex gap-2">
                        <input
                          type="text"
                          value={option}
                          onChange={(e) => updateOption(index, e.target.value)}
                          className="flex-1 border border-emerald-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900"
                          placeholder={`Lựa chọn ${index + 1}`}
                        />
                        {formData.options.length > 1 && (
                          <button
                            type="button"
                            onClick={() => removeOption(index)}
                            className="p-2 text-red-600 hover:bg-red-50 rounded-lg"
                          >
                            <X className="w-4 h-4" />
                          </button>
                        )}
                      </div>
                    ))}
                    <button
                      type="button"
                      onClick={addOption}
                      className="text-sm text-emerald-600 hover:text-emerald-700 font-medium"
                    >
                      + Thêm lựa chọn
                    </button>
                  </div>
                </div>
              )}

              <label className="flex items-center gap-3 p-3 border border-emerald-100 rounded-lg cursor-pointer hover:bg-emerald-50/50">
                <input
                  type="checkbox"
                  checked={formData.required}
                  onChange={(e) => setFormData({ ...formData, required: e.target.checked })}
                  className="w-4 h-4 text-emerald-600 rounded border-emerald-300 focus:ring-emerald-500"
                />
                <span className="text-emerald-900">Bắt buộc nhập</span>
              </label>

              <div className="flex gap-3 pt-4">
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
                  {editingField ? 'Cập nhật' : 'Thêm trường'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
