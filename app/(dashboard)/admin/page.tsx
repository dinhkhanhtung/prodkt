'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/components/AuthProvider';
import { 
  Users, 
  MessageSquare, 
  Send, 
  CreditCard, 
  Building2,
  Search,
  MoreVertical,
  CheckCircle,
  Clock,
  Crown,
  Shield,
  ChevronRight,
  Loader2
} from 'lucide-react';

const TABS = [
  { id: 'users', label: 'Người dùng', icon: Users },
  { id: 'feedback', label: 'Góp ý', icon: MessageSquare },
  { id: 'notifications', label: 'Gửi thông báo', icon: Send },
  { id: 'payments', label: 'Thanh toán', icon: CreditCard },
  { id: 'banks', label: 'Ngân hàng', icon: Building2 },
];

// Mock data
const FEEDBACK_DATA = [
  { id: 1, type: 'bug', title: 'Báo lỗi', content: 'Vô hiệu hóa chuyển đổi gói với thành viên của 1 gia đình', status: 'done', date: '2024-01-15' },
  { id: 2, type: 'feature', title: 'Đề xuất tính năng', content: 'Chưa đăng nhập điện thoại dễ', status: 'done', date: '2024-01-14' },
  { id: 3, type: 'feature', title: 'Đề xuất tính năng', content: 'Tiền ở ví nếu hết cũng cần có màu đỏ', status: 'done', date: '2024-01-13' },
  { id: 4, type: 'feature', title: 'Đề xuất tính năng', content: 'ok. Ngon rồi đấy', status: 'done', date: '2024-01-12' },
  { id: 5, type: 'bug', title: 'Báo lỗi', content: 'ok', status: 'done', date: '2024-01-11' },
];

const USERS_DATA = [
  { id: 1, name: 'Administrator', email: 'geminipro1year@gmail.com', phone: '0982581222', expiry: 'Vĩnh viễn', status: 'vip', plan: 'VIP' },
  { id: 2, name: 'Long Tuan', email: 'tranthanhg@gmail.com', phone: '0973539959', expiry: '29/10/2026', status: 'active', plan: 'PRO' },
  { id: 3, name: 'Khoa Le', email: 'lekhoa123@gmail.com', phone: '0973539959', expiry: '29/10/2026', status: 'active', plan: 'PRO' },
];

const NOTIFICATION_TEMPLATES = [
  { value: 'general', label: 'Thông báo Chung' },
  { value: 'update', label: 'Cập nhật phiên bản' },
  { value: 'feature', label: 'Tính năng mới' },
  { value: 'maintenance', label: 'Bảo trì hệ thống' },
];

const RECIPIENT_OPTIONS = [
  { value: 'all', label: 'Tất cả thành viên' },
  { value: 'pro', label: 'Người dùng PRO' },
  { value: 'free', label: 'Người dùng Free' },
];

export default function AdminPage() {
  const { user, loading } = useAuth();
  const [activeTab, setActiveTab] = useState('users');
  const [searchQuery, setSearchQuery] = useState('');
  const [showInvitedOnly, setShowInvitedOnly] = useState(false);
  
  // Notification form state
  const [notificationTemplate, setNotificationTemplate] = useState('general');
  const [recipient, setRecipient] = useState('all');
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');

  const handleSendNotification = (e: React.FormEvent) => {
    e.preventDefault();
    alert('Thông báo đã được gửi!');
    setTitle('');
    setContent('');
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'done':
        return <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-emerald-100 text-emerald-700"><CheckCircle className="w-3 h-3 mr-1" />Đã xong</span>;
      case 'pending':
        return <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-amber-100 text-amber-700"><Clock className="w-3 h-3 mr-1" />Đang xử lý</span>;
      case 'vip':
        return <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-orange-100 text-orange-700 border border-orange-200"><Crown className="w-3 h-3 mr-1" />VIP</span>;
      case 'active':
        return <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700"><div className="w-1.5 h-1.5 bg-emerald-500 rounded-full mr-1.5" />Hoạt động</span>;
      default:
        return null;
    }
  };

  if (loading || !user || user.role !== 'admin') {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="w-10 h-10 text-emerald-600 animate-spin" />
          <p className="text-emerald-600/70">Đang kiểm tra quyền truy cập...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header với tabs ngang */}
      <div>
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center">
            <Shield className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-emerald-900">Quản trị hệ thống</h1>
            <p className="text-emerald-600/70 text-sm">{user?.email}</p>
          </div>
        </div>

        {/* Tabs ngang */}
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
                      : 'border-transparent text-emerald-600/60 hover:text-emerald-700 hover:border-emerald-200'
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
      <div className="max-w-5xl">
        {/* Users Tab */}
        {activeTab === 'users' && (
          <div className="space-y-4">
            {/* Filters */}
            <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
              <div className="flex flex-col sm:flex-row sm:items-center gap-4">
                <div className="relative flex-1 max-w-md">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-emerald-400" />
                  <input
                    type="text"
                    placeholder="Tìm kiếm theo tên, email, SĐT..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 border border-emerald-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent text-emerald-900 placeholder-emerald-400/70"
                  />
                </div>
                <label className="flex items-center gap-2 text-sm text-emerald-600 cursor-pointer">
                  <input 
                    type="checkbox" 
                    checked={showInvitedOnly}
                    onChange={(e) => setShowInvitedOnly(e.target.checked)}
                    className="w-4 h-4 text-emerald-600 rounded border-emerald-300 focus:ring-emerald-500"
                  />
                  Hiển thị thành viên được mời
                </label>
              </div>
            </div>

            {/* Users Table */}
            <div className="bg-white rounded-xl border border-emerald-100 overflow-hidden shadow-sm">
              <table className="w-full">
                <thead className="bg-emerald-50/50 border-b border-emerald-100">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-semibold text-emerald-700 uppercase">Người dùng</th>
                    <th className="px-4 py-3 text-left text-xs font-semibold text-emerald-700 uppercase">SĐT</th>
                    <th className="px-4 py-3 text-left text-xs font-semibold text-emerald-700 uppercase">Ngày hết hạn</th>
                    <th className="px-4 py-3 text-left text-xs font-semibold text-emerald-700 uppercase">Trạng thái</th>
                    <th className="px-4 py-3 text-right text-xs font-semibold text-emerald-700 uppercase">Hành động</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-emerald-50">
                  {USERS_DATA.map((u) => (
                    <tr key={u.id} className="hover:bg-emerald-50/30">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-emerald-400 to-teal-500 flex items-center justify-center text-white font-semibold">
                            {u.name.charAt(0)}
                          </div>
                          <div>
                            <p className="font-medium text-emerald-900">{u.name}</p>
                            <p className="text-xs text-emerald-600/70">{u.email}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-sm text-emerald-700">{u.phone}</td>
                      <td className="px-4 py-3 text-sm text-emerald-700">{u.expiry}</td>
                      <td className="px-4 py-3">{getStatusBadge(u.status)}</td>
                      <td className="px-4 py-3 text-right">
                        <button className="p-1.5 text-emerald-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg">
                          <MoreVertical className="w-5 h-5" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Feedback Tab */}
        {activeTab === 'feedback' && (
          <div className="space-y-4">
            <div className="bg-white rounded-xl border border-emerald-100 p-4 shadow-sm">
              <h2 className="text-lg font-semibold text-emerald-900 mb-4">Quản lý Góp ý ({FEEDBACK_DATA.length})</h2>
              <div className="space-y-3">
                {FEEDBACK_DATA.map((item) => (
                  <div key={item.id} className="flex items-start justify-between p-4 bg-emerald-50/30 rounded-lg border border-emerald-100">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        {getStatusBadge(item.status)}
                        <span className="text-sm font-medium text-emerald-900">{item.title}</span>
                      </div>
                      <p className="text-sm text-emerald-700/70 italic">"{item.content}"</p>
                    </div>
                    <div className="flex items-center gap-2">
                      <select className="text-sm border border-emerald-200 rounded-lg px-3 py-1.5 bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500 text-emerald-900">
                        <option>Đã xong</option>
                        <option>Đang xử lý</option>
                        <option>Chờ xem xét</option>
                      </select>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Notifications Tab */}
        {activeTab === 'notifications' && (
          <div className="max-w-2xl">
            <div className="bg-white rounded-xl border border-emerald-100 p-6 shadow-sm">
              <h2 className="text-lg font-semibold text-emerald-900 mb-6">Gửi thông báo cho thành viên</h2>
              <form onSubmit={handleSendNotification} className="space-y-5">
                <div>
                  <label className="block text-sm font-medium text-emerald-700 mb-1.5">Chọn mẫu thông báo</label>
                  <select
                    value={notificationTemplate}
                    onChange={(e) => setNotificationTemplate(e.target.value)}
                    className="w-full border border-emerald-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent bg-white text-emerald-900"
                  >
                    {NOTIFICATION_TEMPLATES.map((template) => (
                      <option key={template.value} value={template.value}>{template.label}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-emerald-700 mb-1.5">Gửi đến</label>
                  <select
                    value={recipient}
                    onChange={(e) => setRecipient(e.target.value)}
                    className="w-full border border-emerald-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent bg-white text-emerald-900"
                  >
                    {RECIPIENT_OPTIONS.map((option) => (
                      <option key={option.value} value={option.value}>{option.label}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-emerald-700 mb-1.5">Tiêu đề</label>
                  <input
                    type="text"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    className="w-full border border-emerald-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent text-emerald-900 placeholder-emerald-400"
                    placeholder="Nhập tiêu đề thông báo"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-emerald-700 mb-1.5">Nội dung</label>
                  <textarea
                    value={content}
                    onChange={(e) => setContent(e.target.value)}
                    rows={6}
                    className="w-full border border-emerald-200 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent resize-none text-emerald-900 placeholder-emerald-400"
                    placeholder="Nhập nội dung thông báo..."
                  />
                </div>

                <div className="flex justify-end pt-2">
                  <button
                    type="submit"
                    className="px-6 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-medium rounded-lg transition-colors flex items-center gap-2 shadow-lg shadow-emerald-500/25"
                  >
                    <Send className="w-4 h-4" />
                    Gửi thông báo
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Payments Tab - Placeholder */}
        {activeTab === 'payments' && (
          <div className="bg-white rounded-xl border border-emerald-100 p-12 text-center shadow-sm">
            <CreditCard className="w-12 h-12 text-emerald-300 mx-auto mb-4" />
            <p className="text-emerald-600">Quản lý thanh toán</p>
            <Link href="/admin/payments" className="mt-4 inline-flex items-center gap-2 text-emerald-600 hover:text-emerald-700 hover:underline">
              Xem chi tiết <ChevronRight className="w-4 h-4" />
            </Link>
          </div>
        )}

        {/* Banks Tab - Placeholder */}
        {activeTab === 'banks' && (
          <div className="bg-white rounded-xl border border-emerald-100 p-12 text-center shadow-sm">
            <Building2 className="w-12 h-12 text-emerald-300 mx-auto mb-4" />
            <p className="text-emerald-600">Quản lý ngân hàng</p>
            <Link href="/admin/banks" className="mt-4 inline-flex items-center gap-2 text-emerald-600 hover:text-emerald-700 hover:underline">
              Xem chi tiết <ChevronRight className="w-4 h-4" />
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}
