'use client';

import { useState, useEffect } from 'react';
import { useAuth } from './AuthProvider';
import { updateDoc, doc, getFirestore } from 'firebase/firestore';
import { 
  Package, 
  Store, 
  MapPin, 
  ShoppingBag, 
  ArrowRight, 
  Check,
  Sparkles,
  Users
} from 'lucide-react';

const BUSINESS_CATEGORIES = [
  { id: 'fashion', name: 'Thời trang', icon: '👕' },
  { id: 'electronics', name: 'Điện tử', icon: '📱' },
  { id: 'food', name: 'Thực phẩm', icon: '🍜' },
  { id: 'beauty', name: 'Mỹ phẩm', icon: '💄' },
  { id: 'home', name: 'Nội thất', icon: '🏠' },
  { id: 'toys', name: 'Đồ chơi', icon: '🧸' },
  { id: 'books', name: 'Sách', icon: '📚' },
  { id: 'sports', name: 'Thể thao', icon: '⚽' },
  { id: 'automotive', name: 'Ô tô & Phụ tùng', icon: '🚗' },
  { id: 'health', name: 'Sức khỏe', icon: '💊' },
  { id: 'office', name: 'Văn phòng phẩm', icon: '📎' },
  { id: 'other', name: 'Khác', icon: '📦' },
];

export default function WelcomeModal() {
  const { user } = useAuth();
  const [show, setShow] = useState(false);
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    storeName: '',
    category: '',
    location: '',
    businessType: 'retail', // retail or wholesale
  });

  useEffect(() => {
    // Check if user has completed onboarding
    if (user && !user.storeName) {
      setShow(true);
    }
  }, [user]);

  const handleComplete = async () => {
    if (!user?.uid) return;
    
    setLoading(true);
    try {
      const db = getFirestore();
      await updateDoc(doc(db, 'users', user.uid), {
        storeName: formData.storeName,
        businessCategory: formData.category,
        location: formData.location,
        businessType: formData.businessType,
        onboardingCompleted: true,
        updatedAt: new Date().toISOString(),
      });
      setShow(false);
      window.location.reload(); // Reload to refresh user data
    } catch (error) {
      console.error('Error saving onboarding data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (!show) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="bg-gradient-to-r from-emerald-500 to-teal-600 p-6 text-center">
          <div className="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
            <Sparkles className="w-8 h-8 text-white" />
          </div>
          <h2 className="text-2xl font-bold text-white">Chào mừng đến ProDKT!</h2>
          <p className="text-emerald-100 mt-2">Hãy thiết lập cửa hàng của bạn</p>
        </div>

        {/* Progress */}
        <div className="flex items-center justify-center gap-2 p-4 border-b border-emerald-100">
          {[1, 2, 3].map((s) => (
            <div
              key={s}
              className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold ${
                step >= s
                  ? 'bg-emerald-500 text-white'
                  : 'bg-emerald-100 text-emerald-400'
              }`}
            >
              {step > s ? <Check className="w-4 h-4" /> : s}
            </div>
          ))}
        </div>

        {/* Step 1: Store Name */}
        {step === 1 && (
          <div className="p-6 space-y-4">
            <div className="text-center mb-6">
              <Store className="w-12 h-12 text-emerald-500 mx-auto mb-3" />
              <h3 className="text-xl font-bold text-emerald-900">Tên cửa hàng</h3>
              <p className="text-emerald-600">Khách hàng sẽ thấy tên này</p>
            </div>
            <input
              type="text"
              value={formData.storeName}
              onChange={(e) => setFormData({ ...formData, storeName: e.target.value })}
              className="w-full border-2 border-emerald-200 rounded-xl px-4 py-3 text-lg text-center focus:border-emerald-500 focus:outline-none"
              placeholder="Ví dụ: Shop ABC"
              autoFocus
            />
            <button
              onClick={() => formData.storeName && setStep(2)}
              disabled={!formData.storeName}
              className="w-full bg-emerald-500 text-white rounded-xl py-3 font-semibold flex items-center justify-center gap-2 hover:bg-emerald-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Tiếp tục <ArrowRight className="w-5 h-5" />
            </button>
          </div>
        )}

        {/* Step 2: Category */}
        {step === 2 && (
          <div className="p-6 space-y-4">
            <div className="text-center mb-6">
              <ShoppingBag className="w-12 h-12 text-emerald-500 mx-auto mb-3" />
              <h3 className="text-xl font-bold text-emerald-900">Ngành hàng</h3>
              <p className="text-emerald-600">Chọn lĩnh vực kinh doanh</p>
            </div>
            <div className="grid grid-cols-3 gap-3 max-h-60 overflow-y-auto">
              {BUSINESS_CATEGORIES.map((cat) => (
                <button
                  key={cat.id}
                  onClick={() => {
                    setFormData({ ...formData, category: cat.id });
                    setStep(3);
                  }}
                  className={`p-3 rounded-xl border-2 text-center transition-all ${
                    formData.category === cat.id
                      ? 'border-emerald-500 bg-emerald-50'
                      : 'border-emerald-100 hover:border-emerald-300'
                  }`}
                >
                  <span className="text-2xl mb-1 block">{cat.icon}</span>
                  <span className="text-sm font-medium text-emerald-900">{cat.name}</span>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Step 3: Location & Type */}
        {step === 3 && (
          <div className="p-6 space-y-4">
            <div className="text-center mb-6">
              <MapPin className="w-12 h-12 text-emerald-500 mx-auto mb-3" />
              <h3 className="text-xl font-bold text-emerald-900">Thông tin bổ sung</h3>
              <p className="text-emerald-600">Giúp chúng tôi gợi ý đối tác phù hợp</p>
            </div>

            <div className="space-y-3">
              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-2">
                  Địa điểm (Tỉnh/Thành phố)
                </label>
                <input
                  type="text"
                  value={formData.location}
                  onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                  className="w-full border-2 border-emerald-200 rounded-xl px-4 py-3 focus:border-emerald-500 focus:outline-none"
                  placeholder="Ví dụ: TP. Hồ Chí Minh"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-2">
                  Loại hình kinh doanh
                </label>
                <div className="grid grid-cols-2 gap-3">
                  <button
                    onClick={() => setFormData({ ...formData, businessType: 'retail' })}
                    className={`p-3 rounded-xl border-2 text-center transition-all ${
                      formData.businessType === 'retail'
                        ? 'border-emerald-500 bg-emerald-50'
                        : 'border-emerald-100 hover:border-emerald-300'
                    }`}
                  >
                    <Package className="w-6 h-6 mx-auto mb-2 text-emerald-500" />
                    <span className="text-sm font-medium text-emerald-900">Bán lẻ</span>
                  </button>
                  <button
                    onClick={() => setFormData({ ...formData, businessType: 'wholesale' })}
                    className={`p-3 rounded-xl border-2 text-center transition-all ${
                      formData.businessType === 'wholesale'
                        ? 'border-emerald-500 bg-emerald-50'
                        : 'border-emerald-100 hover:border-emerald-300'
                    }`}
                  >
                    <Users className="w-6 h-6 mx-auto mb-2 text-emerald-500" />
                    <span className="text-sm font-medium text-emerald-900">Bán sỉ</span>
                  </button>
                </div>
              </div>
            </div>

            <button
              onClick={handleComplete}
              disabled={loading || !formData.location}
              className="w-full bg-gradient-to-r from-emerald-500 to-teal-600 text-white rounded-xl py-3 font-semibold flex items-center justify-center gap-2 hover:opacity-90 transition-opacity disabled:opacity-50"
            >
              {loading ? (
                <span>Đang lưu...</span>
              ) : (
                <>
                  <Check className="w-5 h-5" />
                  Hoàn tất
                </>
              )}
            </button>
          </div>
        )}

        {/* Skip option */}
        <div className="p-4 text-center border-t border-emerald-100">
          <button
            onClick={() => setShow(false)}
            className="text-sm text-emerald-500 hover:text-emerald-700"
          >
            Bỏ qua, thiết lập sau
          </button>
        </div>
      </div>
    </div>
  );
}
