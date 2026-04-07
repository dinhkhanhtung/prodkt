import 'package:flutter/material.dart';

class ReportsHelpDialog extends StatelessWidget {
  const ReportsHelpDialog({super.key});

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
              'Hướng dẫn báo cáo',
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
              'Quản lý đơn hàng',
              [
                'Xem danh sách đơn hàng đã bán',
                'Nhấn vào đơn hàng để xem chi tiết',
                'Xem thông tin khách hàng và sản phẩm',
                'Theo dõi trạng thái thanh toán và công nợ',
                'Lọc đơn hàng theo nhiều tiêu chí',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Quản lý chi tiêu',
              [
                'Xem danh sách các khoản chi tiêu',
                'Thêm khoản chi tiêu mới',
                'Phân loại chi tiêu theo danh mục',
                'Theo dõi tổng chi phí theo thời gian',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Thống kê và báo cáo',
              [
                'Xem tổng doanh thu và lợi nhuận',
                'Biểu đồ thống kê theo thời gian',
                'Phân tích sản phẩm bán chạy',
                'Xuất báo cáo chi tiết',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Quản lý khách hàng',
              [
                'Xem danh sách khách hàng',
                'Theo dõi lịch sử mua hàng',
                'Quản lý công nợ khách hàng',
                'Tìm kiếm và lọc khách hàng',
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
