import 'package:flutter/material.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

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
              context,
              'Thêm sản phẩm vào đơn',
              [
                'Nhấn "Thêm sản phẩm" để chọn từ kho',
                'Nhấn "Nhập hàng mới" để thêm sản phẩm mới',
                'Nhấn "Thêm tạm thời" để thêm sản phẩm không có trong kho',
                'Điều chỉnh số lượng bằng nút + và -',
                'Nhấn biểu tượng xóa để loại bỏ sản phẩm khỏi đơn',
              ],
            ),
            const Divider(),
            _buildSection(
              context,
              'Thông tin khách hàng và thanh toán',
              [
                'Nhập tên khách hàng hoặc chọn từ danh sách',
                'Nhấn "Thêm khách hàng" để tạo khách hàng mới',
                'Nhập số tiền khách trả để tính tiền thối/công nợ',
                'Chọn phương thức thanh toán (tiền mặt, chuyển khoản...)',
                'Chọn hình thức giao hàng (lấy tại cửa hàng, giao hàng)',
              ],
            ),
            const Divider(),
            _buildSection(
              context,
              'Tùy chỉnh đơn hàng',
              [
                'Nhấn nút "Tùy chọn" để mở các tùy chỉnh nâng cao',
                'Thêm giảm giá cho đơn hàng (% hoặc số tiền)',
                'Thêm thuế cho đơn hàng (% trên tổng tiền)',
                'Thêm phí vận chuyển nếu có',
                'Thêm ghi chú cho đơn hàng',
              ],
            ),
            const Divider(),
            _buildSection(
              context,
              'Hoàn tất đơn hàng',
              [
                'Nhấn "Hoàn tất" để lưu đơn và trừ kho',
                'Nhấn "Đơn khác" để lưu đơn và tạo đơn mới',
                'Nhấn "Hủy" để hủy đơn và không trừ kho',
                'Trạng thái đơn: "Hoàn tất" hoặc "Còn nợ" tùy vào thanh toán',
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

  Widget _buildSection(BuildContext context, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
      ],
    );
  }
}
