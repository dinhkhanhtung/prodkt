'use client';

import { useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { doc, updateDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { 
  User, Users, CreditCard, Bell, Palette, Save,
  CheckCircle, Crown, Shield, Loader2, Database, Download, FileJson, Truck, Package
} from 'lucide-react';
import { 
  getProducts, getCustomers, getOrders, getSuppliers, getExpenses
} from '@/lib/firestore';
import {
  convertToCSV, downloadCSV, EXPORT_CONFIGS,
  formatProductsForExport, formatCustomersForExport,
  formatOrdersForExport, formatExpensesForExport,
  formatSuppliersForExport, exportAllDataAsJSON
} from '@/lib/export';

const TABS = [
  { id: 'profile', label: 'Hồ sơ', icon: User },
  { id: 'family', label: 'Gia đình', icon: Users },
  { id: 'subscription', label: 'Gói dịch vụ', icon: CreditCard },
  { id: 'notifications', label: 'Thông báo', icon: Bell },
  { id: 'appearance', label: 'Giao diện', icon: Palette },
  { id: 'data', label: 'Sao lưu dữ liệu', icon: Database },
];

export default function SettingsPage() {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState('profile');
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  
  const [profile, setProfile] = useState({
    name: 'Administrator',
    phone: '0982581222',
    email: user?.email || 'geminipro1year@gmail.com',
  });

  const [notifications, setNotifications] = useState({
    email: true, push: true, marketing: false, updates: true,
  });

  const [appearance, setAppearance] = useState({
    theme: 'light', compact: false,
  });

  // Data export state
  const [exporting, setExporting] = useState<string | null>(null);
  const storeId = user?.storeId;

  const handleSave = async () => {
    if (!user) return;
    setSaving(true);
    try {
      await updateDoc(doc(db, 'users', user.uid), {
        ...profile,
        updatedAt: new Date().toISOString(),
      });
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    } finally {
      setSaving(false);
    }
  };

  // Export functions
  const handleExport = async (type: 'products' | 'customers' | 'orders' | 'expenses' | 'suppliers') => {
    if (!storeId) return;
    setExporting(type);
    try {
      let data: any[] = [];
      switch (type) {
        case 'products':
          data = formatProductsForExport(await getProducts(storeId));
          break;
        case 'customers':
          data = formatCustomersForExport(await getCustomers(storeId));
          break;
        case 'orders':
          data = formatOrdersForExport(await getOrders(storeId));
          break;
        case 'expenses':
          data = formatExpensesForExport(await getExpenses(storeId));
          break;
        case 'suppliers':
          data = formatSuppliersForExport(await getSuppliers(storeId));
          break;
      }
      
      const config = EXPORT_CONFIGS[type];
      const csv = convertToCSV(data, config.headers);
      downloadCSV(csv, config.filename);
    } catch (error) {
      console.error('Export error:', error);
      alert('Có lỗi xảy ra khi xuất dữ liệu');
    } finally {
      setExporting(null);
    }
  };

  const handleExportAll = async () => {
    if (!storeId) return;
    setExporting('all');
    try {
      const [products, customers, orders, expenses, suppliers] = await Promise.all([
        getProducts(storeId),
        getCustomers(storeId),
        getOrders(storeId),
        getExpenses(storeId),
        getSuppliers(storeId),
      ]);
      
      exportAllDataAsJSON({
        products: formatProductsForExport(products),
        customers: formatCustomersForExport(customers),
        orders: formatOrdersForExport(orders),
        expenses: formatExpensesForExport(expenses),
        suppliers: formatSuppliersForExport(suppliers),
      });
    } catch (error) {
      console.error('Export all error:', error);
      alert('Có lỗi xảy ra khi sao lưu dữ liệu');
    } finally {
      setExporting(null);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header with tabs */}
      <div>
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center">
            <Shield className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-emerald-900">Cài đặt</h1>
            <p className="text-emerald-600/70 text-sm">{user?.email}</p>
          </div>
        </div>

        <div className="border-b border-emerald-100">
          <nav className="flex gap-1 overflow-x-auto">
            {TABS.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors whitespace-nowrap ${
                    activeTab === tab.id
                      ? 'border-emerald-500 text-emerald-600'
                      : 'border-transparent text-emerald-600/60 hover:text-emerald-700'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  {tab.label}
                </button>
              );
            })}
          </nav>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-3xl">
        {activeTab === 'profile' && (
          <div className="bg-white rounded-xl border border-emerald-100 p-6 shadow-sm">
            <div className="max-w-lg space-y-5">
              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1.5">Tên</label>
                <input
                  type="text"
                  value={profile.name}
                  onChange={(e) => setProfile({ ...profile, name: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1.5">Số điện thoại</label>
                <input
                  type="tel"
                  value={profile.phone}
                  onChange={(e) => setProfile({ ...profile, phone: e.target.value })}
                  className="w-full border border-emerald-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-1.5">Email</label>
                <div className="relative">
                  <input type="email" value={profile.email} disabled
                    className="w-full border border-emerald-200 bg-emerald-50/30 rounded-lg px-3 py-2.5 text-emerald-600/70 cursor-not-allowed pr-10" />
                  <Shield className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-emerald-500" />
                </div>
              </div>
              <div className="pt-4">
                <button onClick={handleSave} disabled={saving}
                  className={`px-4 py-2.5 rounded-lg font-medium flex items-center gap-2 ${
                    saved ? 'bg-emerald-500 text-white' : 'bg-emerald-600 hover:bg-emerald-700 text-white'
                  }`}>
                  {saving ? <><div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" /> Đang lưu...</>
                    : saved ? <><CheckCircle className="w-4 h-4" /> Đã lưu</>
                    : <><Save className="w-4 h-4" /> Lưu thay đổi</>}
                </button>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'family' && (
          <div className="bg-white rounded-xl border border-emerald-100 p-12 text-center shadow-sm">
            <Users className="w-12 h-12 text-emerald-300 mx-auto mb-4" />
            <p className="text-emerald-600">Tính năng quản lý gia đình đang phát triển</p>
          </div>
        )}

        {activeTab === 'subscription' && (
          <div className="bg-white rounded-xl border border-emerald-100 p-6 space-y-6 shadow-sm">
            <div className="p-4 bg-gradient-to-r from-emerald-50 to-teal-50 rounded-xl border border-emerald-100">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-semibold text-emerald-900">Gói VIP</h3>
                  <p className="text-sm text-emerald-600 mt-1">Vĩnh viễn</p>
                </div>
                <Crown className="w-10 h-10 text-emerald-500" />
              </div>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="p-4 border border-emerald-100 rounded-xl">
                <h4 className="font-medium text-emerald-900 mb-3">Quyền lợi VIP</h4>
                <ul className="space-y-2 text-sm text-emerald-700">
                  {['Không giới hạn sản phẩm', 'Multi-store (5 cửa hàng)', 'Báo cáo nâng cao', 'Hỗ trợ ưu tiên 24/7'].map((b, i) => (
                    <li key={i} className="flex items-center gap-2">
                      <CheckCircle className="w-4 h-4 text-emerald-500" /> {b}
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'notifications' && (
          <div className="bg-white rounded-xl border border-emerald-100 p-6 shadow-sm">
            <div className="max-w-lg space-y-3">
              {[
                { key: 'email', label: 'Thông báo qua email', desc: 'Nhận thông báo về đơn hàng, thanh toán' },
                { key: 'push', label: 'Thông báo đẩy', desc: 'Thông báo real-time trên trình duyệt' },
                { key: 'updates', label: 'Cập nhật sản phẩm', desc: 'Thông báo khi có tính năng mới' },
                { key: 'marketing', label: 'Khuyến mãi & Ưu đãi', desc: 'Nhận thông tin khuyến mãi' },
              ].map((item) => (
                <label key={item.key} className="flex items-start gap-3 p-3 border border-emerald-100 rounded-lg cursor-pointer hover:bg-emerald-50/50">
                  <input type="checkbox" checked={notifications[item.key as keyof typeof notifications]}
                    onChange={(e) => setNotifications({ ...notifications, [item.key]: e.target.checked })}
                    className="w-4 h-4 text-emerald-600 rounded border-emerald-300 focus:ring-emerald-500 mt-0.5" />
                  <div>
                    <p className="font-medium text-emerald-900">{item.label}</p>
                    <p className="text-sm text-emerald-600/70">{item.desc}</p>
                  </div>
                </label>
              ))}
            </div>
          </div>
        )}

        {activeTab === 'data' && (
          <div className="bg-white rounded-xl border border-emerald-100 p-6 shadow-sm space-y-6">
            <div>
              <h3 className="font-semibold text-emerald-900 mb-2">Xuất dữ liệu</h3>
              <p className="text-sm text-emerald-600/70 mb-4">Tải xuống dữ liệu của bạn dưới dạng CSV</p>
              
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {[
                  { key: 'products', label: 'Sản phẩm', icon: Package },
                  { key: 'customers', label: 'Khách hàng', icon: Users },
                  { key: 'orders', label: 'Hóa đơn', icon: FileJson },
                  { key: 'expenses', label: 'Chi phí', icon: Database },
                  { key: 'suppliers', label: 'Nhà cung cấp', icon: Truck },
                ].map(({ key, label, icon: Icon }) => (
                  <button
                    key={key}
                    onClick={() => handleExport(key as any)}
                    disabled={exporting === key}
                    className="flex items-center gap-3 p-4 border border-emerald-100 rounded-xl hover:bg-emerald-50/50 transition-colors text-left"
                  >
                    <div className="w-10 h-10 rounded-lg bg-emerald-100 flex items-center justify-center">
                      <Icon className="w-5 h-5 text-emerald-600" />
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-emerald-900">{label}</p>
                      <p className="text-xs text-emerald-600/70">Xuất CSV</p>
                    </div>
                    {exporting === key ? (
                      <Loader2 className="w-5 h-5 text-emerald-600 animate-spin" />
                    ) : (
                      <Download className="w-5 h-5 text-emerald-400" />
                    )}
                  </button>
                ))}
              </div>
            </div>

            <div className="border-t border-emerald-100 pt-6">
              <h3 className="font-semibold text-emerald-900 mb-2">Sao lưu toàn bộ</h3>
              <p className="text-sm text-emerald-600/70 mb-4">Tải xuống tất cả dữ liệu dưới dạng JSON</p>
              
              <button
                onClick={handleExportAll}
                disabled={exporting === 'all'}
                className="w-full sm:w-auto px-6 py-3 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl font-medium transition-colors flex items-center justify-center gap-2"
              >
                {exporting === 'all' ? (
                  <Loader2 className="w-5 h-5 animate-spin" />
                ) : (
                  <Download className="w-5 h-5" />
                )}
                Sao lưu toàn bộ dữ liệu
              </button>
            </div>
          </div>
        )}

        {activeTab === 'appearance' && (
          <div className="bg-white rounded-xl border border-emerald-100 p-6 shadow-sm">
            <div className="max-w-lg space-y-5">
              <div>
                <label className="block text-sm font-medium text-emerald-700 mb-2">Chế độ</label>
                <div className="grid grid-cols-3 gap-2">
                  {['light', 'dark', 'auto'].map((theme) => (
                    <button key={theme} onClick={() => setAppearance({ ...appearance, theme })}
                      className={`px-4 py-2.5 rounded-lg border text-sm font-medium ${
                        appearance.theme === theme
                          ? 'border-emerald-500 bg-emerald-50 text-emerald-700'
                          : 'border-emerald-200 hover:bg-emerald-50/50 text-emerald-600'
                      }`}>
                      {theme === 'light' ? 'Sáng' : theme === 'dark' ? 'Tối' : 'Tự động'}
                    </button>
                  ))}
                </div>
              </div>
              <label className="flex items-center gap-3 p-3 border border-emerald-100 rounded-lg cursor-pointer hover:bg-emerald-50/50">
                <input type="checkbox" checked={appearance.compact}
                  onChange={(e) => setAppearance({ ...appearance, compact: e.target.checked })}
                  className="w-4 h-4 text-emerald-600 rounded border-emerald-300 focus:ring-emerald-500" />
                <div>
                  <p className="font-medium text-emerald-900">Chế độ gọn</p>
                  <p className="text-sm text-emerald-600/70">Giảm khoảng cách giữa các phần tử</p>
                </div>
              </label>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
