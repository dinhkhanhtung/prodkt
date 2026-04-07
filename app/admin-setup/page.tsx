'use client';

import { useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { doc, updateDoc, getDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Shield, CheckCircle, AlertCircle, Loader2, Crown } from 'lucide-react';
import Link from 'next/link';

export default function AdminSetupPage() {
  const { user, loading } = useAuth();
  const [status, setStatus] = useState<'idle' | 'setting' | 'success' | 'error'>('idle');
  const [message, setMessage] = useState('');

  const setupAdmin = async () => {
    if (!user) {
      setStatus('error');
      setMessage('Bạn cần đăng nhập trước');
      return;
    }

    // Only allow geminipro1year@gmail.com
    if (user.email !== 'geminipro1year@gmail.com') {
      setStatus('error');
      setMessage(`Email ${user.email} không được phép setup admin.`);
      return;
    }

    setStatus('setting');
    
    try {
      const userRef = doc(db, 'users', user.uid);
      
      // Check if user exists
      const userDoc = await getDoc(userRef);
      
      if (!userDoc.exists()) {
        setStatus('error');
        setMessage('User document chưa tồn tại. Hãy vào Dashboard trước để tạo.');
        return;
      }

      // Update role to admin
      await updateDoc(userRef, {
        role: 'admin',
        updatedAt: new Date().toISOString(),
      });

      setStatus('success');
      setMessage('✅ Đã set quyền admin thành công!');
    } catch (error: any) {
      console.error('Error setting admin:', error);
      setStatus('error');
      setMessage('Lỗi: ' + (error.message || 'Không thể set admin'));
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 flex items-center justify-center">
        <Loader2 className="w-10 h-10 text-violet-600 animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-violet-50 via-white to-indigo-50 flex items-center justify-center p-4">
      <div className="bg-white/80 backdrop-blur-xl rounded-3xl shadow-2xl shadow-violet-200/50 max-w-md w-full p-8 border border-white/50">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="w-20 h-20 bg-gradient-to-br from-violet-500 to-indigo-600 rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-lg shadow-violet-500/30">
            <Crown className="w-10 h-10 text-white" />
          </div>
          <h1 className="text-2xl font-bold bg-gradient-to-r from-violet-600 to-indigo-600 bg-clip-text text-transparent">
            Thiết lập Admin
          </h1>
          <p className="text-slate-500 mt-2">
            Kích hoạt quyền quản trị viên
          </p>
        </div>

        {!user ? (
          <div className="text-center">
            <div className="w-16 h-16 bg-amber-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
              <AlertCircle className="w-8 h-8 text-amber-600" />
            </div>
            <p className="text-slate-600 mb-4">Bạn cần đăng nhập để tiếp tục</p>
            <Link 
              href="/login" 
              className="block w-full py-3 bg-gradient-to-r from-violet-600 to-indigo-600 text-white rounded-xl font-semibold hover:opacity-90 transition-opacity"
            >
              Đăng nhập
            </Link>
          </div>
        ) : (
          <div className="space-y-4">
            {/* Current User Info */}
            <div className="bg-slate-50 rounded-xl p-4 border border-slate-100">
              <p className="text-xs text-slate-500 uppercase font-medium mb-1">Email đăng nhập</p>
              <p className="font-semibold text-slate-900">{user.email}</p>
            </div>

            {/* Status Messages */}
            {status === 'success' ? (
              <div className="bg-emerald-50 border border-emerald-100 rounded-xl p-4">
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-6 h-6 text-emerald-600 flex-shrink-0" />
                  <div>
                    <p className="text-emerald-800 font-medium">{message}</p>
                    <p className="text-emerald-600 text-sm mt-1">
                      Bạn có thể vào Admin Dashboard ngay bây giờ
                    </p>
                  </div>
                </div>
                <Link 
                  href="/admin" 
                  className="mt-4 block w-full py-3 bg-gradient-to-r from-emerald-500 to-teal-500 text-white rounded-xl font-semibold text-center hover:opacity-90 transition-opacity shadow-lg shadow-emerald-500/25"
                >
                  Vào Admin Dashboard →
                </Link>
              </div>
            ) : status === 'error' ? (
              <div className="bg-red-50 border border-red-100 rounded-xl p-4">
                <div className="flex items-start gap-3">
                  <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-red-800 font-medium">{message}</p>
                    {message.includes('chưa tồn tại') && (
                      <Link 
                        href="/dashboard"
                        className="text-red-600 text-sm underline mt-1 inline-block"
                      >
                        Nhấn vào đây để vào Dashboard →
                      </Link>
                    )}
                  </div>
                </div>
              </div>
            ) : (
              <button
                onClick={setupAdmin}
                disabled={status === 'setting'}
                className="w-full py-4 bg-gradient-to-r from-violet-600 to-indigo-600 text-white rounded-xl font-semibold hover:opacity-90 transition-all disabled:opacity-50 shadow-lg shadow-violet-600/25 flex items-center justify-center gap-2"
              >
                {status === 'setting' ? (
                  <>
                    <Loader2 className="w-5 h-5 animate-spin" />
                    Đang xử lý...
                  </>
                ) : (
                  <>
                    <Shield className="w-5 h-5" />
                    Kích hoạt Admin
                  </>
                )}
              </button>
            )}

            {/* Note */}
            <p className="text-xs text-slate-400 text-center">
              Chỉ email <span className="font-medium text-violet-600">geminipro1year@gmail.com</span> được phép setup admin.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
