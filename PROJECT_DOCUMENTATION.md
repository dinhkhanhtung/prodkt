# PRODKT - PROJECT DOCUMENTATION
## Tài liệu chi tiết cho Code Agent

---

## 📋 TỔNG QUAN

**ProDKT** = Quản lý bán hàng + Tài chính cá nhân (Vidu Family) + Cộng đồng B2B (Kimke)

**Tech Stack:** Next.js 14 + TypeScript + Tailwind + Firebase

---

## 🗂️ CẤU TRÚC THƯ MỤC

```
app/(dashboard)/
├── dashboard/           # Dashboard + Charts
├── products/           # Quản lý sản phẩm
├── customers/        # Khách hàng
├── suppliers/        # Nhà cung cấp
├── pos/              # Bán hàng POS
├── orders/           # Đơn hàng
├── expenses/         # Chi phí shop
├── reports/          # Báo cáo
├── ai-analysis/      # AI phân tích
├── chat/             # Chat giữa users
├── partners/hall-of-fame/  # Xếp hạng
├── community/        # Feed cộng đồng
├── marketplace/      # B2B marketplace
├── personal-finance/ # Thu chi cá nhân
├── debts/            # Quản lý nợ
├── recurring/        # Giao dịch định kỳ
└── ...

lib/
└── firestore.ts      # TẤT CẢ schema & API
```

---

## 🔥 SCHEMA FIRESTORE

### COLLECTIONS

| Collection | Mô tả | Schema chính |
|------------|-------|--------------|
| `users` | Thông tin user | UserProfile |
| `stores` | Thông tin cửa hàng | Store |
| `stores/{id}/products` | Sản phẩm | Product |
| `stores/{id}/customers` | Khách hàng | Customer |
| `stores/{id}/orders` | Đơn hàng | Order |
| `stores/{id}/expenses` | Chi phí | Expense |
| `chatRooms` | Phòng chat | ChatRoom |
| `chatRooms/{id}/messages` | Tin nhắn | ChatMessage |
| `partnerRatings` | Đánh giá đối tác | PartnerRating |
| `partnerProfiles` | Hồ sơ đối tác | PartnerProfile |
| `communityPosts` | Bài đăng cộng đồng | CommunityPost |
| `b2bProducts` | Sản phẩm sỉ | B2BProduct |
| `b2bOrders` | Đơn hàng B2B | B2BOrder |
| `personalTransactions` | Thu chi cá nhân | PersonalTransaction |
| `personalDebts` | Nợ cá nhân | PersonalDebt |
| `recurringTransactions` | Giao dịch lặp | RecurringTransaction |

---

## 🎨 THEME & DESIGN

**Màu sắc chính (Emerald Theme):**
```css
Primary:    #059669 (emerald-600)
Secondary:  #F97316 (orange-500)
Background: #ecfdf5 (emerald-50)
Text:       #064e3b (emerald-900)
```

**Components UI:**
- Card: `bg-white rounded-xl border border-emerald-100 shadow-sm`
- Button Primary: `bg-emerald-600 text-white rounded-lg`
- Input: `border border-emerald-200 rounded-lg px-3 py-2`

---

## ⚡ PATTERNS QUAN TRỌNG

### 1. Server Component vs Client Component

```typescript
// Server Component (default) - dùng cho data static
export default function Page() {
  return <div>Content</div>
}

// Client Component - dùng cho interactive
'use client'
export default function Page() {
  const [state, setState] = useState()
  return <div>Interactive</div>
}
```

### 2. Firestore Data Fetching Pattern

```typescript
// Trong lib/firestore.ts
export async function getProducts(storeId: string): Promise<WithId<Product>[]> {
  const productsCol = collection(db, STORES_COLLECTION, storeId, 'products');
  const q = query(productsCol, orderBy('createdAt', 'desc'));
  const querySnapshot = await getDocs(q);
  return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as WithId<Product>));
}

// Trong page component
const [products, setProducts] = useState<WithId<Product>[]>([]);
useEffect(() => {
  if (user?.storeId) {
    getProducts(user.storeId).then(setProducts);
  }
}, [user?.storeId]);
```

### 3. Form Pattern

```typescript
const [formData, setFormData] = useState({
  field1: '',
  field2: 0,
});

const handleSubmit = async (e: React.FormEvent) => {
  e.preventDefault();
  await addDoc(collection, formData);
};
```

---

## 🛡️ AUTHENTICATION

**AuthProvider** cung cấp:
```typescript
const { user, loading, login, register, logout } = useAuth();

// user chứa:
{
  uid: string;
  email: string;
  storeId: string;
  storeName: string;
  role: 'owner' | 'admin' | 'staff';
}
```

---

## 📝 HƯỚNG DẪN THÊM TÍNH NĂNG MỚI

### Bước 1: Thêm Schema vào firestore.ts

```typescript
export interface NewFeature {
  id?: string;
  userId: string;
  // ... fields
  createdAt: string;
  updatedAt: string;
}

const NEW_FEATURE_COLLECTION = 'newFeature';

export async function getNewFeatures(userId: string): Promise<WithId<NewFeature>[]> {
  // Implementation
}

export async function addNewFeature(/* params */): Promise<string> {
  // Implementation
}
```

### Bước 2: Tạo Page

```typescript
// app/(dashboard)/new-feature/page.tsx
'use client';

import { useAuth } from '@/components/AuthProvider';
import { getNewFeatures } from '@/lib/firestore';

export default function NewFeaturePage() {
  const { user } = useAuth();
  // ... implementation
}
```

### Bước 3: Thêm vào Sidebar

```typescript
// Trong DashboardLayout.tsx, thêm vào navItems:
{ name: 'Tên Tính Năng', href: '/new-feature', icon: IconName },
```

### Bước 4: Thêm Icon Import

```typescript
import { IconName } from 'lucide-react';
```

---

## 🐛 COMMON ISSUES & FIXES

### Issue 1: Type 'string | undefined' not assignable
**Fix:** Kiểm tra ID trước khi gọi hàm
```typescript
{notif.id && (
  <button onClick={() => handleDelete(notif.id!)}>
    Delete
  </button>
)}
```

### Issue 2: Module not found 'date-fns'
**Fix:** Cài dependency
```bash
npm install date-fns
```

### Issue 3: Formatter type error in Recharts
**Fix:** Dùng type guard
```typescript
formatter={(value) => typeof value === 'number' ? formatCurrency(value) : value}
```

---

## 🔗 FILE QUAN TRỌNG NHẤT

| File | Mô tả | Khi nào cần sửa |
|------|-------|----------------|
| `lib/firestore.ts` | Tất cả API & Schema | Thêm/sửa database |
| `components/DashboardLayout.tsx` | Sidebar & Layout | Thêm menu mới |
| `components/AuthProvider.tsx` | Authentication | Sửa auth logic |
| `app/(dashboard)/*/page.tsx` | Các page UI | Thêm tính năng |

---

## 📞 CONTACT

Nếu cần thêm thông tin, kiểm tra:
1. Các file page.tsx hiện có để tham khảo pattern
2. lib/firestore.ts để xem API tương tự
3. SELLEASY_ANALYSIS.md để hiểu business logic

---

**Last Updated:** April 2024
**Version:** 2.0 (Full Integration with Vidu Family & Kimke)
