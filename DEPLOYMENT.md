# PRODUCTION DEPLOYMENT GUIDE - ProDKT

## Triển khai lên Vercel

### Bước 1: Chuẩn bị

```bash
# 1. Đảm bảo code chạy local tốt
npm run dev

# 2. Build local test
npm run build
```

### Bước 2: Thiết lập Firebase Production

1. **Tạo Firebase Project mới** (hoặc dùng project dev):
   - Vào https://console.firebase.google.com
   - Tạo project mới: `prodkt-production`

2. **Bật các dịch vụ**:
   - Authentication → Email/Password: **Enable**
   - Firestore Database → **Create database** (Start in production mode)

3. **Lấy Firebase Config**:
   - Project Settings → General → Your apps → Web app
   - Copy config vào biến môi trường Vercel

### Bước 3: Deploy lên Vercel

#### Cách 1: Deploy qua Windsurf (Nhanh)

```bash
# Deploy ngay (sẽ tạo project mới)
```

#### Cách 2: Deploy qua Vercel CLI

```bash
# 1. Cài Vercel CLI
npm i -g vercel

# 2. Login
vercel login

# 3. Deploy
vercel --prod
```

#### Cách 3: Deploy qua GitHub + Vercel Dashboard

1. **Push code lên GitHub**:
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/username/prodkt.git
git push -u origin main
```

2. **Import vào Vercel**:
   - Vào https://vercel.com/new
   - Import GitHub repo
   - Framework: Next.js
   - Add Environment Variables
   - Deploy

### Bước 4: Thiết lập Environment Variables trên Vercel

Vào Project Settings → Environment Variables, thêm các biến:

```
NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=123456789
NEXT_PUBLIC_FIREBASE_APP_ID=1:123456789:web:abcdef
NEXT_PUBLIC_IMGBB_API_KEY=398c8af4e13d05bed6d6a0351f437511
```

**Lưu ý quan trọng:**
- Tất cả biến `NEXT_PUBLIC_` đều expose ra client
- Không để API keys nhạy cảm (server-only) vào `NEXT_PUBLIC_`

### Bước 5: Cấu hình Firestore Security Rules

Vào Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - chỉ đọc user của chính mình
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Stores collection và subcollections
    match /stores/{storeId}/{document=**} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.storeId == storeId;
    }
  }
}
```

### Bước 6: Tùy chỉnh Domain (Optional)

1. Vào Vercel Dashboard → Project Settings → Domains
2. Add custom domain: `app.yourdomain.com`
3. Cấu hình DNS theo hướng dẫn

### Bước 7: Kiểm tra sau deploy

1. **Kiểm tra các trang**:
   - `/` - Landing page
   - `/login` - Trang đăng nhập
   - `/register` - Trang đăng ký
   - `/dashboard` - Dashboard (cần đăng nhập)

2. **Kiểm tra chức năng**:
   - Đăng ký tài khoản mới
   - Thêm sản phẩm + upload ảnh
   - Tạo đơn hàng POS

---

## Lưu ý Production

### 1. ImgBB API Key
- Hiện tại đang dùng key công khai trong code
- Nên tạo tài khoản ImgBB mới và thay key production riêng

### 2. Firebase Quotas (FREE tier)
- 50,000 đọc/ngày
- 20,000 ghi/ngày
- 1GB dữ liệu

### 3. Backup dữ liệu
- Export Firestore data định kỳ
- Dùng Firebase Extensions cho auto-backup

### 4. Monitoring
- Firebase Console → Analytics
- Vercel Dashboard → Analytics

---

## Troubleshooting

### Lỗi "useAuth must be used within an AuthProvider"
- Đã fix bằng cách thêm AuthProvider vào root layout

### Lỗi Firebase permission denied
- Kiểm tra Security Rules
- Đảm bảo user đã tạo document trong collection `users`

### Lỗi ImgBB upload failed
- Kiểm tra API key còn valid
- Kiểm tra file size (< 10MB)

### Lỗi build trên Vercel
- Kiểm tra Node version (cần 18+)
- Thêm vào package.json:
```json
"engines": {
  "node": ">=18.0.0"
}
```
