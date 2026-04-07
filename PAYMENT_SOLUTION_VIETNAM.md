# GIẢI PHÁP THANH TOÁN PRODKT - PHÙ HỢP VIỆT NAM

## Vấn đề hiện tại
- Stripe chưa hỗ trợ Việt Nam
- PayPal ít người dùng ở VN
- API ngân hàng rất khó xin (cần giấy phép, doanh nghiệp, bảo lãnh...)

## Giải pháp đề xuất: Manual Payment + Admin Dashboard

### Flow thanh toán:
```
User đăng ký → Chọn gói PRO → Hiển thị QR/TK ngân hàng 
→ User chuyển khoản → Upload ảnh CK → Chờ admin duyệt
→ Admin xác nhận → Kích hoạt PRO
```

---

## 1. SCHEMA MỞ RỘNG

### payments/{paymentId}
```typescript
interface Payment {
  id: string;
  userId: string;
  storeId: string;
  amount: number;           // Số tiền (99000)
  plan: 'monthly' | 'yearly';
  status: 'pending' | 'verified' | 'rejected' | 'expired';
  
  // Thông tin chuyển khoản
  bankCode: string;       // Vietcombank, Techcombank...
  accountNumber: string;  // STK ngân hàng của admin
  accountName: string;    // Tên chủ TK
  transferContent: string; // Nội dung CK: "PRODKT-{userId}"
  
  // Chứng từ từ user
  receiptImage?: string;  // URL ảnh chụp màn hình CK
  receiptNote?: string;   // Ghi chú từ user
  transferredAt?: Timestamp; // Thời gian user nói đã chuyển
  
  // Admin xử lý
  verifiedBy?: string;    // Admin userId
  verifiedAt?: Timestamp;
  rejectionReason?: string;
  
  // Thời hạn
  validUntil: Timestamp;  // Ngày hết hạn subscription
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### users/{userId} - Bổ sung
```typescript
interface User {
  // ... existing fields
  
  subscription: {
    plan: 'free' | 'pro' | 'enterprise';
    status: 'active' | 'expired' | 'pending';
    startedAt?: Timestamp;
    expiresAt?: Timestamp;
    lastPaymentId?: string;
  };
  
  paymentHistory: string[]; // Array of paymentIds
}
```

### Cấu hình ngân hàng (Admin)
```typescript
// configs/bankAccounts (collection public read)
interface BankAccount {
  id: string;
  bankCode: string;       // VCB, TCB, VPB...
  bankName: string;       // Tên đầy đủ
  accountNumber: string;
  accountName: string;
  isActive: boolean;
  isDefault: boolean;
  qrImageUrl?: string;    // Ảnh QR code sẵn
}
```

---

## 2. NGÂN HÀNG HỖ TRỢ (Phổ biến VN)

| Mã | Tên ngân hàng | QR Support | Notes |
|----|--------------|------------|-------|
| VCB | Vietcombank | ✅ | Phổ biến nhất |
| TCB | Techcombank | ✅ | Free CK |
| VPB | VPBank | ✅ | Start-up yêu thích |
| MB | MB Bank | ✅ | App tốt |
| ACB | ACB | ✅ | Doanh nghiệp |
| MSB | Maritime Bank | ✅ | Free CK |

---

## 3. ADMIN DASHBOARD

### Trang quản lý: `/admin`

#### 3.1 Dashboard tổng quan
```
┌─────────────────────────────────────────────┐
│  📊 ADMIN DASHBOARD - PRODKT               │
├─────────────────────────────────────────────┤
│  Tổng Users: 1,234    |    PRO Users: 56   │
│  Pending Payments: 12 |    Revenue: 5.5M   │
└─────────────────────────────────────────────┘
```

#### 3.2 Quản lý Payments (`/admin/payments`)
**Danh sách chờ duyệt:**
```
┌──────────┬──────────┬──────────┬─────────┬──────────┬────────┐
│ User     │ Gói      │ Số tiền  │ Ngân hàng│ Ngày CK  │ Action │
├──────────┼──────────┼──────────┼─────────┼──────────┼────────┤
│ Nguyen A │ PRO 1T   │ 99,000   │ Vietcom │ 07/04    │ [Duyệt]│
│ Tran B   │ PRO 1N   │ 990,000  │ Techcom │ 06/04    │ [Duyệt]│
│ Le C     │ PRO 1T   │ 99,000   │ VPBank  │ 05/04    │ [Từ chối]│
└──────────┴──────────┴──────────┴─────────┴──────────┴────────┘
```

**Chi tiết khi click:**
- Ảnh chụp màn hình chuyển khoản
- Số tiền user claim đã chuyển
- So sánh với giá gói
- Button: ✅ Duyệt | ❌ Từ chối | 📝 Yêu cầu bổ sung

#### 3.3 Quản lý Users (`/admin/users`)
```
┌────────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
│ Email      │ Store    │ Plan     │ Status   │ Expires  │ Action   │
├────────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
│ a@mail.com │ Store A  │ PRO      │ Active   │ 07/05    │ [Gia hạn]│
│ b@mail.com │ Store B  │ Free     │ Active   │ -        │ [Nâng cấp]│
│ c@mail.com │ Store C  │ PRO      │ Expired  │ 01/03    │ [Nhắc nhở]│
└────────────┴──────────┴──────────┴──────────┴──────────┴──────────┘
```

#### 3.4 Quản lý Ngân hàng (`/admin/banks`)
- Thêm/sửa/xóa tài khoản ngân hàng nhận tiền
- Upload QR code cho từng ngân hàng
- Set default account

#### 3.5 Báo cáo Doanh thu (`/admin/revenue`)
- Theo ngày/tuần/tháng/năm
- Theo ngân hàng
- Theo gói dịch vụ
- Export Excel

---

## 4. USER FLOW - UPGRADE TO PRO

### Bước 1: Chọn gói
```
┌─────────────────────────────────────────┐
│  Nâng cấp lên PRO                      │
│                                         │
│  [99K/tháng]    [990K/năm - Tiết kiệm] │
│                                         │
│  ✓ Không giới hạn sản phẩm             │
│  ✓ Không giới hạn đơn hàng             │
│  ✓ Multi-store (5 cửa hàng)            │
│                                         │
│  [Tiếp tục thanh toán]                  │
└─────────────────────────────────────────┘
```

### Bước 2: Chọn phương thức
```
┌─────────────────────────────────────────┐
│  Thanh toán qua chuyển khoản ngân hàng │
│                                         │
│  Chọn ngân hàng:                       │
│  [Vietcombank] [Techcombank] [VPBank]  │
│  [MB Bank] [ACB] [Khác...]             │
│                                         │
│  Số tài khoản: 1234567890              │
│  Chủ TK: NGUYEN VAN A                  │
│                                         │
│  NỘI DUNG CK: PRODKT-uid123456         │
│                                         │
│  [📷 Tải ảnh QR lớn hơn]               │
│                                         │
└─────────────────────────────────────────┘
```

### Bước 3: Xác nhận đã chuyển
```
┌─────────────────────────────────────────┐
│  Xác nhận thanh toán                   │
│                                         │
│  Đã chuyển khoản?                      │
│                                         │
│  [📷 Upload ảnh chụp màn hình]         │
│                                         │
│  Ngày giờ chuyển: [07/04/2025 15:30]   │
│                                         │
│  Ghi chú: [____________________]        │
│                                         │
│  [✓ Tôi đã chuyển 99,000đ]             │
│                                         │
└─────────────────────────────────────────┘
```

### Bước 4: Chờ duyệt
```
┌─────────────────────────────────────────┐
│  ⏳ Đang chờ xác nhận                   │
│                                         │
│  Thanh toán của bạn đang được kiểm tra.│
│  Thời gian xử lý: 5 phút - 24 giờ.    │
│                                         │
│  Mã thanh toán: PAY-123456             │
│                                         │
│  [Về trang chủ]                        │
└─────────────────────────────────────────┘
```

---

## 5. FIRESTORE SECURITY RULES

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ... existing rules ...
    
    // Payments - user chỉ xem của mình
    match /payments/{paymentId} {
      allow read: if request.auth != null && 
        (resource.data.userId == request.auth.uid || isAdmin());
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.userId;
      allow update: if isAdmin();  // Chỉ admin cập nhật status
    }
    
    // Bank accounts - public read (để hiển thị cho user)
    match /bankAccounts/{accountId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Admin functions
    function isAdmin() {
      return request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

---

## 6. CẤU HÌNH ADMIN

### Tạo admin user:
```javascript
// Trong Firestore, set 1 user có role = 'admin'
await updateDoc(doc(db, 'users', 'admin-user-id'), {
  role: 'admin',
  email: 'admin@prodkt.vn'
});
```

### Middleware kiểm tra admin:
```typescript
// middleware.ts bổ sung
if (pathname.startsWith('/admin')) {
  const user = await getUser(request);
  if (!user || user.role !== 'admin') {
    return NextResponse.redirect(new URL('/login', request.url));
  }
}
```

---

## 7. TÍNH NĂNG BỔ SUNG

### 7.1 Reminder tự động
- Email/SMS nhắc nhở trước 7 ngày hết hạn
- Email thông báo khi được duyệt

### 7.2 Hoàn tiền
- Admin có thể hoàn tiền (ghi nhận lý do)
- Pro rating: Hoàn tiền theo số ngày chưa dùng

### 7.3 Manual upgrade
- Admin có thể nâng cấp user thủ công (tặng pro, bồi thường...)

---

## 8. UI COMPONENTS CẦN TẠO

### Admin Side:
- [ ] AdminLayout (sidebar admin)
- [ ] PaymentTable (danh sách chờ duyệt)
- [ ] PaymentDetailModal (xem ảnh, duyệt/từ chối)
- [ ] UserTable (quản lý users)
- [ ] BankAccountManager (thêm/sửa TK ngân hàng)
- [ ] RevenueChart (biểu đồ doanh thu)

### User Side:
- [ ] PricingCard (hiển thị gói)
- [ ] BankSelector (chọn ngân hàng)
- [ ] QRCodeDisplay (hiển thị QR)
- [ ] PaymentReceiptUpload (upload ảnh CK)
- [ ] PaymentStatusTracker (theo dõi trạng thái)

---

## 9. ESTIMATE THỜI GIAN

| Tính năng | Effort | Priority |
|-----------|--------|----------|
| Schema Firestore + Security Rules | 0.5 ngày | 🔴 Cao |
| User Payment Flow (chọn gói, upload CK) | 1 ngày | 🔴 Cao |
| Admin Payment Dashboard | 1.5 ngày | 🔴 Cao |
| Admin User Management | 0.5 ngày | 🟡 TB |
| Admin Revenue Reports | 1 ngày | 🟡 TB |
| Email notifications | 0.5 ngày | 🟢 Thấp |

**Tổng: ~5 ngày cho MVP payment system**

---

## 10. LỢI ÍCH GIẢI PHÁP NÀY

✅ **Không cần API ngân hàng** - Dùng chuyển khoản thủ công  
✅ **Không phí giao dịch** - Không mất % phí như Stripe/PayPal  
✅ **Phổ biến VN** - Người VN quen chuyển khoản  
✅ **Kiểm soát tốt** - Admin duyệt thủ công, giảm fraud  
✅ **Linh hoạt** - Có thể hỗ trợ Momo/ZaloPay sau này  

---

**Bạn muốn bắt đầu implement giải pháp này không?**
