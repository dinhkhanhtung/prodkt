'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '@/components/AuthProvider';
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
  Bell,
  Plus,
  ChevronDown,
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

  const handleLogout = async () => {
    await logout();
    router.push('/');
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Mobile sidebar */}
      {sidebarOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div
            className="fixed inset-0 bg-gray-900/50"
            onClick={() => setSidebarOpen(false)}
          />
          <div className="fixed inset-y-0 left-0 w-64 bg-white shadow-lg">
            <SidebarContent
              pathname={pathname}
              onClose={() => setSidebarOpen(false)}
              user={user}
            />
          </div>
        </div>
      )}

      {/* Desktop sidebar */}
      <div className="hidden lg:fixed lg:inset-y-0 lg:flex lg:w-64 lg:flex-col">
        <div className="flex flex-col flex-grow bg-white border-r border-gray-200">
          <SidebarContent pathname={pathname} user={user} />
        </div>
      </div>

      {/* Main content */}
      <div className="lg:pl-64">
        {/* Header */}
        <header className="bg-white border-b border-gray-200 sticky top-0 z-10">
          <div className="flex items-center justify-between h-16 px-4 sm:px-6 lg:px-8">
            <button
              onClick={() => setSidebarOpen(true)}
              className="lg:hidden p-2 rounded-md text-gray-600 hover:bg-gray-100"
            >
              <Menu className="w-6 h-6" />
            </button>

            {/* Right side icons */}
            <div className="flex items-center gap-2 ml-auto">
              {/* Refresh */}
              <button 
                onClick={() => window.location.reload()}
                className="p-2 rounded-full text-gray-500 hover:bg-gray-100 transition-colors"
                title="Làm mới"
              >
                <RefreshCw className="w-5 h-5" />
              </button>
              
              {/* Dark mode toggle */}
              <button 
                className="p-2 rounded-full text-gray-500 hover:bg-gray-100 transition-colors"
                title="Chế độ tối"
              >
                <Moon className="w-5 h-5" />
              </button>
              
              {/* Notifications */}
              <button 
                className="p-2 rounded-full text-gray-500 hover:bg-gray-100 transition-colors relative"
                title="Thông báo"
              >
                <Bell className="w-5 h-5" />
                <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
              </button>

              {/* User dropdown */}
              <div className="relative ml-2">
                <button
                  onClick={() => setUserDropdownOpen(!userDropdownOpen)}
                  className="flex items-center gap-2 p-1 pr-3 rounded-full hover:bg-gray-100 transition-colors"
                >
                  <div className="w-8 h-8 rounded-full bg-emerald-500 text-white flex items-center justify-center font-semibold text-sm">
                    {user?.email?.charAt(0).toUpperCase() || 'U'}
                  </div>
                </button>

                {userDropdownOpen && (
                  <div className="absolute right-0 mt-2 w-56 bg-white rounded-xl shadow-lg border border-gray-100 py-2 z-50">
                    <div className="px-4 py-3 border-b border-gray-100">
                      <p className="font-semibold text-gray-900">Administrator</p>
                      <p className="text-sm text-gray-500">{user?.email}</p>
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
          
          {/* FAB for quick actions */}
          <div className="fixed bottom-6 right-6 flex flex-col gap-3 z-40">
            <Link
              href="/pos"
              className="flex items-center gap-2 px-4 py-3 bg-emerald-500 hover:bg-emerald-600 text-white rounded-full shadow-lg shadow-emerald-500/30 transition-all hover:scale-105"
            >
              <ShoppingCart className="w-5 h-5" />
              <span className="font-medium">Bán hàng</span>
            </Link>
            <Link
              href="/products"
              className="flex items-center gap-2 px-4 py-3 bg-violet-500 hover:bg-violet-600 text-white rounded-full shadow-lg shadow-violet-500/30 transition-all hover:scale-105"
            >
              <Plus className="w-5 h-5" />
              <span className="font-medium">Nhập hàng</span>
            </Link>
          </div>
        </main>
      </div>
    </div>
  );
}

function SidebarContent({
  pathname,
  onClose,
  user,
}: {
  pathname: string;
  onClose?: () => void;
  user?: { email?: string | null; role?: string } | null;
}) {
  const isAdmin = user?.role === 'admin';

  return (
    <>
      <div className="flex items-center justify-between h-16 px-4 border-b border-gray-200">
        <Link href="/dashboard" className="flex items-center gap-2">
          <Package className="w-8 h-8 text-primary-600" />
          <span className="text-xl font-bold text-gray-900">ProDKT</span>
        </Link>
        {onClose && (
          <button
            onClick={onClose}
            className="lg:hidden p-2 rounded-md text-gray-600 hover:bg-gray-100"
          >
            <X className="w-5 h-5" />
          </button>
        )}
      </div>

      <nav className="flex-1 px-4 py-4 space-y-1 overflow-y-auto">
        {navigation.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.name}
              href={item.href}
              onClick={onClose}
              className={`sidebar-link ${isActive ? 'active' : ''}`}
            >
              <item.icon className="w-5 h-5" />
              {item.name}
            </Link>
          );
        })}

        {/* Admin Section */}
        {isAdmin && (
          <div className="mt-6 pt-4 border-t border-gray-200">
            <p className="px-3 text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">
              Quản trị
            </p>
            <Link
              href="/admin"
              onClick={onClose}
              className={`sidebar-link ${pathname === '/admin' || pathname.startsWith('/admin/') ? 'active' : ''}`}
            >
              <Shield className="w-5 h-5" />
              Bảng điều khiển
            </Link>
          </div>
        )}
      </nav>

      {/* Admin Badge */}
      {isAdmin && (
        <div className="px-4 py-3 mx-4 mb-3 bg-gradient-to-r from-violet-50 to-indigo-50 rounded-xl border border-violet-100">
          <div className="flex items-center gap-2">
            <Shield className="w-4 h-4 text-violet-600" />
            <div>
              <p className="text-xs font-semibold text-violet-900">Quản Trị Viên</p>
              <p className="text-xs text-violet-600">Quyền truy cập hệ thống</p>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
