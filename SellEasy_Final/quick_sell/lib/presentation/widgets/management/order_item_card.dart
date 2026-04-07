import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../data/models/order_item_model.dart';
import '../../../data/models/product_model.dart';

class OrderItemCard extends StatelessWidget {
  final OrderItem item;
  final Function(OrderItem) onEdit;
  final Function(OrderItem) onDelete;
  final Function(OrderItem, bool) onExchangeToggle;

  const OrderItemCard({
    Key? key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onExchangeToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final totalPrice = item.price * item.quantity;
    
    if (product == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 12)),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Container(
                  width: ResponsiveUtils.getAdaptiveWidth(context, 60),
                  height: ResponsiveUtils.getAdaptiveWidth(context, 60),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product.imagePath != null && product.imagePath!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(product.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.image,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.image,
                          color: Colors.grey,
                        ),
                ),
                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 12)),
                
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                      Row(
                        children: [
                          Text(
                            '${StringUtils.formatCurrency(item.price)} × ${item.quantity} ${product.unit}',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                              color: Colors.grey[600],
                            ),
                          ),
                          if (item.isExchanged)
                            Container(
                              margin: EdgeInsets.only(
                                left: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                                vertical: ResponsiveUtils.getAdaptiveSpacing(context, 2),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Đổi trả',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 10),
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                      Text(
                        'Thành tiền: ${StringUtils.formatCurrency(totalPrice)}',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Actions
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => onEdit(item),
                      tooltip: 'Sửa',
                      iconSize: ResponsiveUtils.getAdaptiveIconSize(context, 20),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => onDelete(item),
                      tooltip: 'Xóa',
                      iconSize: ResponsiveUtils.getAdaptiveIconSize(context, 20),
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
            
            // Exchange toggle
            Row(
              children: [
                Checkbox(
                  value: item.isExchanged,
                  onChanged: (value) => onExchangeToggle(item, value ?? false),
                ),
                Text(
                  'Đổi trả sản phẩm',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                  ),
                ),
                const Spacer(),
                if (item.isExchanged)
                  Text(
                    'Không tính vào tồn kho',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
