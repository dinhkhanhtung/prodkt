'use client';

import { useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { doc, updateDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { 
  User, 
  Users, 
  CreditCard, 
  Bell, 
  Palette, 
  Save,
  CheckCircle,
  Crown,
  Shield
} from 'lucide-react';

const TABS = [
  { id: 'profile', label: 'Hồ sơ', icon: User },
  { id: 'family', label: 'Gia đình', icon: Users },
  { id: 'subscription', label: 'Gói dịch vụ', icon: CreditCard },
  { id: 'notifications', label: 'Thông báo', icon: Bell },
  { id: 'appearance', label: 'Giao diện', icon: Palette },
];

export default function SettingsPage() {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState('profile');
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  
  // Profile form state
  const [profile, setProfile] = useState({
    name: 'Administrator',
    phone: '0982581222',
    email: user?.email || 'geminipro1year@gmail.com',
  });

  // Notification preferences
  const [notifications, setNotifications] = useState({
    email: true,
    push: true,
    marketing: false,
    updates: true,
  });

  // Appearance
  const [appearance, setAppearance] = useState({
    theme: 'light',
    compact: false,
  });

  const handleSave = async () => {
    if (!user) return;
    
    setSaving(true);
    try {
      const userRef = doc(db, 'users', user.uid);
      await updateDoc(userRef, {
        ...profile,
        updatedAt: new Date().toISOString(),
      });
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    } catch (error) {
      console.error('Error saving:', error);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 py-8">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-slate-900">Cài đặt</h1>
          <p className="text-slate-500 mt-1">Quản lý thông tin cá nhân và tùy chọn</p>
        </div>

        <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
          {/* Tabs */}
          <div className="border-b border-slate-200">
            <div className="flex overflow-x-auto">
              {TABS.map((tab) => {
                const Icon = tab.icon;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`flex items-center gap-2 px-6 py-4 text-sm font-medium border-b-2 transition-colors whitespace-nowrap ${
                      activeTab === tab.id
                        ? 'border-emerald-500 text-emerald-600'
                        : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
                    }`}
                  >
                    <Icon className="w-4 h-4" />
                    {tab.label}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Content */}
          <div className="p-6">
            {/* Profile Tab */}
            {activeTab === 'profile' && (
              <div className="max-w-lg">
                <div className="flex items-center gap-4 mb-6">
                  <div className="w-16 h-16 rounded-full bg-gradient-to-br from-violet-500 to-indigo-600 flex items-center justify-center text-white text-xl font-bold">
                    {profile.name.charAt(0)}
                  </div>
                  <div>
                    <h3 className="font-semibold text-slate-900">{profile.name}</h3>
                    <div className="flex items-center gap-2 mt-1">
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-violet-100 text-violet-700">
                        <Shield className="w-3 h-3" />
                        Admin
                      </span>
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
                        <Crown className="w-3 h-3" />
                        VIP
                      </span>
                    </div>
                  </div>
                </div>

                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1.5">Tên</label>
                    <input
                      type="text"
                      value={profile.name}
                      onChange={(e) => setProfile({ ...profile, name: e.target.value })}
                      className="w-full border border-slate-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1.5">Số điện thoại</label>
                    <input
                      type="tel"
                      value={profile.phone}
                      onChange={(e) => setProfile({ ...profile, phone: e.target.value })}
                      className="w-full border border-slate-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1.5">Email</label>
                    <div className="relative">
                      <input
                        type="email"
                        value={profile.email}
                        disabled
                        className="w-full border border-slate-200 bg-slate-50 rounded-lg px-3 py-2.5 text-slate-500 cursor-not-allowed"
                      />
                      <Shield className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-violet-500" />
                    </div>
                    <p className="text-xs text-slate-400 mt-1">Email không thể thay đổi</p>
                  </div>

                  <div className="pt-4">
                    <button
                      onClick={handleSave}
                      disabled={saving}
                      className={`px-4 py-2 rounded-lg font-medium flex items-center gap-2 transition-colors ${
                        saved
                          ? 'bg-emerald-500 text-white'
                          : 'bg-emerald-500 hover:bg-emerald-600 text-white disabled:opacity-50'
                      }`}
                    >
                      {saving ? (
                        <>
                          <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                          Đang lưu...
                        </>
                      ) : saved ? (
                        <>
                          <CheckCircle className="w-4 h-4" />
                          Đã lưu
                        </>
                      ) : (
                        <>
                          <Save className="w-4 h-4" />
                          Lưu thay đổi
                        </>
                      )}
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* Family Tab */}
            {activeTab === 'family' && (
              <div>
                <p className="text-slate-500">Tính năng quản lý gia đình đang được phát triển</p>
              </div>
            )}

            {/* Subscription Tab */}
            {activeTab === 'subscription' && (
              <div className="space-y-4">
                <div className="p-4 bg-gradient-to-r from-violet-50 to-indigo-50 rounded-xl border border-violet-100">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="font-semibold text-violet-900">Gói VIP</h3>
                      <p className="text-sm text-violet-600 mt-1">Vĩnh viễn</p>
                    </div>
                    <Crown className="w-8 h-8 text-violet-500" />
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="p-4 border border-slate-200 rounded-xl">
                    <h4 className="font-medium text-slate-900 mb-2">Quyền lợi VIP</h4>
                    <ul className="space-y-2 text-sm text-slate-600">
                      <li className="flex items-center gap-2">
                        <CheckCircle className="w-4 h-4 text-emerald-500" />
                        Không giới hạn sản phẩm
                      </li>
                      <li className="flex items-center gap-2">
                        <CheckCircle className="w-4 h-4 text-emerald-500" />
                        Multi-store (5 cửa hàng)
                      </li>
                      <li className="flex items-center gap-2">
                        <CheckCircle className="w-4 h-4 text-emerald-500" />
                        Báo cáo nâng cao
                      </li>
                      <li className="flex items-center gap-2">
                        <CheckCircle className="w-4 h-4 text-emerald-500" />
                        Hỗ trợ ưu tiên 24/7
                      </li>
                    </ul>
                  </div>
                </div>
              </div>
            )}

            {/* Notifications Tab */}
            {activeTab === 'notifications' && (
              <div className="max-w-lg space-y-4">
                <h3 className="font-medium text-slate-900 mb-4">Tùy chọn thông báo</h3>
                
                {[
                  { key: 'email', label: 'Thông báo qua email', desc: 'Nhận thông báo về đơn hàng, thanh toán' },
                  { key: 'push', label: 'Thông báo đẩy', desc: 'Thông báo real-time trên trình duyệt' },
                  { key: 'updates', label: 'Cập nhật sản phẩm', desc: 'Thông báo khi có tính năng mới' },
                  { key: 'marketing', label: 'Khuyến mãi & Ưu đãi', desc: 'Nhận thông tin khuyến mãi' },
                ].map((item) => (
                  <label key={item.key} className="flex items-start gap-3 p-3 border border-slate-200 rounded-lg cursor-pointer hover:bg-slate-50">
                    <input
                      type="checkbox"
                      checked={notifications[item.key as keyof typeof notifications]}
                      onChange={(e) => setNotifications({ ...notifications, [item.key]: e.target.checked })}
                      className="w-4 h-4 text-emerald-600 rounded border-slate-300 focus:ring-emerald-500 mt-0.5"
                    />
                    <div>
                      <p className="font-medium text-slate-900">{item.label}</p>
                      <p className="text-sm text-slate-500">{item.desc}</p>
                    </div>
                  </label>
                ))}
              </div>
            )}

            {/* Appearance Tab */}
            {activeTab === 'appearance' && (
              <div className="max-w-lg space-y-4">
                <h3 className="font-medium text-slate-900 mb-4">Giao diện</h3>
                
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Chế độ</label>
                  <div className="grid grid-cols-3 gap-2">
                    {['light', 'dark', 'auto'].map((theme) => (
                      <button
                        key={theme}
                        onClick={() => setAppearance({ ...appearance, theme })}
                        className={`px-4 py-2 rounded-lg border text-sm font-medium transition-colors ${
                          appearance.theme === theme
                            ? 'border-emerald-500 bg-emerald-50 text-emerald-700'
                            : 'border-slate-200 hover:bg-slate-50'
                        }`}
                      >
                        {theme === 'light' && 'Sáng'}
                        {theme === 'dark' && 'Tối'}
                        {theme === 'auto' && 'Tự động'}
                      </button>
                    ))}
                  </div>
                </div>

                <label className="flex items-center gap-3 p-3 border border-slate-200 rounded-lg cursor-pointer hover:bg-slate-50 mt-4">
                  <input
                    type="checkbox"
                    checked={appearance.compact}
                    onChange={(e) => setAppearance({ ...appearance, compact: e.target.checked })}
                    className="w-4 h-4 text-emerald-600 rounded border-slate-300 focus:ring-emerald-500"
                  />
                  <div>
                    <p className="font-medium text-slate-900">Chế độ gọn</p>
                    <p className="text-sm text-slate-500">Giảm khoảng cách giữa các phần tử</p>
                  </div>
                </label>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
