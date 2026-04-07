# Hướng dẫn triển khai In-App Purchase cho SellEasy

## Tổng quan

Tài liệu này hướng dẫn chi tiết cách triển khai tính năng mua hàng trong ứng dụng (In-App Purchase) cho SellEasy với gói premium giá 50.000 VNĐ.

## Các bước đã thực hiện

1. **Cập nhật giá gói premium**: Đã thay đổi giá từ 99.000 VNĐ xuống 50.000 VNĐ trong dialog xác nhận mua hàng
2. **Cập nhật ID sản phẩm**: Đã thay đổi ID sản phẩm từ `selleasy_premium` thành `selleasy_premium_50k`
3. **Tạo tài liệu hướng dẫn**: Đã tạo hướng dẫn chi tiết về cách thiết lập trên Google Play Console

## Các bước cần thực hiện

### 1. Thiết lập Google Play Console

- Tạo sản phẩm in-app purchase mới với ID `selleasy_premium_50k` và giá 50.000 VNĐ
- Tham khảo chi tiết trong file `docs/google_play_iap_setup.md`

### 2. Cấu hình ứng dụng trên Google Play

#### 2.1. Tạo bản phát hành mới

- Tạo bản phát hành mới trên Google Play Console
- Tải lên file APK/AAB của ứng dụng đã cập nhật
- Đảm bảo phiên bản mới cao hơn phiên bản hiện tại

#### 2.2. Thiết lập tài khoản kiểm thử

- Thêm tài khoản Google của bạn vào danh sách tài khoản kiểm thử
- Thiết lập môi trường kiểm thử nội bộ (Internal Testing)

### 3. Kiểm thử mua hàng

#### 3.1. Cài đặt ứng dụng từ track kiểm thử

- Sử dụng link kiểm thử để cài đặt ứng dụng
- Đảm bảo bạn đang sử dụng tài khoản Google đã được thêm vào danh sách kiểm thử

#### 3.2. Thực hiện mua hàng kiểm thử

- Mở ứng dụng và điều hướng đến màn hình Premium Features
- Nhấn vào "Mua hàng Google Play"
- Xác nhận giao dịch và kiểm tra xem tính năng có được mở khóa không

### 4. Phát hành chính thức

- Khi đã kiểm thử thành công, phát hành ứng dụng lên Google Play
- Đảm bảo sản phẩm in-app purchase đã được kích hoạt

## Cấu trúc mã nguồn

### InAppPurchaseService

- **File**: `lib/services/in_app_purchase_service.dart`
- **Chức năng**: Xử lý tất cả các tương tác với Google Play Billing API
- **Phương thức chính**:
  - `initialize()`: Khởi tạo dịch vụ và kiểm tra trạng thái mua hàng
  - `buyPremium()`: Thực hiện giao dịch mua hàng
  - `restorePurchases()`: Khôi phục các giao dịch đã mua
  - `_listenToPurchaseUpdated()`: Xử lý các sự kiện mua hàng

### PurchaseProvider

- **File**: `lib/providers/purchase_provider.dart`
- **Chức năng**: Cung cấp trạng thái mua hàng cho UI
- **Thuộc tính chính**:
  - `isPremiumPurchased`: Kiểm tra xem người dùng đã mua premium chưa
  - `isLoading`: Trạng thái đang xử lý giao dịch

### PremiumFeaturesScreen

- **File**: `lib/screens/premium_features_screen.dart`
- **Chức năng**: Hiển thị màn hình tính năng premium và xử lý tương tác người dùng
- **Phương thức chính**:
  - `_showPurchaseConfirmation()`: Hiển thị dialog xác nhận mua hàng
  - `_restorePurchases()`: Khôi phục các giao dịch đã mua

## Xử lý sự cố

### Sản phẩm không tìm thấy

- Kiểm tra ID sản phẩm trong mã nguồn và Google Play Console
- Đảm bảo sản phẩm đã được kích hoạt trên Google Play Console

### Giao dịch không hoàn tất

- Kiểm tra logs để xem lỗi cụ thể
- Đảm bảo tài khoản kiểm thử đã được thiết lập đúng cách

### Tính năng không được mở khóa sau khi mua

- Kiểm tra phương thức `_verifyAndSavePurchase()` trong `InAppPurchaseService`
- Đảm bảo trạng thái mua hàng được lưu đúng cách

## Liên hệ hỗ trợ

Nếu bạn gặp bất kỳ vấn đề nào trong quá trình triển khai, vui lòng liên hệ:

- **Email**: support@selleasy.com
- **Điện thoại**: 0982581222
