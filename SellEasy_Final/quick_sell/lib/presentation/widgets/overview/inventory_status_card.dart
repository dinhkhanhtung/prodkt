import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class InventoryStatusCard extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  const InventoryStatusCard({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tình trạng kho hàng',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to inventory screen
                  },
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(product['status']).withAlpha(30),
                    child: Icon(
                      _getStatusIcon(product['status']),
                      color: _getStatusColor(product['status']),
                    ),
                  ),
                  title: Text(
                    product['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                    ),
                  ),
                  subtitle: Text(
                    'Số lượng: ${product['quantity']}',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                    ),
                  ),
                  trailing: Chip(
                    label: Text(
                      product['status'],
                      style: TextStyle(
                        color: _getStatusColor(product['status']),
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: _getStatusColor(product['status']).withAlpha(30),
                  ),
                  onTap: () {
                    // TODO: Show product details
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đủ hàng':
        return Colors.green;
      case 'Sắp hết':
        return Colors.orange;
      case 'Hết hàng':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Đủ hàng':
        return Icons.check_circle;
      case 'Sắp hết':
        return Icons.warning;
      case 'Hết hàng':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}
