import 'package:flutter/material.dart';

class AppHelpDialog extends StatelessWidget {
  const AppHelpDialog({super.key});

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
              'Hướng dẫn sử dụng',
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
              'Quản lý kho',
              [
                'Xem và quản lý sản phẩm trong kho',
                'Nhập hàng và cập nhật số lượng',
                'Kiểm tra lịch sử nhập xuất',
                'Tìm kiếm và lọc sản phẩm',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Bán hàng',
              [
                'Tạo đơn hàng mới',
                'Thêm sản phẩm vào đơn',
                'Tính tiền và thanh toán',
                'Quản lý khách hàng',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Báo cáo',
              [
                'Xem báo cáo doanh thu',
                'Theo dõi chi tiêu',
                'Phân tích lợi nhuận',
                'Xuất báo cáo chi tiết',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Cài đặt',
              [
                'Tùy chỉnh thông tin cửa hàng',
                'Quản lý người dùng',
                'Sao lưu và khôi phục',
                'Cấu hình hệ thống',
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
