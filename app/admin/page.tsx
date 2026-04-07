'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { getPendingPayments, Payment, getUserSubscription, Subscription } from '@/lib/firestore';
import { 
  Users, 
  CreditCard, 
  TrendingUp, 
  Clock,
  CheckCircle,
  XCircle,
  AlertCircle
} from 'lucide-react';
import Link from 'next/link';

interface DashboardStats {
  totalUsers: number;
  proUsers: number;
  pendingPayments: number;
  totalRevenue: number;
}

export default function AdminDashboard() {
  const { user } = useAuth();
  const [stats, setStats] = useState<DashboardStats>({
    totalUsers: 0,
    proUsers: 0,
    pendingPayments: 0,
    totalRevenue: 0,
  });
  const [recentPayments, setRecentPayments] = useState<(Payment & { id: string })[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      // Load pending payments
      const pending = await getPendingPayments();
      setRecentPayments(pending.slice(0, 5));
      
      // TODO: Add functions to get total stats
      // For now, use pending count as estimate
      setStats({
        totalUsers: 0, // Will be loaded from separate function
        proUsers: 0,
        pendingPayments: pending.length,
        totalRevenue: pending.reduce((sum, p) => sum + (p.status === 'verified' ? p.amount : 0), 0),
      });
    } catch (error) {
      console.error('Error loading dashboard:', error);
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
      minimumFractionDigits: 0,
    }).format(amount);
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'verified':
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'rejected':
        return <XCircle className="w-5 h-5 text-red-500" />;
      case 'pending':
        return <Clock className="w-5 h-5 text-yellow-500" />;
      default:
        return <AlertCircle className="w-5 h-5 text-gray-500" />;
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'verified':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      case 'pending':
        return 'Chờ duyệt';
      default:
        return status;
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-sm text-gray-500">
          Xin chào, {user?.email}
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500">Tổng Users</p>
              <p className="text-2xl font-bold text-gray-900">{stats.totalUsers}</p>
            </div>
            <div className="w-12 h-12 bg-blue-50 rounded-lg flex items-center justify-center">
              <Users className="w-6 h-6 text-blue-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500">PRO Users</p>
              <p className="text-2xl font-bold text-gray-900">{stats.proUsers}</p>
            </div>
            <div className="w-12 h-12 bg-primary-50 rounded-lg flex items-center justify-center">
              <CreditCard className="w-6 h-6 text-primary-600" />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500">Chờ Duyệt</p>
              <p className="text-2xl font-bold text-gray-900">{stats.pendingPayments}</p>
            </div>
            <div className="w-12 h-12 bg-yellow-50 rounded-lg flex items-center justify-center">
              <Clock className="w-6 h-6 text-yellow-600" />
            </div>
          </div>
          {stats.pendingPayments > 0 && (
            <Link 
              href="/admin/payments"
              className="mt-3 inline-flex items-center text-sm text-primary-600 hover:text-primary-700"
            >
              Xem chi tiết →
            </Link>
          )}
        </div>

        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500">Doanh Thu</p>
              <p className="text-2xl font-bold text-gray-900">{formatCurrency(stats.totalRevenue)}</p>
            </div>
            <div className="w-12 h-12 bg-green-50 rounded-lg flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-green-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Recent Pending Payments */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">Thanh toán chờ duyệt</h2>
          <Link 
            href="/admin/payments"
            className="text-sm text-primary-600 hover:text-primary-700"
          >
            Xem tất cả
          </Link>
        </div>
        
        {loading ? (
          <div className="p-6 text-center text-gray-500">Đang tải...</div>
        ) : recentPayments.length === 0 ? (
          <div className="p-6 text-center text-gray-500">
            <Clock className="w-12 h-12 text-gray-300 mx-auto mb-3" />
            <p>Không có thanh toán chờ duyệt</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {recentPayments.map((payment) => (
              <div key={payment.id} className="px-6 py-4 flex items-center justify-between hover:bg-gray-50">
                <div className="flex items-center gap-4">
                  {getStatusIcon(payment.status)}
                  <div>
                    <p className="font-medium text-gray-900">
                      {formatCurrency(payment.amount)}
                    </p>
                    <p className="text-sm text-gray-500">
                      {payment.bankCode} • {payment.transferContent}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                    payment.status === 'pending' 
                      ? 'bg-yellow-100 text-yellow-700'
                      : payment.status === 'verified'
                      ? 'bg-green-100 text-green-700'
                      : 'bg-red-100 text-red-700'
                  }`}>
                    {getStatusText(payment.status)}
                  </span>
                  <Link 
                    href={`/admin/payments?id=${payment.id}`}
                    className="text-sm text-primary-600 hover:text-primary-700"
                  >
                    Chi tiết
                  </Link>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Link 
          href="/admin/payments"
          className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow"
        >
          <CreditCard className="w-8 h-8 text-primary-600 mb-3" />
          <h3 className="font-semibold text-gray-900">Quản lý thanh toán</h3>
          <p className="text-sm text-gray-500 mt-1">Duyệt/từ chối yêu cầu thanh toán</p>
        </Link>

        <Link 
          href="/admin/users"
          className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow"
        >
          <Users className="w-8 h-8 text-blue-600 mb-3" />
          <h3 className="font-semibold text-gray-900">Quản lý users</h3>
          <p className="text-sm text-gray-500 mt-1">Xem và chỉnh sửa subscription</p>
        </Link>

        <Link 
          href="/admin/banks"
          className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow"
        >
          <AlertCircle className="w-8 h-8 text-green-600 mb-3" />
          <h3 className="font-semibold text-gray-900">Tài khoản ngân hàng</h3>
          <p className="text-sm text-gray-500 mt-1">Thêm/sửa TK nhận tiền</p>
        </Link>
      </div>
    </div>
  );
}
