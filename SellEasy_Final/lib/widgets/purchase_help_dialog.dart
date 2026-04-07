import 'package:flutter/material.dart';

class PurchaseHelpDialog extends StatelessWidget {
  const PurchaseHelpDialog({super.key});

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
              'Hướng dẫn nhập hàng',
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
              'Thông tin sản phẩm',
              [
                'Điền tên sản phẩm vào trường bắt buộc',
                'Nhập mã sản phẩm hoặc để hệ thống tự động tạo',
                'Nhập số lượng nhập vào kho',
                'Nhập giá vốn (giá nhập) của sản phẩm',
                'Nhập giá bán để tính lợi nhuận',
                'Chọn đơn vị tính cho sản phẩm (cái, hộp, kg...)',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Hình ảnh và thông tin bổ sung',
              [
                'Nhấn vào biểu tượng máy ảnh để chụp ảnh sản phẩm',
                'Nhấn vào biểu tượng thư viện để chọn ảnh có sẵn',
                'Nhập thông tin nhà cung cấp nếu có',
                'Thêm ghi chú về sản phẩm hoặc đơn nhập hàng',
                'Thêm các thuộc tính tùy chỉnh cho sản phẩm',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Hoàn tất nhập hàng',
              [
                'Nhấn nút "Lưu" để lưu sản phẩm và quay lại',
                'Nhấn "Nhập hàng khác" để lưu và tiếp tục nhập sản phẩm mới',
                'Sản phẩm sẽ được thêm vào kho và sẵn sàng để bán',
                'Có thể chỉnh sửa sản phẩm sau khi đã nhập vào kho',
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Lưu ý quan trọng',
              [
                'Giá vốn và giá bán phải lớn hơn 0',
                'Số lượng nhập phải là số nguyên dương',
                'Tên sản phẩm là trường bắt buộc duy nhất',
                'Các trường khác có thể điền sau nếu cần',
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
