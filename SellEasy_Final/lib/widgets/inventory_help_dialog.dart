import 'package:flutter/material.dart';

class InventoryHelpDialog extends StatelessWidget {
  const InventoryHelpDialog({super.key});

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
              'Hướng dẫn quản lý kho',
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
              'Quản lý sản phẩm',
              [
                'Xem danh sách sản phẩm trong kho',
                'Nhấn vào sản phẩm để xem chi tiết',
                'Nhấn nút "Chi tiết" để xem thông tin đầy đủ',
                'Nhấn nút "Tạo đơn" để tạo đơn hàng mới',
                'Nhấn nút "Sửa" để chỉnh sửa thông tin sản phẩm',
                'Nhấn nút "Lịch sử" để xem lịch sử nhập xuất',
                'Nhấn nút "Xóa" để xóa sản phẩm khỏi kho',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Thao tác nhanh',
              [
                'Nhấn nút + ở góc dưới để thêm sản phẩm mới',
                'Kéo xuống để làm mới danh sách',
                'Nhấn vào ô tìm kiếm để tìm sản phẩm',
                'Nhấn nút lọc để lọc sản phẩm theo nhiều tiêu chí',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Quản lý tồn kho',
              [
                'Theo dõi số lượng tồn kho hiện tại',
                'Cập nhật số lượng khi nhập/xuất hàng',
                'Kiểm tra lịch sử nhập xuất chi tiết',
                'Nhận cảnh báo khi hàng sắp hết',
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
