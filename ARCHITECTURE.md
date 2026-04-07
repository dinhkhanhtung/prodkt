# Báo Cáo Logic Hoạt Động ProDKT

## 1. Kiến Trúc Tổng Quan

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT BROWSER                        │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │  Auth Layer  │  │  UI Layer    │  │  Data Layer      │   │
│  │  - Firebase  │  │  - React     │  │  - Firestore     │   │
│  │    Auth      │  │  - Tailwind  │  │  - ImgBB         │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    EXTERNAL SERVICES                       │
│  ┌─────────────────┐    ┌──────────────────────────────┐    │
│  │  ImgBB API      │    │  Firebase                   │    │
│  │  (Image Hosting)│    │  ├─ Authentication           │    │
│  │                 │    │  ├─ Cloud Firestore         │    │
│  │                 │    │  └─ Security Rules          │    │
│  └─────────────────┘    └──────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Luồng Xác Thực (Authentication Flow)

### 2.1. Đăng Ký Tài Khoản Mới

```
User Input (email, password, storeName)
           │
           ▼
┌──────────────────────┐
│  createUserWithEmail │  ← Firebase Auth
│      AndPassword()   │
└──────────────────────┘
           │
           ▼ (Success)
┌──────────────────────┐
│  Generate storeId    │  ← random 20-char string
│  using crypto        │
└──────────────────────┘
           │
           ▼
┌──────────────────────┐
│  Create User Doc     │  ← Firestore: users/{uid}
│  - email             │
│  - storeName         │
│  - storeId           │  ← Quan trọng: Multi-tenant key
│  - role: 'owner'     │
│  - createdAt         │
└──────────────────────┘
           │
           ▼
┌──────────────────────┐
│  Create Store Doc    │  ← Firestore: stores/{storeId}
│  - name              │
│  - ownerId           │
│  - settings          │
│  - createdAt         │
└──────────────────────┘
           │
           ▼
    Redirect to /dashboard
```

### 2.2. Đăng Nhập

```
User Input (email, password)
           │
           ▼
┌──────────────────────┐
│  signInWithEmail     │  ← Firebase Auth
│      AndPassword()   │
└──────────────────────┘
           │
           ▼ (Success)
┌──────────────────────┐
│  Fetch User Doc      │  ← Firestore: users/{uid}
│  from Firestore      │
└──────────────────────┘
           │
           ▼
┌──────────────────────┐
│  AuthContext State   │  ← Lưu user + storeId vào context
│  - user: FirebaseUser│
│  - userData: {...}   │
│  - storeId: string   │  ← Sử dụng cho mọi query
│  - loading: false    │
└──────────────────────┘
           │
           ▼
    Redirect to /dashboard
```

### 2.3. Auth Context State Management

```typescript
// components/AuthProvider.tsx
interface AuthContextType {
  user: User | null;              // Firebase Auth user
  userData: UserData | null;      // Extended data from Firestore
  storeId: string | null;         // KEY: Multi-tenant isolation
  loading: boolean;
  login: (email, password) => void;
  register: (email, password, storeName) => void;
  logout: () => void;
}
```

**Luồng dữ liệu:**
- `onAuthStateChanged` listener theo dõi thay đổi auth
- Khi user đăng nhập → fetch `userData` từ Firestore
- `storeId` được trích xuất từ `userData` và lưu vào context
- Mọi component con dùng `useAuth()` hook để truy cập

---

## 3. Multi-Tenant Architecture (Data Isolation)

### 3.1. Nguyên Tắc Cốt Lõi

**Mọi dữ liệu được phân tách theo `storeId`**

```
Firestore Root
├── users/{uid}                    ← Global (cross-store)
├── stores/{storeId}               ← Store config
│   ├── products/{productId}       ← Scoped data
│   ├── customers/{customerId}     ← Scoped data
│   ├── suppliers/{supplierId}     ← Scoped data
│   └── orders/{orderId}           ← Scoped data
```

### 3.2. Firestore Path Helper

```typescript
// lib/firestore.ts
const getStoreRef = (storeId: string) => 
  doc(db, 'stores', storeId);

const getProductsRef = (storeId: string) => 
  collection(db, 'stores', storeId, 'products');

const getCustomersRef = (storeId: string) => 
  collection(db, 'stores', storeId, 'customers');

// ... tương tự cho suppliers, orders
```

### 3.3. Query Pattern

```typescript
// Mọi query BẮT BUỘC phải có storeId
const getProducts = async (storeId: string) => {
  const q = query(
    collection(db, 'stores', storeId, 'products'),
    orderBy('createdAt', 'desc')
  );
  // ...
};

// Không có storeId = không thể query
// Đảm bảo data isolation giữa các store
```

---

## 4. Module Products (Quản Lý Sản Phẩm)

### 4.1. Data Model

```typescript
interface Product {
  name: string;           // Tên sản phẩm
  sku: string;           // Mã SKU
  barcode: string;       // Mã vạch
  category: string;      // Danh mục
  purchasePrice: number; // Giá nhập
  sellingPrice: number;  // Giá bán
  stock: number;         // Tồn kho
  unit: string;          // Đơn vị (cái, kg, ...)
  imageUrl: string;      // Ảnh từ ImgBB
  note: string;          // Ghi chú
  createdAt: string;     // ISO timestamp
  updatedAt: string;     // ISO timestamp
}
```

### 4.2. ImgBB Upload Flow

```
User chọn file ảnh
       │
       ▼
┌──────────────────────┐
│  File Validation     │  ← Kiểm tra type, size (max 10MB)
└──────────────────────┘
       │
       ▼
┌──────────────────────┐
│  Convert to Base64   │  ← FileReader.readAsDataURL()
└──────────────────────┘
       │
       ▼
┌──────────────────────┐
│  POST to ImgBB API   │  ← https://api.imgbb.com/1/upload
│  - key: API_KEY      │
│  - image: base64       │
└──────────────────────┘
       │
       ▼ (Success)
┌──────────────────────┐
│  Extract imageUrl    │  ← response.data.data.url
│  from response       │
└──────────────────────┘
       │
       ▼
┌──────────────────────┐
│  Save to Product Doc │  ← Firestore: stores/{storeId}/products
│  - imageUrl field    │
└──────────────────────┘
```

### 4.3. CRUD Operations

```typescript
// CREATE
const addProduct = async (storeId, productData) => {
  const docRef = await addDoc(
    collection(db, 'stores', storeId, 'products'),
    {
      ...productData,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    }
  );
  return docRef.id;
};

// READ (with real-time updates)
const subscribeProducts = (storeId, callback) => {
  const q = query(
    collection(db, 'stores', storeId, 'products'),
    orderBy('createdAt', 'desc')
  );
  return onSnapshot(q, (snapshot) => {
    const products = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    callback(products);
  });
};

// UPDATE
const updateProduct = async (storeId, productId, data) => {
  await updateDoc(
    doc(db, 'stores', storeId, 'products', productId),
    { ...data, updatedAt: new Date().toISOString() }
  );
};

// DELETE
const deleteProduct = async (storeId, productId) => {
  await deleteDoc(
    doc(db, 'stores', storeId, 'products', productId)
  );
};
```

---

## 5. Module POS (Point of Sale)

### 5.1. State Management (useState)

```typescript
// app/(dashboard)/pos/page.tsx

const [products, setProducts] = useState<Product[]>([]);        // Danh sách sản phẩm
const [searchQuery, setSearchQuery] = useState('');            // Tìm kiếm
const [cart, setCart] = useState<CartItem[]>([]);               // Giỏ hàng
const [customerSearch, setCustomerSearch] = useState('');        // Tìm KH
const [selectedCustomer, setSelectedCustomer] = useState(null);  // KH được chọn
const [discount, setDiscount] = useState(0);                    // Giảm giá
const [paymentMethod, setPaymentMethod] = useState('cash');       // PT thanh toán
const [paidAmount, setPaidAmount] = useState(0);                // Tiền đã trả
const [showReceipt, setShowReceipt] = useState(false);           // Hiện hóa đơn
const [createdOrder, setCreatedOrder] = useState(null);           // Đơn vừa tạo
```

### 5.2. Cart Logic

```typescript
// Thêm sản phẩm vào giỏ
const addToCart = (product) => {
  const existing = cart.find(item => item.productId === product.id);
  
  if (existing) {
    // Tăng số lượng nếu đã có
    setCart(cart.map(item => 
      item.productId === product.id
        ? { ...item, quantity: item.quantity + 1, 
            subtotal: (item.quantity + 1) * item.price }
        : item
    ));
  } else {
    // Thêm mới
    setCart([...cart, {
      productId: product.id,
      name: product.name,
      price: product.sellingPrice,
      quantity: 1,
      subtotal: product.sellingPrice,
      originalStock: product.stock  // Lưu tồn kho gốc
    }]);
  }
};

// Cập nhật số lượng
const updateQuantity = (productId, quantity) => {
  if (quantity <= 0) {
    setCart(cart.filter(item => item.productId !== productId));
  } else {
    setCart(cart.map(item =>
      item.productId === productId
        ? { ...item, quantity, subtotal: quantity * item.price }
        : item
    ));
  }
};

// Tính toán
const subtotal = cart.reduce((sum, item) => sum + item.subtotal, 0);
const finalAmount = subtotal - discount;
const debtAmount = finalAmount - paidAmount;  // Công nợ phát sinh
```

### 5.3. Order Creation Flow (Critical)

```
User nhấn "Thanh toán"
       │
       ▼
┌──────────────────────┐
│  Validation          │  ← Kiểm tra giỏ hàng không rỗng
└──────────────────────┘
       │
       ▼
┌──────────────────────┐
│  Create Order Doc    │  ← Firestore transaction
│                      │
│  order = {           │
│    customerId,       │
│    customerName,     │
│    items: [...],     │
│    subtotal,         │
│    discount,         │
│    finalAmount,      │
│    paidAmount,       │
│    debtAmount,       │  ← Quan trọng
│    paymentMethod,    │
│    createdAt,        │
│    updatedAt         │
│  }                   │
└──────────────────────┘
       │
       ▼
┌──────────────────────┐
│  Update Stock        │  ← Duyệt từng sản phẩm trong giỏ
│  for each product:   │
│  newStock =          │
│    originalStock -   │
│    quantity          │
└──────────────────────┘
       │
       ▼
┌──────────────────────┐
│  Update Customer     │  ← Nếu có công nợ
│  Debt                │
│  newDebt =           │
│    currentDebt +     │
│    debtAmount        │
└──────────────────────┘
       │
       ▼
┌──────────────────────┐
│  Show Receipt Modal  │  ← Hiển thị hóa đơn
│  Clear Cart          │  ← Reset giỏ hàng
└──────────────────────┘
```

### 5.4. Transaction Safety

```typescript
// lib/firestore.ts - createOrder
export const createOrder = async (storeId: string, orderData: Order) => {
  const batch = writeBatch(db);
  
  // 1. Create order
  const orderRef = doc(collection(db, 'stores', storeId, 'orders'));
  batch.set(orderRef, {
    ...orderData,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });
  
  // 2. Update stock for each item
  orderData.items.forEach(item => {
    const productRef = doc(db, 'stores', storeId, 'products', item.productId);
    batch.update(productRef, {
      stock: increment(-item.quantity),
      updatedAt: new Date().toISOString(),
    });
  });
  
  // 3. Update customer debt if applicable
  if (orderData.debtAmount > 0 && orderData.customerId) {
    const customerRef = doc(db, 'stores', storeId, 'customers', orderData.customerId);
    batch.update(customerRef, {
      debtAmount: increment(orderData.debtAmount),
      updatedAt: new Date().toISOString(),
    });
  }
  
  // Commit all operations atomically
  await batch.commit();
  return orderRef.id;
};
```

---

## 6. Module Customers & Suppliers (Công Nợ)

### 6.1. Customer Data Model

```typescript
interface Customer {
  name: string;          // Tên khách hàng
  phone: string;        // SĐT
  email: string;        // Email
  address: string;      // Địa chỉ
  debtAmount: number;   // Tổng công nợ hiện tại
  note: string;         // Ghi chú
  createdAt: string;    // Ngày tạo
  updatedAt: string;    // Ngày cập nhật
}
```

### 6.2. Debt Management Logic

```
┌────────────────────────────────────────────────────────┐
│                    DEBT FLOW                          │
├────────────────────────────────────────────────────────┤
│                                                        │
│  1. Initial State                                     │
│     Customer.debtAmount = 0                           │
│                                                        │
│  2. Create Order with Partial Payment                 │
│     finalAmount = 100,000đ                            │
│     paidAmount = 50,000đ                              │
│     debtAmount = 50,000đ                              │
│                                                        │
│  3. Update Customer                                   │
│     customer.debtAmount += 50,000đ                    │
│     customer.debtAmount = 50,000đ                     │
│                                                        │
│  4. Next Order                                        │
│     finalAmount = 200,000đ                            │
│     paidAmount = 0đ (công nợ toàn bộ)                 │
│     debtAmount = 200,000đ                             │
│                                                        │
│  5. Update Customer                                   │
│     customer.debtAmount = 50,000 + 200,000            │
│     customer.debtAmount = 250,000đ                    │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### 6.3. Supplier Debt (Nợ Nhà Cung Cấp)

Tương tự Customer nhưng hướng ngược lại:
- Khi nhập hàng từ supplier → tăng debtAmount của supplier
- Khi trả tiền cho supplier → giảm debtAmount

---

## 7. Module Orders (Lịch Sử Hóa Đơn)

### 7.1. Order Data Model

```typescript
interface Order {
  // Customer Info
  customerId: string | null;
  customerName: string;
  
  // Items
  items: Array<{
    productId: string;
    name: string;
    price: number;      // Giá bán tại thời điểm mua
    quantity: number;
    subtotal: number;   // price * quantity
  }>;
  
  // Financial
  subtotal: number;      // Tổng tiền hàng
  discount: number;      // Giảm giá
  finalAmount: number;   // Thành tiền (subtotal - discount)
  paidAmount: number;    // Đã thanh toán
  debtAmount: number;    // Còn nợ (finalAmount - paidAmount)
  
  // Payment
  paymentMethod: 'cash' | 'transfer' | 'debt';
  
  // Metadata
  createdAt: string;     // ISO timestamp
  updatedAt: string;     // ISO timestamp
}
```

### 7.2. Query Patterns

```typescript
// Lấy tất cả đơn hàng (mới nhất trước)
const getOrders = async (storeId: string) => {
  const q = query(
    collection(db, 'stores', storeId, 'orders'),
    orderBy('createdAt', 'desc')
  );
  // ...
};

// Lọc theo ngày
const getOrdersByDate = async (storeId: string, date: string) => {
  const q = query(
    collection(db, 'stores', storeId, 'orders'),
    where('createdAt', '>=', `${date}T00:00:00`),
    where('createdAt', '<=', `${date}T23:59:59`),
    orderBy('createdAt', 'desc')
  );
  // ...
};

// Tìm kiếm theo tên KH
const searchOrders = async (storeId: string, query: string) => {
  // Client-side filter vì Firestore không hỗ trợ
  // full-text search natively
  const allOrders = await getOrders(storeId);
  return allOrders.filter(order =>
    order.customerName.toLowerCase().includes(query.toLowerCase())
  );
};
```

---

## 8. Dashboard & Reporting

### 8.1. Aggregation Logic

```typescript
// Dashboard Stats
const calculateStats = (orders: Order[]) => {
  const today = new Date().toISOString().split('T')[0];
  
  // Doanh thu hôm nay
  const todayRevenue = orders
    .filter(o => o.createdAt.startsWith(today))
    .reduce((sum, o) => sum + o.finalAmount, 0);
  
  // Tổng đơn hàng
  const totalOrders = orders.length;
  
  // Công nợ phát sinh hôm nay
  const todayDebt = orders
    .filter(o => o.createdAt.startsWith(today))
    .reduce((sum, o) => sum + o.debtAmount, 0);
  
  // Sản phẩm sắp hết (stock < 10)
  const lowStockProducts = products.filter(p => p.stock < 10);
  
  return {
    todayRevenue,
    totalOrders,
    todayDebt,
    lowStockCount: lowStockProducts.length,
  };
};
```

### 8.2. Recent Orders

```typescript
// Lấy 5 đơn hàng gần nhất
const recentOrders = orders.slice(0, 5);
```

---

## 9. Data Flow Summary

### 9.1. Component Hierarchy

```
RootLayout
└── AuthProvider (Global Auth State)
    ├── Landing Page (/)          ← Public
    ├── Auth Pages (/login, /register)  ← Public
    └── DashboardLayout
        ├── Sidebar Navigation
        ├── Header (User info, Logout)
        └── Page Content
            ├── Dashboard         ← Stats, Charts
            ├── Products          ← CRUD + ImgBB
            ├── POS               ← Cart, Checkout
            ├── Orders            ← History, Filter
            ├── Customers         ← CRUD + Debt
            └── Suppliers         ← CRUD + Debt
```

### 9.2. Hook Usage Pattern

```typescript
// Mỗi page sử dụng:
const { user, userData, storeId } = useAuth();  // Lấy auth + storeId

// Fetch data với storeId
useEffect(() => {
  if (!storeId) return;
  
  // Subscribe real-time updates
  const unsubscribe = subscribeProducts(storeId, (data) => {
    setProducts(data);
  });
  
  return () => unsubscribe();  // Cleanup
}, [storeId]);

// Thực hiện CRUD
const handleAdd = async (data) => {
  await addProduct(storeId, data);  // Truyền storeId
};
```

---

## 10. Security Considerations

### 10.1. Firestore Security Rules (Cần thiết lập)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read their own user document
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
    }
    
    // Store data - only accessible by owner
    match /stores/{storeId}/{document=**} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.storeId == storeId;
    }
  }
}
```

### 10.2. Client-Side Guards

```typescript
// DashboardLayout.tsx
if (!user || !storeId) {
  router.push('/login');  // Redirect if not authenticated
  return null;
}
```

---

## 11. Performance Optimizations

1. **Real-time Subscriptions**: Sử dụng `onSnapshot` thay vì polling
2. **Lazy Loading**: Chỉ load data khi cần (theo route)
3. **Debounced Search**: Tránh query liên tục khi user type
4. **Batch Operations**: Dùng `writeBatch` cho nhiều updates
5. **Image Optimization**: ImgBB tự động resize và CDN delivery

---

## 12. Error Handling

```typescript
// Pattern sử dụng trong toàn bộ app
try {
  await someFirestoreOperation();
} catch (error) {
  console.error('Detailed error:', error);
  alert('Thông báo lỗi thân thiện với user');
}

// Loading states
const [loading, setLoading] = useState(true);
// Hiển thị spinner khi đang load
```

---

## Tóm Tắt Kiến Trúc

**ProDKT** là ứng dụng **React + Firebase** sử dụng kiến trúc:
- **Frontend**: Next.js 14 App Router, React Hooks, Tailwind CSS
- **Backend**: Firebase Authentication + Cloud Firestore
- **Storage**: ImgBB cho hình ảnh (miễn phí)
- **Architecture**: Multi-tenant với storeId isolation
- **Data Flow**: Unidirectional (Context API) + Real-time subscriptions
- **Security**: Client-side guards + Firestore Security Rules
