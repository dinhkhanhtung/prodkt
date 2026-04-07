'use client';

import { useState } from 'react';
import { useAuth } from '@/components/AuthProvider';
import { doc, updateDoc, getDoc, setDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Shield, CheckCircle, AlertCircle, Loader2 } from 'lucide-react';

// Email được set làm admin
const ADMIN_EMAIL = 'geminipro1year@gmail.com';

export default function AdminSetupPage() {
  const { user, loading } = useAuth();
  const [status, setStatus] = useState<'idle' | 'checking' | 'setting' | 'success' | 'error'>('idle');
  const [message, setMessage] = useState('');

  const setupAdmin = async () => {
    if (!user) {
      setStatus('error');
      setMessage('Bạn cần đăng nhập trước');
      return;
    }

    setStatus('checking');
    
    try {
      // Kiểm tra xem email có khớp không
      if (user.email !== ADMIN_EMAIL) {
        setStatus('error');
        setMessage(`Email ${user.email} không được phép setup admin. Chỉ ${ADMIN_EMAIL} được phép.`);
        return;
      }

      // Kiểm tra user document
      const userRef = doc(db, 'users', user.uid);
      const userDoc = await getDoc(userRef);

      if (!userDoc.exists()) {
        // Tạo user document nếu chưa tồn tại
        await setDoc(userRef, {
          uid: user.uid,
          email: user.email,
          role: 'admin',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        });
      } else {
        // Update role thành admin
        await updateDoc(userRef, {
          role: 'admin',
          updatedAt: new Date().toISOString(),
        });
      }

      setStatus('success');
      setMessage('Đã set quyền admin thành công! Bạn có thể truy cập /admin ngay bây giờ.');
    } catch (error) {
      console.error('Error setting admin:', error);
      setStatus('error');
      setMessage('Có lỗi xảy ra: ' + (error as Error).message);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-8 h-8 text-primary-600 animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-white flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-lg max-w-md w-full p-8">
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <Shield className="w-8 h-8 text-primary-600" />
          </div>
          <h1 className="text-2xl font-bold text-gray-900">Admin Setup</h1>
          <p className="text-gray-600 mt-2">Thiết lập quyền quản trị viên</p>
        </div>

        {!user ? (
          <div className="text-center">
            <AlertCircle className="w-12 h-12 text-yellow-500 mx-auto mb-4" />
            <p className="text-gray-600 mb-4">Bạn cần đăng nhập để setup admin</p>
            <a href="/login" className="btn-primary block w-full">
              Đăng nhập
            </a>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="bg-gray-50 rounded-lg p-4">
              <p className="text-sm text-gray-500">Email đăng nhập:</p>
              <p className="font-medium text-gray-900">{user.email}</p>
            </div>

            <div className="bg-gray-50 rounded-lg p-4">
              <p className="text-sm text-gray-500">Email được phép setup:</p>
              <p className="font-medium text-primary-600">{ADMIN_EMAIL}</p>
            </div>

            {status === 'success' ? (
              <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                <div className="flex items-center gap-2">
                  <CheckCircle className="w-5 h-5 text-green-600" />
                  <p className="text-green-700 font-medium">{message}</p>
                </div>
                <a 
                  href="/admin" 
                  className="mt-4 block w-full text-center btn-primary"
                >
                  Vào Admin Dashboard
                </a>
              </div>
            ) : status === 'error' ? (
              <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                <div className="flex items-center gap-2">
                  <AlertCircle className="w-5 h-5 text-red-600" />
                  <p className="text-red-700">{message}</p>
                </div>
                {message.includes('không được phép') && (
                  <p className="text-sm text-red-600 mt-2">
                    Vui lòng đăng nhập bằng email {ADMIN_EMAIL}
                  </p>
                )}
              </div>
            ) : (
              <button
                onClick={setupAdmin}
                disabled={status === 'checking' || status === 'setting'}
                className="w-full btn-primary py-3 flex items-center justify-center gap-2"
              >
                {(status === 'checking' || status === 'setting') ? (
                  <>
                    <Loader2 className="w-5 h-5 animate-spin" />
                    Đang xử lý...
                  </>
                ) : (
                  <>
                    <Shield className="w-5 h-5" />
                    Set làm Admin
                  </>
                )}
              </button>
            )}

            <p className="text-xs text-gray-500 text-center">
              Chỉ email {ADMIN_EMAIL} mới được phép setup admin.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
