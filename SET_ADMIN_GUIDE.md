# Cách set Admin cho geminipro1year@gmail.com

## ⚡ Cách 1: Dùng Browser Console (Nhanh nhất)

1. Mở app: https://prodkt-eight.vercel.app
2. Đăng nhập bằng `geminipro1year@gmail.com`
3. Mở DevTools (F12) → Console
4. Copy và paste đoạn code sau:

```javascript
// Set admin cho user hiện tại
const setAdmin = async () => {
  const { doc, updateDoc, getFirestore } = await import('firebase/firestore');
  const { getAuth } = await import('firebase/auth');
  
  const auth = getAuth();
  const db = getFirestore();
  
  if (!auth.currentUser) {
    console.error('❌ Chưa đăng nhập!');
    return;
  }
  
  const userRef = doc(db, 'users', auth.currentUser.uid);
  await updateDoc(userRef, {
    role: 'admin',
    updatedAt: new Date().toISOString()
  });
  
  console.log('✅ Đã set admin thành công cho:', auth.currentUser.email);
  console.log('🔄 Refresh trang để vào /admin');
};

setAdmin();
```

5. Nhấn Enter, đợi 2-3 giây
6. Refresh trang và vào `/admin`

---

## 🔧 Cách 2: Firebase Console (Manual)

1. Vào [Firebase Console](https://console.firebase.google.com/)
2. Chọn project → Firestore Database
3. Collection `users` → Tìm document của `geminipro1year@gmail.com`
4. Click "Add field":
   - Field: `role`
   - Type: `string`
   - Value: `admin`
5. Save

---

## 📝 Cách 3: Dùng Firebase CLI

```bash
# Install firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Set admin (thay USER_ID bằng UID thật)
firebase firestore:documents:set users/USER_ID --data '{"role": "admin"}'
```

---

## ✅ Kiểm tra

Sau khi set admin, vào: https://prodkt-eight.vercel.app/admin

Nếu thấy dashboard → Thành công! 🎉

Nếu bị redirect → Check lại Firestore rules hoặc đăng nhập lại.
