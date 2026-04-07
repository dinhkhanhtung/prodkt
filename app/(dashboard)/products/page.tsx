'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { getProducts, addProduct, updateProduct, deleteProduct, Product, WithId } from '@/lib/firestore';
import { uploadImageToImgBB } from '@/lib/imgbb';
import { Plus, Edit2, Trash2, Search, Upload, X, ImageIcon } from 'lucide-react';

interface ProductFormData {
  name: string;
  price: string;
  cost: string;
  stock: string;
  imageURL: string;
  description: string;
}

const initialFormData: ProductFormData = {
  name: '',
  price: '',
  cost: '',
  stock: '',
  imageURL: '',
  description: '',
};

export default function ProductsPage() {
  const { user } = useAuth();
  const [products, setProducts] = useState<(Product & WithId)[]>([]);
  const [filteredProducts, setFilteredProducts] = useState<(Product & WithId)[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<(Product & WithId) | null>(null);
  const [formData, setFormData] = useState<ProductFormData>(initialFormData);
  const [uploadingImage, setUploadingImage] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  const loadProducts = useCallback(async () => {
    if (!user?.storeId) return;
    try {
      const data = await getProducts(user.storeId);
      setProducts(data);
      setFilteredProducts(data);
    } catch (error) {
      console.error('Error loading products:', error);
    } finally {
      setLoading(false);
    }
  }, [user]);

  useEffect(() => {
    loadProducts();
  }, [loadProducts]);

  useEffect(() => {
    if (searchQuery.trim() === '') {
      setFilteredProducts(products);
    } else {
      const query = searchQuery.toLowerCase();
      setFilteredProducts(
        products.filter(
          (p) =>
            p.name.toLowerCase().includes(query) ||
            p.description?.toLowerCase().includes(query)
        )
      );
    }
  }, [searchQuery, products]);

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploadingImage(true);
    try {
      const imageURL = await uploadImageToImgBB(file);
      setFormData((prev) => ({ ...prev, imageURL }));
    } catch (error) {
      alert('Lỗi upload ảnh: ' + (error as Error).message);
    } finally {
      setUploadingImage(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user?.storeId) return;

    setSubmitting(true);
    try {
      const productData = {
        name: formData.name,
        price: parseFloat(formData.price) || 0,
        cost: parseFloat(formData.cost) || 0,
        stock: parseInt(formData.stock) || 0,
        imageURL: formData.imageURL,
        description: formData.description,
      };

      if (editingProduct) {
        await updateProduct(user.storeId, editingProduct.id, productData);
      } else {
        await addProduct(user.storeId, productData);
      }

      setIsModalOpen(false);
      setEditingProduct(null);
      setFormData(initialFormData);
      await loadProducts();
    } catch (error) {
      alert('Lỗi: ' + (error as Error).message);
    } finally {
      setSubmitting(false);
    }
  };

  const handleEdit = (product: Product & WithId) => {
    setEditingProduct(product);
    setFormData({
      name: product.name,
      price: product.price.toString(),
      cost: product.cost.toString(),
      stock: product.stock.toString(),
      imageURL: product.imageURL || '',
      description: product.description || '',
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (productId: string) => {
    if (!confirm('Bạn có chắc muốn xóa sản phẩm này?')) return;
    if (!user?.storeId) return;

    try {
      await deleteProduct(user.storeId, productId);
      await loadProducts();
    } catch (error) {
      alert('Lỗi xóa sản phẩm: ' + (error as Error).message);
    }
  };

  const openAddModal = () => {
    setEditingProduct(null);
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
        <h1 className="text-2xl font-bold text-gray-900">Quản lý sản phẩm</h1>
        <button onClick={openAddModal} className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" />
          Thêm sản phẩm
        </button>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
        <input
          type="text"
          placeholder="Tìm kiếm sản phẩm..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="input pl-10"
        />
      </div>

      {/* Products Grid */}
      {filteredProducts.length === 0 ? (
        <div className="card text-center py-12">
          <Package className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <p className="text-gray-500">Chưa có sản phẩm nào</p>
          <button onClick={openAddModal} className="btn-primary mt-4">
            Thêm sản phẩm đầu tiên
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {filteredProducts.map((product) => (
            <div key={product.id} className="card p-4">
              <div className="aspect-square bg-gray-100 rounded-lg mb-4 overflow-hidden">
                {product.imageURL ? (
                  <img
                    src={product.imageURL}
                    alt={product.name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <ImageIcon className="w-12 h-12 text-gray-300" />
                  </div>
                )}
              </div>
              <h3 className="font-semibold text-gray-900 truncate">{product.name}</h3>
              <p className="text-sm text-gray-500 mt-1">Tồn kho: {product.stock}</p>
              <div className="flex items-center justify-between mt-3">
                <div>
                  <p className="text-lg font-bold text-primary-600">
                    {formatCurrency(product.price)}
                  </p>
                  <p className="text-xs text-gray-400">
                    Giá vốn: {formatCurrency(product.cost)}
                  </p>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => handleEdit(product)}
                    className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg"
                  >
                    <Edit2 className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => handleDelete(product.id)}
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
            <div
              className="fixed inset-0 bg-gray-900/50"
              onClick={() => setIsModalOpen(false)}
            />
            <div className="relative bg-white rounded-lg shadow-xl max-w-lg w-full p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-gray-900">
                  {editingProduct ? 'Sửa sản phẩm' : 'Thêm sản phẩm'}
                </h2>
                <button
                  onClick={() => setIsModalOpen(false)}
                  className="p-2 text-gray-400 hover:text-gray-600"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <form onSubmit={handleSubmit} className="space-y-4">
                {/* Image Upload */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Ảnh sản phẩm
                  </label>
                  <div className="flex items-center gap-4">
                    {formData.imageURL ? (
                      <div className="relative">
                        <img
                          src={formData.imageURL}
                          alt="Preview"
                          className="w-20 h-20 object-cover rounded-lg"
                        />
                        <button
                          type="button"
                          onClick={() => setFormData((prev) => ({ ...prev, imageURL: '' }))}
                          className="absolute -top-2 -right-2 p-1 bg-red-500 text-white rounded-full"
                        >
                          <X className="w-3 h-3" />
                        </button>
                      </div>
                    ) : (
                      <label className="flex items-center justify-center w-20 h-20 border-2 border-dashed border-gray-300 rounded-lg cursor-pointer hover:border-primary-500">
                        <input
                          type="file"
                          accept="image/*"
                          onChange={handleImageUpload}
                          className="hidden"
                          disabled={uploadingImage}
                        />
                        {uploadingImage ? (
                          <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-primary-600" />
                        ) : (
                          <Upload className="w-6 h-6 text-gray-400" />
                        )}
                      </label>
                    )}
                    <p className="text-xs text-gray-500">
                      Tải ảnh lên ImgBB
                      <br />
                      (Tối đa 32MB)
                    </p>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700">Tên sản phẩm</label>
                  <input
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) => setFormData((prev) => ({ ...prev, name: e.target.value }))}
                    className="input mt-1"
                    placeholder="Nhập tên sản phẩm"
                  />
                </div>

                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Giá bán</label>
                    <input
                      type="number"
                      required
                      min="0"
                      value={formData.price}
                      onChange={(e) => setFormData((prev) => ({ ...prev, price: e.target.value }))}
                      className="input mt-1"
                      placeholder="0"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Giá vốn</label>
                    <input
                      type="number"
                      min="0"
                      value={formData.cost}
                      onChange={(e) => setFormData((prev) => ({ ...prev, cost: e.target.value }))}
                      className="input mt-1"
                      placeholder="0"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Tồn kho</label>
                    <input
                      type="number"
                      min="0"
                      value={formData.stock}
                      onChange={(e) => setFormData((prev) => ({ ...prev, stock: e.target.value }))}
                      className="input mt-1"
                      placeholder="0"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700">Mô tả</label>
                  <textarea
                    rows={3}
                    value={formData.description}
                    onChange={(e) => setFormData((prev) => ({ ...prev, description: e.target.value }))}
                    className="input mt-1"
                    placeholder="Mô tả sản phẩm (tùy chọn)"
                  />
                </div>

                <div className="flex gap-3 pt-4">
                  <button
                    type="button"
                    onClick={() => setIsModalOpen(false)}
                    className="flex-1 btn-secondary"
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    disabled={submitting}
                    className="flex-1 btn-primary flex justify-center items-center gap-2"
                  >
                    {submitting && <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />}
                    {editingProduct ? 'Cập nhật' : 'Thêm mới'}
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

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
  }).format(amount);
}
