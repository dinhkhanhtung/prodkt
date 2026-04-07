import 'package:flutter/material.dart';

class ExpenseHelpDialog extends StatelessWidget {
  const ExpenseHelpDialog({super.key});

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
              'Hướng dẫn ghi chi tiêu',
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
              'Nhập thông tin chi tiêu',
              [
                'Nhập số tiền chi tiêu vào trường bắt buộc',
                'Chọn danh mục chi tiêu phù hợp từ danh sách',
                'Thêm mô tả chi tiết để ghi nhớ mục đích chi tiêu',
                'Nhấn nút "Lưu" để lưu khoản chi tiêu',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Các danh mục chi tiêu',
              [
                'Quảng cáo: chi phí marketing, quảng cáo',
                'Vận chuyển: chi phí giao hàng, vận chuyển',
                'Xăng xe: chi phí xăng dầu, đi lại',
                'Điện nước: chi phí tiện ích cơ bản',
                'Thuê mặt bằng: tiền thuê nhà, mặt bằng',
                'Lương nhân viên: chi phí nhân công',
                'Bao bì đóng gói: vật tư đóng gói',
                'Thiết bị văn phòng: mua sắm thiết bị',
                'Phí ngân hàng: phí dịch vụ ngân hàng',
                'Khác: các chi phí khác',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Quản lý chi tiêu',
              [
                'Các khoản chi tiêu được hiển thị trong tab Báo Cáo',
                'Có thể xem lại và chỉnh sửa chi tiêu đã lưu',
                'Thống kê chi tiêu theo danh mục và thời gian',
                'Phân tích cơ cấu chi phí để quản lý tài chính hiệu quả',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Lưu ý quan trọng',
              [
                'Số tiền phải lớn hơn 0',
                'Nên chọn đúng danh mục để thống kê chính xác',
                'Các khoản chi tiêu ảnh hưởng đến báo cáo lợi nhuận',
                'Có thể xuất báo cáo chi tiêu chi tiết',
              ],
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đã hiểu'),
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
