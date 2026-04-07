'use client';

import { useState } from 'react';
import { Search, User, Crown, Calendar, CreditCard } from 'lucide-react';

export default function AdminUsersPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Quản lý người dùng</h1>
        <p className="text-gray-500 mt-1">Xem và quản lý subscription của users</p>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
        <input
          type="text"
          placeholder="Tìm kiếm theo email..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
        />
      </div>

      {/* Placeholder - Sẽ implement khi cần */}
      <div className="bg-white rounded-xl p-12 text-center border border-gray-100">
        <User className="w-12 h-12 text-gray-300 mx-auto mb-3" />
        <p className="text-gray-500">Tính năng quản lý users đang được phát triển</p>
        <p className="text-sm text-gray-400 mt-2">
          Bạn có thể duyệt thanh toán tại trang "Thanh toán" để kích hoạt PRO cho user
        </p>
      </div>
    </div>
  );
}
