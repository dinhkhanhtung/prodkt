# ProDKT - Phần mềm Quản lý Bán hàng & Báo cáo Thuế

Ứng dụng web SaaS quản lý bán hàng, tồn kho, công nợ cho Hộ Kinh Doanh.
Hoàn toàn miễn phí chi phí vận hành.

## Tech Stack

- **Frontend**: Next.js 14 (App Router), React, Tailwind CSS
- **Backend & Database**: Firebase Authentication, Cloud Firestore
- **Image Storage**: ImgBB API (miễn phí)
- **Deployment**: Vercel + GitHub

## Tính năng chính

1. **Multi-tenant**: Mỗi user có storeId riêng, dữ liệu được phân tách hoàn toàn
2. **Quản lý sản phẩm**: Tích hợp upload ảnh lên ImgBB
3. **POS bán hàng**: Giao diện trực quan, tạo hóa đơn nhanh chóng
4. **Quản lý khách hàng**: Theo dõi công nợ
5. **Quản lý nhà cung cấp**: Theo dõi công nợ
6. **Báo cáo hóa đơn**: Lịch sử giao dịch, doanh thu

## Cài đặt

```bash
# Cài dependencies
npm install

# Tạo file .env.local với các biến:
# - Firebase config
# - ImgBB API key (đã có sẵn)

# Chạy dev server
npm run dev
```

## Triển khai

1. Tạo project Firebase mới
2. Bật Authentication (Email/Password) và Firestore
3. Copy config Firebase vào `.env.local`
4. Deploy lên Vercel

## License

MIT - Miễn phí sử dụng
