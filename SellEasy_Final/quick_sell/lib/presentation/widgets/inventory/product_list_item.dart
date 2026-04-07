import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive_utils.dart';

class ProductListItem extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const ProductListItem({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    
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
          child: Row(
            children: [
              // Product image or placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product['image_path'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product['image_path'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.grey,
                        size: 40,
                      ),
              ),
              SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 12)),
              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusChip(context, product['status']),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                    Text(
                      'Mã: ${product['code']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SL: ${product['quantity']}',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                          ),
                        ),
                        Text(
                          currencyFormat.format(product['sell_price']),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    String label;

    switch (status) {
      case 'in_stock':
        color = Colors.green;
        label = 'Còn hàng';
        break;
      case 'low_stock':
        color = Colors.orange;
        label = 'Sắp hết';
        break;
      case 'out_of_stock':
        color = Colors.red;
        label = 'Hết hàng';
        break;
      default:
        color = Colors.grey;
        label = 'Không xác định';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
