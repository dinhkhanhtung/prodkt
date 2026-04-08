# ROADMAP: Tích hợp tính năng từ Vidu Family & Kimke

## 📊 Đánh giá tính năng hợp lý để tích hợp

### ✅ NÊN TÍCH HỢP (High Value, phù hợp ProDKT)

| # | Tính năng | Nguồn | Lý do hợp lý | Priority |
|---|-----------|-------|--------------|----------|
| 1 | **Personal Finance** | Vidu Family | User là chủ shop cũng cần quản lý chi tiêu cá nhân | HIGH |
| 2 | **Debt Management** | Vidu Family | Quản lý công nợ với đối tác, khách hàng | HIGH |
| 3 | **Recurring Transactions** | Vidu Family | Tự động hóa chi phí định kỳ (thuê, điện, lương) | HIGH |
| 4 | **Partner Hall of Fame** | Kimke | Xếp hạng đối tác uy tín, giúp tìm nguồn hàng tốt | MEDIUM |
| 5 | **Community Blog/Feed** | Kimke | Cộng đồng chia sẻ kinh nghiệm bán hàng | MEDIUM |

### ❌ KHÔNG NÊN TÍCH HỢP (Low value hoặc trùng lặp)

| Tính năng | Nguồn | Lý do KHÔNG hợp lý |
|-----------|-------|-------------------|
| Chat Heads | Kimke | Phức tạp, không cần thiết cho B2B |
| Membership Tiers | Kimke | ProDKT không cần phân cấp thành viên |
| Broadcast | Kimke | Spam risk, không phù hợp B2B |
| Savings Goals | Vidu Family | Không liên quan đến quản lý shop |
| Budget Planner | Vidu Family | Giao diện phức tạp, ít dùng |

---

## 🎯 PHASE 1: Core Features (Tuần 1-2)

### 1. Personal Finance Module
```
📁 app/(dashboard)/personal-finance/page.tsx
📁 lib/personalFinance.ts (new schema)

Schema:
- PersonalExpense { userId, type: income|expense, amount, category, note, date }
- PersonalDebt { userId, type: borrow|lend, amount, person, status, dueDate }
- RecurringTransaction { userId, name, amount, frequency, nextDate, active }

Features:
✓ Thu chi cá nhân (không liên quan shop)
✓ Quản lý nợ cá nhân & công nợ với đối tác
✓ Giao dịch định kỳ tự động
```

### 2. Debt Management
```
📁 app/(dashboard)/debts/page.tsx

Features:
✓ Theo dõi khoản vay & cho vay
✓ Tự động tạo giao dịch khi trả nợ
✓ Cảnh báo quá hạn
✓ Liên kết với khách hàng/đối tác
```

### 3. Recurring Transactions
```
📁 app/(dashboard)/recurring/page.tsx

Features:
✓ Thiết lập giao dịch lặp (daily, weekly, monthly)
✓ Tự động tạo vào ngày đến hạn
✓ Thông báo trước khi tạo
```

---

## 🎯 PHASE 2: Community Features (Tuần 3)

### 4. Partner Hall of Fame
```
📁 app/(dashboard)/partners/hall-of-fame/page.tsx

Features:
✓ Bảng xếp hạng đối tác theo đánh giá
✓ Top 10 đối tác uy tín nhất
✓ Lọc theo danh mục ngành
✓ Badge "Verified Partner", "Top Rated"
```

### 5. Community Blog/Feed
```
📁 app/(dashboard)/community/page.tsx

Features:
✓ Đăng bài chia sẻ kinh nghiệm
✓ Tìm nguồn hàng ("Cần mua sỉ điện thoại")
✓ Comment, like
✓ Gắn tag danh mục
```

---

## 📋 Thứ tự triển khai

### Tuần 1: Personal Finance + Debt
- [ ] Tạo schema mới trong Firestore
- [ ] UI Personal Finance page
- [ ] UI Debt Management page
- [ ] Thêm vào sidebar

### Tuần 2: Recurring + Hoàn thiện
- [ ] Recurring Transactions UI
- [ ] Auto-generate logic (cron/cloud function)
- [ ] Testing & fix bugs

### Tuần 3: Community
- [ ] Partner Hall of Fame
- [ ] Community Blog/Feed
- [ ] Integration with Chat system

---

## 🎨 Design Notes

- **Theme:** Emerald theme như hiện tại
- **Icons:** Lucide icons
- **Layout:** Giống các page hiện tại (card-based)
- **Mobile:** Responsive như dashboard

---

*Ready to implement!*
