# Hướng dẫn thiết lập In-App Purchase trên Google Play Console

## 1. Đăng nhập vào Google Play Console

- Truy cập [Google Play Console](https://play.google.com/console)
- Đăng nhập bằng tài khoản Google đã đăng ký làm nhà phát triển

## 2. Chọn ứng dụng SellEasy

- Từ danh sách ứng dụng, chọn ứng dụng SellEasy
- Nếu chưa có ứng dụng, bạn cần tạo ứng dụng mới và tải lên bản APK/AAB đầu tiên

## 3. Thiết lập sản phẩm In-App Purchase

### 3.1. Tạo sản phẩm mới

- Từ menu bên trái, chọn "Monetize" > "Products" > "In-app products"
- Nhấn nút "Create product"
- Chọn loại sản phẩm là "Non-consumable" (sản phẩm mua một lần)

### 3.2. Cấu hình sản phẩm

- **Product ID**: Nhập `selleasy_premium_50k` (phải khớp với ID trong mã nguồn)
- **Name**: Nhập "SellEasy Premium"
- **Description**: Nhập "Mở khóa tất cả tính năng nâng cao của SellEasy"

### 3.3. Thiết lập giá

- Chọn "Default price" và nhập giá 50.000 VNĐ
- Kiểm tra giá ở các quốc gia khác nếu cần

### 3.4. Hoàn tất và kích hoạt

- Nhấn "Save" để lưu sản phẩm
- Đảm bảo trạng thái sản phẩm là "Active"

## 4. Thiết lập tài khoản kiểm thử

### 4.1. Thêm tài khoản kiểm thử

- Từ menu bên trái, chọn "Setup" > "License testing"
- Thêm email của tài khoản Google bạn muốn sử dụng để kiểm thử mua hàng
- Lưu ý: Tài khoản kiểm thử sẽ không bị trừ tiền thật khi mua hàng

### 4.2. Thiết lập môi trường kiểm thử

- Từ menu bên trái, chọn "Testing" > "Internal testing"
- Tạo track kiểm thử mới hoặc sử dụng track hiện có
- Thêm tài khoản kiểm thử vào danh sách người kiểm thử

## 5. Kiểm tra và xác minh

### 5.1. Tải ứng dụng từ track kiểm thử

- Sử dụng tài khoản kiểm thử để tải ứng dụng từ link kiểm thử
- Đảm bảo bạn đang sử dụng phiên bản ứng dụng có tích hợp in-app purchase

### 5.2. Kiểm tra mua hàng

- Mở ứng dụng và điều hướng đến màn hình Premium Features
- Nhấn vào "Mua hàng Google Play"
- Xác nhận giao dịch và kiểm tra xem tính năng có được mở khóa không

## 6. Phát hành chính thức

- Khi đã kiểm tra thành công, bạn có thể phát hành ứng dụng với tính năng in-app purchase
- Đảm bảo rằng sản phẩm in-app purchase đã được kích hoạt và có trạng thái "Active"

## Lưu ý quan trọng

1. **Tài khoản nhà phát triển**: Phải đã thanh toán phí nhà phát triển 25 USD
2. **Thông tin thanh toán**: Phải thiết lập đầy đủ thông tin thanh toán trong Merchant Center
3. **Chính sách**: Tuân thủ các chính sách của Google về in-app purchase
4. **Thuế**: Cung cấp thông tin thuế chính xác để tránh vấn đề về thanh toán
5. **Kiểm thử**: Luôn kiểm thử kỹ lưỡng trước khi phát hành chính thức

## Xử lý sự cố

- Nếu gặp lỗi "Item not found", hãy kiểm tra lại Product ID trong mã nguồn và Google Play Console
- Nếu gặp lỗi "Purchase failed", hãy kiểm tra cấu hình tài khoản kiểm thử và trạng thái sản phẩm
- Nếu ứng dụng không nhận diện được giao dịch, hãy kiểm tra lại mã xử lý giao dịch trong ứng dụng
