'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from './AuthProvider';
import { getNotifications, getUnreadCount, markNotificationAsRead, markAllAsRead, deleteNotification, Notification } from '@/lib/firestore';
import { 
  LayoutDashboard, 
  Package, 
  Users, 
  Truck, 
  ShoppingCart, 
  Receipt, 
  LogOut, 
  Menu, 
  X, 
  Shield, 
  Settings, 
  RefreshCw, 
  Moon,
  Check,
  Trash2, 
  Bell, 
  Plus, 
  ChevronDown, 
  Wallet, 
  BarChart3, 
  Settings2,
  MessageCircle,
  Sparkles,
  Repeat,
  HandCoins
} from 'lucide-react';
import { useState } from 'react';

const navigation = [
  { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
  { name: 'Sản phẩm', href: '/products', icon: Package },
  { name: 'Khách hàng', href: '/customers', icon: Users },
  { name: 'Nhà cung cấp', href: '/suppliers', icon: Truck },
  { name: 'Bán hàng POS', href: '/pos', icon: ShoppingCart },
  { name: 'Hóa đơn', href: '/orders', icon: Receipt },
  { name: 'Cài đặt', href: '/settings', icon: Settings },
];

export function DashboardLayout({ children }: { children: React.ReactNode }) {
  const { user, loading, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [userDropdownOpen, setUserDropdownOpen] = useState(false);
  const [notifOpen, setNotifOpen] = useState(false);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    if (!loading && !user) {
      router.push('/login');
    }
  }, [user, loading, router]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  if (!user) {
    return null;
  }

  // Load notifications
  useEffect(() => {
    if (user?.uid) {
      loadNotifications();
      // Poll for new notifications every 30 seconds
      const interval = setInterval(loadNotifications, 30000);
      return () => clearInterval(interval);
    }
  }, [user?.uid]);

  const loadNotifications = async () => {
    if (!user?.uid) return;
    try {
      const [notifs, count] = await Promise.all([
        getNotifications(user.uid, false),
        getUnreadCount(user.uid),
      ]);
      setNotifications(notifs);
      setUnreadCount(count);
    } catch (error) {
      console.error('Error loading notifications:', error);
    }
  };

  const handleMarkAsRead = async (id: string) => {
    if (!user?.uid) return;
    try {
      await markNotificationAsRead(user.uid, id);
      loadNotifications();
    } catch (error) {
      console.error('Error marking notification as read:', error);
    }
  };

  const handleMarkAllAsRead = async () => {
    if (!user?.uid) return;
    try {
      await markAllAsRead(user.uid);
      loadNotifications();
    } catch (error) {
      console.error('Error marking all as read:', error);
    }
  };

  const handleDeleteNotification = async (id: string) => {
    if (!user?.uid) return;
    try {
      await deleteNotification(user.uid, id);
      loadNotifications();
    } catch (error) {
      console.error('Error deleting notification:', error);
    }
  };

  const handleLogout = async () => {
    await logout();
    router.push('/');
  };

  const isAdmin = user?.role === 'admin';

  const navItems = [
    { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
    { name: 'Sản phẩm', href: '/products', icon: Package },
    { name: 'Khách hàng', href: '/customers', icon: Users },
    { name: 'Nhà cung cấp', href: '/suppliers', icon: Truck },
    { name: 'Bán hàng POS', href: '/pos', icon: ShoppingCart, highlight: true },
    { name: 'Hóa đơn', href: '/orders', icon: Receipt },
    { name: 'Chi phí', href: '/expenses', icon: Wallet },
    { name: 'Báo cáo', href: '/reports', icon: BarChart3 },
    { name: 'AI Phân tích', href: '/ai-analysis', icon: Sparkles },
    { name: 'Chat', href: '/chat', icon: MessageCircle },
    { name: 'Tài chính cá nhân', href: '/personal-finance', icon: Wallet },
    { name: 'Quản lý nợ', href: '/debts', icon: HandCoins },
    { name: 'Giao dịch định kỳ', href: '/recurring', icon: Repeat },
    { name: 'Trường tùy chỉnh', href: '/custom-fields', icon: Settings2 },
    { name: 'Cài đặt', href: '/settings', icon: Settings },
    ...(isAdmin ? [{ name: 'Quản trị', href: '/admin', icon: Shield }] : []),
  ];

  return (
    <div className="min-h-screen bg-emerald-50/50">
      {/* Mobile sidebar */}
      {sidebarOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div
            className="fixed inset-0 bg-emerald-950/50"
            onClick={() => setSidebarOpen(false)}
          />
          <div className="fixed inset-y-0 left-0 w-64 bg-gradient-to-b from-emerald-900 to-teal-900 shadow-xl">
            <SidebarContent
              pathname={pathname}
              onClose={() => setSidebarOpen(false)}
              user={user}
              navItems={navItems}
            />
          </div>
        </div>
      )}

      {/* Desktop sidebar */}
      <div className="hidden lg:fixed lg:inset-y-0 lg:flex lg:w-64 lg:flex-col">
        <div className="flex flex-col flex-grow bg-gradient-to-b from-emerald-900 via-emerald-800 to-teal-900">
          <SidebarContent pathname={pathname} user={user} navItems={navItems} />
        </div>
      </div>

      {/* Main content */}
      <div className="lg:pl-64">
        {/* Header */}
        <header className="bg-white/80 backdrop-blur-md border-b border-emerald-100 sticky top-0 z-10">
          <div className="flex items-center justify-between h-16 px-4 sm:px-6 lg:px-8">
            <button
              onClick={() => setSidebarOpen(true)}
              className="lg:hidden p-2 rounded-md text-emerald-600 hover:bg-emerald-50"
            >
              <Menu className="w-6 h-6" />
            </button>

            {/* Right side icons */}
            <div className="flex items-center gap-2 ml-auto">
              {/* Refresh */}
              <button 
                onClick={() => window.location.reload()}
                className="p-2 rounded-full text-emerald-600 hover:bg-emerald-50 transition-colors"
                title="Làm mới"
              >
                <RefreshCw className="w-5 h-5" />
              </button>
              
              {/* Dark mode toggle */}
              <button 
                className="p-2 rounded-full text-emerald-600 hover:bg-emerald-50 transition-colors"
                title="Chế độ tối"
              >
                <Moon className="w-5 h-5" />
              </button>
              
              {/* Notifications */}
              <div className="relative">
                <button 
                  onClick={() => setNotifOpen(!notifOpen)}
                  className="p-2 rounded-full text-emerald-600 hover:bg-emerald-50 transition-colors relative"
                  title="Thông báo"
                >
                  <Bell className="w-5 h-5" />
                  {unreadCount > 0 && (
                    <span className="absolute top-1 right-1 w-4 h-4 bg-orange-500 rounded-full text-[10px] text-white flex items-center justify-center font-semibold">
                      {unreadCount > 9 ? '9+' : unreadCount}
                    </span>
                  )}
                </button>

                {notifOpen && (
                  <div className="absolute right-0 mt-2 w-80 bg-white rounded-xl shadow-xl border border-emerald-100 py-2 z-50 max-h-96 overflow-y-auto">
                    <div className="flex items-center justify-between px-4 py-2 border-b border-emerald-50">
                      <p className="font-semibold text-emerald-900">Thông báo</p>
                      {unreadCount > 0 && (
                        <button 
                          onClick={handleMarkAllAsRead}
                          className="text-xs text-emerald-600 hover:text-emerald-700"
                        >
                          Đọc tất cả
                        </button>
                      )}
                    </div>
                    {notifications.length === 0 ? (
                      <div className="p-4 text-center">
                        <p className="text-sm text-emerald-600">Không có thông báo</p>
                      </div>
                    ) : (
                      notifications.slice(0, 10).map((notif) => (
                        <div 
                          key={notif.id} 
                          className={`px-4 py-3 border-b border-emerald-50 hover:bg-emerald-50/50 ${!notif.read ? 'bg-emerald-50/30' : ''}`}
                        >
                          <div className="flex items-start gap-2">
                            <div className={`w-2 h-2 rounded-full mt-2 ${!notif.read ? 'bg-emerald-500' : 'bg-emerald-200'}`} />
                            <div className="flex-1 min-w-0">
                              <p className="text-sm font-medium text-emerald-900">{notif.title}</p>
                              <p className="text-xs text-emerald-600/70 truncate">{notif.message}</p>
                              <p className="text-[10px] text-emerald-400 mt-1">
                                {new Date(notif.createdAt).toLocaleString('vi-VN')}
                              </p>
                            </div>
                            <div className="flex gap-1">
                              {!notif.read && (
                                <button 
                                  onClick={() => handleMarkAsRead(notif.id)}
                                  className="p-1 text-emerald-600 hover:bg-emerald-100 rounded"
                                  title="Đánh dấu đã đọc"
                                >
                                  <Check className="w-3 h-3" />
                                </button>
                              )}
                              <button 
                                onClick={() => handleDeleteNotification(notif.id)}
                                className="p-1 text-red-600 hover:bg-red-50 rounded"
                                title="Xóa"
                              >
                                <Trash2 className="w-3 h-3" />
                              </button>
                            </div>
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                )}
              </div>

              {/* User dropdown */}
              <div className="relative ml-2">
                <button
                  onClick={() => setUserDropdownOpen(!userDropdownOpen)}
                  className="flex items-center gap-2 p-1 pr-3 rounded-full hover:bg-emerald-50 transition-colors border border-emerald-100"
                >
                  <div className="w-8 h-8 rounded-full bg-gradient-to-br from-emerald-500 to-teal-500 text-white flex items-center justify-center font-semibold text-sm">
                    {user?.email?.charAt(0).toUpperCase() || 'U'}
                  </div>
                </button>

                {userDropdownOpen && (
                  <div className="absolute right-0 mt-2 w-56 bg-white rounded-xl shadow-xl border border-emerald-100 py-2 z-50">
                    <div className="px-4 py-3 border-b border-emerald-50">
                      <p className="font-semibold text-emerald-900">Administrator</p>
                      <p className="text-sm text-emerald-600">{user?.email}</p>
                    </div>
                    <button
                      onClick={async () => {
                        await logout();
                        router.push('/');
                      }}
                      className="w-full flex items-center gap-2 px-4 py-2.5 text-red-600 hover:bg-red-50 transition-colors"
                    >
                      <LogOut className="w-4 h-4" />
                      Đăng xuất
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
        </header>

        {/* Page content */}
        <main className="p-4 sm:p-6 lg:p-8 relative">
          {children}
          
          {/* FAB - Quick add */}
          <Link
            href="/products"
            className="fixed bottom-6 right-6 w-14 h-14 bg-orange-500 hover:bg-orange-600 text-white rounded-full shadow-lg shadow-orange-500/30 transition-all hover:scale-110 flex items-center justify-center z-40"
          >
            <Plus className="w-7 h-7" />
          </Link>
        </main>
      </div>
    </div>
  );
}

function SidebarContent({
  pathname,
  onClose,
  user,
  navItems,
}: {
  pathname: string;
  onClose?: () => void;
  user?: { email?: string | null; role?: string } | null;
  navItems: any[];
}) {
  const isAdmin = user?.role === 'admin';

  return (
    <>
      <div className="flex items-center justify-between h-16 px-4 border-b border-emerald-700/50">
        <Link href="/dashboard" className="flex items-center gap-2">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-400 to-teal-500 flex items-center justify-center">
            <Package className="w-6 h-6 text-white" />
          </div>
          <span className="text-xl font-bold text-white">ProDKT</span>
        </Link>
        {onClose && (
          <button
            onClick={onClose}
            className="lg:hidden p-2 rounded-md text-emerald-200 hover:bg-emerald-800"
          >
            <X className="w-5 h-5" />
          </button>
        )}
      </div>

      <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        {navItems.map((item) => {
          const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
          return (
            <Link
              key={item.name}
              href={item.href}
              onClick={onClose}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all ${
                isActive
                  ? 'bg-gradient-to-r from-emerald-500 to-teal-500 text-white shadow-lg shadow-emerald-500/25'
                  : item.highlight
                  ? 'bg-orange-500/20 text-orange-200 border border-orange-500/30 hover:bg-orange-500/30'
                  : 'text-emerald-100 hover:bg-emerald-800/50 hover:text-white'
              }`}
            >
              <item.icon className={`w-5 h-5 ${item.highlight && !isActive ? 'text-orange-300' : ''}`} />
              {item.name}
            </Link>
          );
        })}
      </nav>

      {/* Admin Badge */}
      {isAdmin && (
        <div className="px-4 py-3 mx-3 mb-3 bg-gradient-to-r from-emerald-500/20 to-emerald-500/20 rounded-xl border border-emerald-400/30">
          <div className="flex items-center gap-2">
            <Shield className="w-5 h-5 text-emerald-300" />
            <div>
              <p className="text-sm font-semibold text-white">Quản Trị Viên</p>
              <p className="text-xs text-emerald-200/70">Toàn quyền hệ thống</p>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
