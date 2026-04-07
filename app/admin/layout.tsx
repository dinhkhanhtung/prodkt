'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/components/AuthProvider';
import { 
  LayoutDashboard, 
  CreditCard, 
  Users, 
  Building2, 
  BarChart3,
  LogOut,
  Menu,
  X,
  Shield,
  ChevronRight
} from 'lucide-react';
import { useState } from 'react';

const adminNavItems = [
  { href: '/admin', label: 'Tổng quan', icon: LayoutDashboard, description: 'Dashboard & thống kê' },
  { href: '/admin/payments', label: 'Thanh toán', icon: CreditCard, description: 'Duyệt yêu cầu CK' },
  { href: '/admin/users', label: 'Người dùng', icon: Users, description: 'Quản lý tài khoản' },
  { href: '/admin/banks', label: 'Ngân hàng', icon: Building2, description: 'TK nhận tiền' },
  { href: '/admin/revenue', label: 'Doanh thu', icon: BarChart3, description: 'Báo cáo tài chính' },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const { user, logout } = useAuth();
  const pathname = usePathname();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  return (
    <div className="min-h-screen bg-slate-50/50">
      {/* Desktop Sidebar - Glassmorphism style */}
      <aside className="hidden lg:fixed lg:inset-y-0 lg:left-0 lg:z-50 lg:w-72 lg:bg-white/80 lg:backdrop-blur-xl lg:border-r lg:border-slate-200/60 lg:flex lg:flex-col lg:shadow-xl lg:shadow-slate-200/20">
        {/* Logo */}
        <div className="h-20 flex items-center px-6 border-b border-slate-100">
          <div className="w-10 h-10 bg-gradient-to-br from-violet-600 to-indigo-600 rounded-xl flex items-center justify-center shadow-lg shadow-violet-600/25">
            <Shield className="w-5 h-5 text-white" />
          </div>
          <div className="ml-3">
            <span className="text-lg font-bold bg-gradient-to-r from-slate-900 to-slate-600 bg-clip-text text-transparent">
              ProDKT
            </span>
            <p className="text-xs text-slate-500 font-medium">Admin Portal</p>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
          <p className="px-4 text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">
            Menu chính
          </p>
          {adminNavItems.map((item) => {
            const isActive = pathname === item.href || pathname.startsWith(`${item.href}/`);
            const Icon = item.icon;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`group flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 ${
                  isActive
                    ? 'bg-gradient-to-r from-violet-50 to-indigo-50 text-violet-700 shadow-sm shadow-violet-100'
                    : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                }`}
              >
                <div className={`w-10 h-10 rounded-lg flex items-center justify-center transition-all ${
                  isActive 
                    ? 'bg-gradient-to-br from-violet-600 to-indigo-600 text-white shadow-md shadow-violet-600/25' 
                    : 'bg-slate-100 text-slate-500 group-hover:bg-white group-hover:shadow-sm'
                }`}>
                  <Icon className="w-5 h-5" />
                </div>
                <div className="flex-1">
                  <p className="font-medium">{item.label}</p>
                  <p className={`text-xs ${isActive ? 'text-violet-500' : 'text-slate-400'}`}>
                    {item.description}
                  </p>
                </div>
                {isActive && <ChevronRight className="w-4 h-4 text-violet-400" />}
              </Link>
            );
          })}
        </nav>

        {/* User Info & Logout */}
        <div className="p-4 m-4 bg-gradient-to-br from-slate-50 to-slate-100/50 rounded-2xl border border-slate-100">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 bg-gradient-to-br from-violet-500 to-indigo-500 rounded-full flex items-center justify-center shadow-lg shadow-violet-500/25">
              <span className="text-white font-bold text-lg">
                {user?.email?.charAt(0).toUpperCase() || 'A'}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-slate-900 truncate">
                {user?.email || 'Admin'}
              </p>
              <div className="flex items-center gap-1">
                <span className="w-2 h-2 bg-green-500 rounded-full"></span>
                <p className="text-xs text-slate-500">Super Admin</p>
              </div>
            </div>
          </div>
          <button
            onClick={logout}
            className="flex items-center justify-center gap-2 w-full px-4 py-2.5 text-sm font-medium text-red-600 bg-red-50 hover:bg-red-100 rounded-xl transition-colors"
          >
            <LogOut className="w-4 h-4" />
            Đăng xuất
          </button>
        </div>
      </aside>

      {/* Mobile Header */}
      <header className="lg:hidden fixed top-0 left-0 right-0 z-50 bg-white/80 backdrop-blur-xl border-b border-slate-200/60">
        <div className="h-16 flex items-center justify-between px-4">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 bg-gradient-to-br from-violet-600 to-indigo-600 rounded-lg flex items-center justify-center">
              <Shield className="w-4 h-4 text-white" />
            </div>
            <div>
              <span className="font-bold text-slate-900">ProDKT</span>
              <span className="text-xs text-slate-500 block">Admin</span>
            </div>
          </div>
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="p-2 text-slate-600 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition-colors"
          >
            {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {/* Mobile Menu */}
        {mobileMenuOpen && (
          <div className="border-t border-slate-200/60 bg-white/95 backdrop-blur-xl">
            <nav className="px-4 py-4 space-y-1">
              {adminNavItems.map((item) => {
                const isActive = pathname === item.href || pathname.startsWith(`${item.href}/`);
                const Icon = item.icon;
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={() => setMobileMenuOpen(false)}
                    className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors ${
                      isActive
                        ? 'bg-violet-50 text-violet-700'
                        : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                    }`}
                  >
                    <Icon className="w-5 h-5" />
                    <div>
                      <p>{item.label}</p>
                      <p className="text-xs text-slate-400">{item.description}</p>
                    </div>
                  </Link>
                );
              })}
              <hr className="my-3 border-slate-100" />
              <button
                onClick={logout}
                className="flex items-center gap-3 w-full px-4 py-3 text-sm font-medium text-red-600 hover:bg-red-50 rounded-xl transition-colors"
              >
                <LogOut className="w-5 h-5" />
                Đăng xuất
              </button>
            </nav>
          </div>
        )}
      </header>

      {/* Main Content */}
      <main className="lg:ml-72 min-h-screen pt-16 lg:pt-0">
        <div className="p-4 lg:p-8 max-w-7xl">
          {children}
        </div>
      </main>
    </div>
  );
}
