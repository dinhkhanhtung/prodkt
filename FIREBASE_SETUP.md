# Hướng Dẫn Thiết Lập Firebase Production - ProDKT

## Bước 1: Tạo Firebase Project

### 1.1 Truy cập Firebase Console
1. Vào https://console.firebase.google.com
2. Click **Create a project**

### 1.2 Đặt tên project
- **Project name:** `prodkt-production` (hoặc tên bạn muốn)
- Click **Continue**

### 1.3 Google Analytics (Tùy chọn)
- Có thể **Enable** để theo dõi usage
- Hoặc **Disable** nếu không cần
- Click **Create project**

### 1.4 Đợi project được tạo (30-60 giây)
- Click **Continue** khi sẵn sàng

---

## Bước 2: Thêm Ứng Dụng Web

### 2.1 Register app
1. Ở màn hình chính Firebase, click icon **</>** (Web)
2. **App nickname:** `prodkt-web`
3. Click **Register app**

### 2.2 Copy Firebase Config
Sau khi register, bạn sẽ thấy đoạn code như sau:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXX",
  authDomain: "prodkt-production.firebaseapp.com",
  projectId: "prodkt-production",
  storageBucket: "prodkt-production.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef123456"
};
```

**Lưu lại các giá trị này để dùng ở Bước 6**

---

## Bước 3: Bật Firebase Authentication

### 3.1 Vào Authentication
1. Left sidebar → **Build** → **Authentication**
2. Click **Get started**

### 3.2 Bật Email/Password
1. Tab **Sign-in method**
2. Tìm **Email/Password** → Click **Enable**
3. **Save**

### 3.3 (Tùy chọn) Bật thêm các provider khác
- Google Sign-in (nếu muốn đăng nhập bằng Google)
- Phone (nếu muốn OTP)

---

## Bước 4: Tạo Cloud Firestore Database

### 4.1 Vào Firestore
1. Left sidebar → **Build** → **Firestore Database**
2. Click **Create database**

### 4.2 Chọn chế độ bảo mật
- Chọn **Start in production mode** (an toàn hơn)
- Click **Next**

### 4.3 Chọn location
- **Cloud Firestore location:** `asia-southeast1` (Singapore) - gần Việt Nam nhất
- Click **Enable**

---

## Bước 5: Cấu Hình Firestore Security Rules

### 5.1 Edit Rules
1. Firestore Database → Tab **Rules**
2. Xóa code mặc định, thay bằng:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - chỉ user đó được đọc/ghi
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Stores collection - chỉ owner của store được truy cập
    match /stores/{storeId} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.storeId == storeId;
      
      // Subcollections tự động kế thừa rules từ parent
      match /{document=**} {
        allow read, write: if request.auth != null && 
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.storeId == storeId;
      }
    }
  }
}
```

### 5.2 Publish
- Click **Publish** (mất 1-2 phút để apply)

---

## Bước 6: Thêm Environment Variables vào Vercel

### 6.1 Vào Project Settings
1. Vào https://vercel.com/dashboard
2. Chọn project **prodkt** → **Settings** → **Environment Variables**

### 6.2 Thêm từng biến

| Key | Giá trị (copy từ Bước 2.2) |
|-----|---------------------------|
| `NEXT_PUBLIC_FIREBASE_API_KEY` | `AIzaSyXXXXXXXX...` |
| `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` | `prodkt-production.firebaseapp.com` |
| `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | `prodkt-production` |
| `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET` | `prodkt-production.appspot.com` |
| `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID` | `123456789` |
| `NEXT_PUBLIC_FIREBASE_APP_ID` | `1:123456789:web:abcdef...` |
| `NEXT_PUBLIC_IMGBB_API_KEY` | `398c8af4e13d05bed6d6a0351f437511` (hoặc key mới) |

### 6.3 Lưu ý quan trọng
- **Development:** Chọn preview + production
- Click **Save** sau mỗi biến

---

## Bước 7: Redeploy Vercel

Sau khi thêm environment variables, cần redeploy:

### Cách 1: Auto-deploy từ GitHub
- Push code mới lên GitHub → Vercel tự động deploy

### Cách 2: Manual redeploy
1. Vercel Dashboard → project → **Deployments**
2. Tìm deployment gần nhất → click **...** → **Redeploy**

### Cách 3: Vercel CLI
```bash
vercel --prod
```

---

## Bước 8: Kiểm Tra Production

### 8.1 Test các chức năng cơ bản
1. Truy cập URL Vercel (`https://prodkt-xxx.vercel.app`)
2. **Đăng ký** tài khoản mới
3. **Thêm sản phẩm** + upload ảnh
4. **Tạo đơn hàng** POS

### 8.2 Kiểm tra Firestore
1. Firebase Console → Firestore Database → Data
2. Xác nhận collections được tạo:
   - `users/{uid}`
   - `stores/{storeId}/products`
   - `stores/{storeId}/orders`
   - `stores/{storeId}/customers`

---

## Bước 9: (Tùy chọn) Tùy Chỉnh Domain

### 9.1 Thêm Custom Domain
1. Vercel Dashboard → project → **Settings** → **Domains**
2. Add domain: `app.prodkt.vn` (hoặc domain bạn có)
3. Cấu hình DNS theo hướng dẫn của Vercel

### 9.2 Cấu hình Firebase Auth Domain (nếu dùng custom domain)
1. Firebase Console → Authentication → Settings
2. **Authorized domains** → Add domain của bạn

---

## Troubleshooting

### Lỗi "Permission denied" khi đọc/ghi Firestore
- Kiểm tra Security Rules đã publish chưa
- Kiểm tra user đã có document trong `users/{uid}` chưa
- Kiểm tra `storeId` trong user document có khớp không

### Lỗi "API key not valid"
- Kiểm tra API key đã copy đúng chưa
- Kiểm tra project đã enable Firebase Auth chưa

### ImgBB upload failed
- Kiểm tra API key còn valid không (tạo mới tại https://api.imgbb.com)
- Kiểm tra file size < 10MB

---

## Checklist Hoàn Thành

- [ ] Firebase project đã tạo
- [ ] Firebase Authentication enabled (Email/Password)
- [ ] Firestore Database created (asia-southeast1)
- [ ] Security Rules published
- [ ] Vercel Environment Variables đã thêm đầy đủ
- [ ] Redeploy thành công
- [ ] Test đăng ký tài khoản OK
- [ ] Test thêm sản phẩm OK
- [ ] Test tạo đơn hàng OK

---

## Liên Hệ Hỗ Trợ

- **Firebase Issues:** https://firebase.google.com/support
- **Vercel Issues:** https://vercel.com/help
- **ProDKT Issues:** Tạo issue trên GitHub repo

**Chúc mừng! ProDKT của bạn đã sẵn sàng production! 🎉**
