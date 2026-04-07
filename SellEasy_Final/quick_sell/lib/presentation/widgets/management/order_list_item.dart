import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive_utils.dart';

class OrderListItem extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const OrderListItem({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final DateTime orderDate = DateTime.parse(order['date']);
    
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getStatusColor(order['status']).withAlpha(30),
                        radius: 16,
                        child: Icon(
                          Icons.receipt,
                          color: _getStatusColor(order['status']),
                          size: 16,
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                      Text(
                        'Đơn #${order['id']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                        ),
                      ),
                    ],
                  ),
                  _buildStatusChip(context, order['status']),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['customer_name'],
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                      Text(
                        dateFormat.format(orderDate),
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(order['total']),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                      Text(
                        '${order['items_count']} sản phẩm',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (order['debt'] > 0) ...[
                SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange,
                      size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
                    ),
                    SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                    Text(
                      'Còn nợ: ${currencyFormat.format(order['debt'])}',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
        return Colors.green;
      case 'Đang xử lý':
        return Colors.blue;
      case 'Chưa thanh toán':
        return Colors.orange;
      case 'Đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
