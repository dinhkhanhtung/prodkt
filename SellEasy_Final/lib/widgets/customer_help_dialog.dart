import 'package:flutter/material.dart';

class CustomerHelpDialog extends StatelessWidget {
  const CustomerHelpDialog({super.key});

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
              'Hướng dẫn thêm khách hàng',
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
              'Thông tin khách hàng',
              [
                'Nhập tên khách hàng vào trường bắt buộc',
                'Nhập số điện thoại để liên hệ và tìm kiếm',
                'Nhập email nếu cần gửi hóa đơn hoặc thông báo',
                'Nhập địa chỉ để giao hàng hoặc xuất hóa đơn',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Quản lý khách hàng',
              [
                'Khách hàng được lưu trong hệ thống để sử dụng lại',
                'Có thể tìm kiếm khách hàng khi tạo đơn hàng',
                'Theo dõi lịch sử mua hàng của từng khách hàng',
                'Quản lý công nợ và thanh toán của khách hàng',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Lưu ý quan trọng',
              [
                'Tên khách hàng là trường bắt buộc duy nhất',
                'Số điện thoại nên nhập đúng định dạng để liên hệ',
                'Thông tin khách hàng được bảo mật trong hệ thống',
                'Có thể chỉnh sửa thông tin khách hàng sau khi đã lưu',
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
