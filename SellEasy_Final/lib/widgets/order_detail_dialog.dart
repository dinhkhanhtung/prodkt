import 'package:flutter/material.dart';
import '../utils/format_utils.dart';
import '../utils/responsive_utils.dart';

class OrderDetailDialog extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailDialog({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(38),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            // Icon đơn hàng
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.receipt_long,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Tiêu đề
            Expanded(
              child: Text(
                'Chi tiết đơn #${order['id']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Nút đóng
            IconButton(
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha(25),
              ),
            ),
          ],
        ),
      ),
      content: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveUtils.getDialogMaxWidth(context),
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                'Thông tin đơn hàng',
                [
                  _buildInfoRow(
                      'Ngày tạo:', order['date'].toString().split('T')[0]),
                  _buildInfoRow('Tổng tiền:',
                      '${FormatUtils.formatCurrency(order['total'])}đ'),
                  _buildInfoRow('Đã trả:',
                      '${FormatUtils.formatCurrency(order['paid'])}đ'),
                  _buildInfoRow('Còn nợ:',
                      '${FormatUtils.formatCurrency(order['debt'])}đ'),
                ],
              ),
              if (order['customer_name'] != null) ...[
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Thông tin khách hàng',
                  [
                    _buildInfoRow('Tên:', order['customer_name']),
                    if (order['customer_phone'] != null)
                      _buildInfoRow('SĐT:', order['customer_phone']),
                    if (order['customer_address'] != null)
                      _buildInfoRow('Địa chỉ:', order['customer_address']),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Sản phẩm',
                [
                  if (order['items'] != null)
                    ...List.from(order['items']).map((item) => Card(
                          child: ListTile(
                            title: Text(item['product_name']),
                            subtitle: Text('SL: ${item['quantity']}'),
                            trailing: Text(
                              '${FormatUtils.formatCurrency(item['price'])}đ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(15),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Center(
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIconForLabel(label),
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 80,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Ngày tạo:':
        return Icons.calendar_today;
      case 'Tổng tiền:':
        return Icons.attach_money;
      case 'Đã trả:':
        return Icons.payments;
      case 'Còn nợ:':
        return Icons.account_balance_wallet;
      case 'Tên:':
        return Icons.person;
      case 'SĐT:':
        return Icons.phone;
      case 'Địa chỉ:':
        return Icons.location_on;
      default:
        return Icons.info_outline;
    }
  }
}
