import 'package:flutter/material.dart';

class SalesHelpDialog extends StatelessWidget {
  const SalesHelpDialog({super.key});

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
              'Hướng dẫn bán hàng',
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
              'Tạo đơn hàng',
              [
                'Chọn sản phẩm từ kho hàng',
                'Thêm sản phẩm tạm thời',
                'Điều chỉnh số lượng',
                'Áp dụng giảm giá/thuế',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Thanh toán',
              [
                'Nhập số tiền khách trả',
                'Tính tiền thối/công nợ',
                'Chọn phương thức thanh toán',
                'In hóa đơn bán hàng',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Quản lý khách hàng',
              [
                'Thêm thông tin khách hàng',
                'Theo dõi lịch sử mua hàng',
                'Quản lý công nợ',
                'Chăm sóc khách hàng',
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
