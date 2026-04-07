'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
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
  Shield,
  ChevronRight,
  LayoutDashboard,
  Menu,
  X,
  ArrowLeft
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
  const pathname = usePathname();
  const [activeTab, setActiveTab] = useState('profile');
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  
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

  const isAdmin = user?.role === 'admin';

  return (
    <div className="min-h-screen bg-slate-50 -m-4 sm:-m-6 lg:-m-8">
      {/* Mobile Header */}
      <header className="lg:hidden bg-white border-b border-slate-200 sticky top-0 z-10">
        <div className="flex items-center justify-between h-16 px-4">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 bg-gradient-to-br from-violet-600 to-indigo-600 rounded-lg flex items-center justify-center">
              <User className="w-4 h-4 text-white" />
            </div>
            <span className="font-bold text-slate-900">Cài đặt</span>
          </div>
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="p-2 text-slate-600 hover:text-slate-900 hover:bg-slate-100 rounded-lg"
          >
            {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {/* Mobile Menu */}
        {mobileMenuOpen && (
          <div className="border-t border-slate-200 bg-white">
            <nav className="px-4 py-4 space-y-1">
              {TABS.map((tab) => {
                const Icon = tab.icon;
                return (
                  <button
                    key={tab.id}
                    onClick={() => {
                      setActiveTab(tab.id);
                      setMobileMenuOpen(false);
                    }}
                    className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors ${
                      activeTab === tab.id
                        ? 'bg-violet-50 text-violet-700'
                        : 'text-slate-600 hover:bg-slate-50'
                    }`}
                  >
                    <Icon className="w-5 h-5" />
                    {tab.label}
                  </button>
                );
              })}
              <hr className="my-3 border-slate-100" />
              <Link
                href="/dashboard"
                className="flex items-center gap-3 px-4 py-3 text-sm font-medium text-slate-600 hover:bg-slate-50 rounded-xl"
              >
                <LayoutDashboard className="w-5 h-5" />
                Về Dashboard
              </Link>
              {isAdmin && (
                <Link
                  href="/admin"
                  className="flex items-center gap-3 px-4 py-3 text-sm font-medium text-violet-600 hover:bg-violet-50 rounded-xl"
                >
                  <Shield className="w-5 h-5" />
                  Bảng điều khiển
                </Link>
              )}
            </nav>
          </div>
        )}
      </header>

      <div className="flex flex-col lg:flex-row min-h-screen">
        {/* Sidebar */}
        <aside className="hidden lg:flex lg:w-72 lg:flex-col lg:fixed lg:inset-y-0 lg:left-0 lg:z-50 bg-white border-r border-slate-200">
          <div className="h-16 flex items-center px-6 border-b border-slate-200">
            <Link href="/dashboard" className="flex items-center gap-2">
              <ArrowLeft className="w-5 h-5 text-slate-400" />
              <span className="font-semibold text-slate-900">Quay lại</span>
            </Link>
          </div>

          <div className="p-6 border-b border-slate-200">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-violet-500 to-indigo-600 flex items-center justify-center text-white font-bold text-lg">
                {profile.name.charAt(0)}
              </div>
              <div>
                <p className="font-semibold text-slate-900">{profile.name}</p>
                <div className="flex items-center gap-2 mt-1">
                  <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-violet-100 text-violet-700">
                    <Shield className="w-3 h-3" />
                    Admin
                  </span>
                </div>
              </div>
            </div>
          </div>

          <nav className="flex-1 px-4 py-6 space-y-1">
            <p className="px-4 text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">
              Cài đặt
            </p>
            {TABS.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all ${
                    activeTab === tab.id
                      ? 'bg-gradient-to-r from-violet-50 to-indigo-50 text-violet-700 shadow-sm'
                      : 'text-slate-600 hover:bg-slate-50'
                  }`}
                >
                  <div className={`w-9 h-9 rounded-lg flex items-center justify-center ${
                    activeTab === tab.id
                      ? 'bg-gradient-to-br from-violet-600 to-indigo-600 text-white'
                      : 'bg-slate-100 text-slate-500'
                  }`}>
                    <Icon className="w-4 h-4" />
                  </div>
                  {tab.label}
                  {activeTab === tab.id && <ChevronRight className="w-4 h-4 ml-auto" />}
                </button>
              );
            })}
          </nav>

          {isAdmin && (
            <div className="p-4 m-4 bg-gradient-to-r from-violet-50 to-indigo-50 rounded-xl border border-violet-100">
              <div className="flex items-center gap-2">
                <Shield className="w-4 h-4 text-violet-600" />
                <div>
                  <p className="text-xs font-semibold text-violet-900">Quản Trị Viên</p>
                  <Link href="/admin" className="text-xs text-violet-600 hover:underline">
                    Vào bảng điều khiển →
                  </Link>
                </div>
              </div>
            </div>
          )}
        </aside>

        {/* Main Content */}
        <main className="flex-1 lg:ml-72 p-4 sm:p-6 lg:p-8">
          <div className="max-w-3xl">
            {/* Header */}
            <div className="mb-8">
              <h1 className="text-2xl font-bold text-slate-900">
                {TABS.find(t => t.id === activeTab)?.label}
              </h1>
              <p className="text-slate-500 mt-1">
                {activeTab === 'profile' && 'Quản lý thông tin cá nhân'}
                {activeTab === 'family' && 'Quản lý thành viên gia đình'}
                {activeTab === 'subscription' && 'Quản lý gói dịch vụ'}
                {activeTab === 'notifications' && 'Tùy chỉnh thông báo'}
                {activeTab === 'appearance' && 'Tùy chỉnh giao diện'}
              </p>
            </div>

            {/* Content */}
            <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden">
              {/* Profile Tab */}
              {activeTab === 'profile' && (
                <div className="p-6">
                  <div className="max-w-lg space-y-5">
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1.5">Tên</label>
                      <input
                        type="text"
                        value={profile.name}
                        onChange={(e) => setProfile({ ...profile, name: e.target.value })}
                        className="w-full border border-slate-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-transparent"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1.5">Số điện thoại</label>
                      <input
                        type="tel"
                        value={profile.phone}
                        onChange={(e) => setProfile({ ...profile, phone: e.target.value })}
                        className="w-full border border-slate-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-transparent"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1.5">Email</label>
                      <div className="relative">
                        <input
                          type="email"
                          value={profile.email}
                          disabled
                          className="w-full border border-slate-200 bg-slate-50 rounded-lg px-3 py-2.5 text-slate-500 cursor-not-allowed pr-10"
                        />
                        <Shield className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-violet-500" />
                      </div>
                      <p className="text-xs text-slate-400 mt-1">Email không thể thay đổi</p>
                    </div>

                    <div className="pt-4">
                      <button
                        onClick={handleSave}
                        disabled={saving}
                        className={`px-4 py-2.5 rounded-lg font-medium flex items-center gap-2 transition-colors ${
                          saved
                            ? 'bg-emerald-500 text-white'
                            : 'bg-violet-600 hover:bg-violet-700 text-white disabled:opacity-50'
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
                <div className="p-12 text-center">
                  <Users className="w-12 h-12 text-slate-300 mx-auto mb-4" />
                  <p className="text-slate-500">Tính năng quản lý gia đình đang được phát triển</p>
                </div>
              )}

              {/* Subscription Tab */}
              {activeTab === 'subscription' && (
                <div className="p-6 space-y-6">
                  <div className="p-4 bg-gradient-to-r from-violet-50 to-indigo-50 rounded-xl border border-violet-100">
                    <div className="flex items-center justify-between">
                      <div>
                        <h3 className="font-semibold text-violet-900">Gói VIP</h3>
                        <p className="text-sm text-violet-600 mt-1">Vĩnh viễn</p>
                      </div>
                      <Crown className="w-10 h-10 text-violet-500" />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div className="p-4 border border-slate-200 rounded-xl">
                      <h4 className="font-medium text-slate-900 mb-3">Quyền lợi VIP</h4>
                      <ul className="space-y-2 text-sm text-slate-600">
                        {[
                          'Không giới hạn sản phẩm',
                          'Multi-store (5 cửa hàng)',
                          'Báo cáo nâng cao',
                          'Hỗ trợ ưu tiên 24/7',
                        ].map((benefit, idx) => (
                          <li key={idx} className="flex items-center gap-2">
                            <CheckCircle className="w-4 h-4 text-emerald-500" />
                            {benefit}
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </div>
              )}

              {/* Notifications Tab */}
              {activeTab === 'notifications' && (
                <div className="p-6">
                  <div className="max-w-lg space-y-3">
                    {[
                      { key: 'email', label: 'Thông báo qua email', desc: 'Nhận thông báo về đơn hàng, thanh toán' },
                      { key: 'push', label: 'Thông báo đẩy', desc: 'Thông báo real-time trên trình duyệt' },
                      { key: 'updates', label: 'Cập nhật sản phẩm', desc: 'Thông báo khi có tính năng mới' },
                      { key: 'marketing', label: 'Khuyến mãi & Ưu đãi', desc: 'Nhận thông tin khuyến mãi' },
                    ].map((item) => (
                      <label key={item.key} className="flex items-start gap-3 p-3 border border-slate-200 rounded-lg cursor-pointer hover:bg-slate-50 transition-colors">
                        <input
                          type="checkbox"
                          checked={notifications[item.key as keyof typeof notifications]}
                          onChange={(e) => setNotifications({ ...notifications, [item.key]: e.target.checked })}
                          className="w-4 h-4 text-violet-600 rounded border-slate-300 focus:ring-violet-500 mt-0.5"
                        />
                        <div>
                          <p className="font-medium text-slate-900">{item.label}</p>
                          <p className="text-sm text-slate-500">{item.desc}</p>
                        </div>
                      </label>
                    ))}
                  </div>
                </div>
              )}

              {/* Appearance Tab */}
              {activeTab === 'appearance' && (
                <div className="p-6">
                  <div className="max-w-lg space-y-5">
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-2">Chế độ</label>
                      <div className="grid grid-cols-3 gap-2">
                        {['light', 'dark', 'auto'].map((theme) => (
                          <button
                            key={theme}
                            onClick={() => setAppearance({ ...appearance, theme })}
                            className={`px-4 py-2.5 rounded-lg border text-sm font-medium transition-colors ${
                              appearance.theme === theme
                                ? 'border-violet-500 bg-violet-50 text-violet-700'
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

                    <label className="flex items-center gap-3 p-3 border border-slate-200 rounded-lg cursor-pointer hover:bg-slate-50 transition-colors">
                      <input
                        type="checkbox"
                        checked={appearance.compact}
                        onChange={(e) => setAppearance({ ...appearance, compact: e.target.checked })}
                        className="w-4 h-4 text-violet-600 rounded border-slate-300 focus:ring-violet-500"
                      />
                      <div>
                        <p className="font-medium text-slate-900">Chế độ gọn</p>
                        <p className="text-sm text-slate-500">Giảm khoảng cách giữa các phần tử</p>
                      </div>
                    </label>
                  </div>
                </div>
              )}
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
