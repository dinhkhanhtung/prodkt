import 'package:flutter/material.dart';

class SettingsHelpDialog extends StatelessWidget {
  const SettingsHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 8, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Hướng dẫn cài đặt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Cài đặt cơ bản',
              [
                'Nhấn vào "Thông tin cửa hàng" để cập nhật thông tin',
                'Nhấn vào "Giao diện" để thay đổi chế độ sáng/tối',
                'Nhấn vào "Bảo mật & Thông báo" để quản lý thông báo',
                'Nhấn vào "Sao lưu & Khôi phục" để bảo vệ dữ liệu',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Tính năng nâng cao',
              [
                'Nhấn vào "Tính năng cao cấp" để xem các tính năng mở rộng',
                'Nhấn vào "Cài đặt nâng cao" để tùy chỉnh hệ thống',
                'Quản lý các trường tùy chỉnh cho sản phẩm',
                'Thiết lập các tùy chọn xuất báo cáo',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Hỗ trợ & Thông tin',
              [
                'Nhấn vào "Hướng dẫn sử dụng" để xem hướng dẫn chi tiết',
                'Nhấn vào "Câu hỏi thường gặp" để xem giải đáp',
                'Xem thông tin phiên bản hiện tại',
                'Đánh giá và chia sẻ ứng dụng',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Thao tác nhanh',
              [
                'Kéo xuống để làm mới cài đặt',
                'Nhấn vào biểu tượng mũi tên để mở rộng các mục',
                'Nhấn vào công tắc để bật/tắt các tùy chọn',
                'Nhấn nút "Khôi phục cài đặt gốc" để đặt lại mặc định',
              ],
            ),
          ],
        ),
      ),
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.check_circle),
          label: const Text('Đã hiểu'),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
      ],
    );
  }
}
