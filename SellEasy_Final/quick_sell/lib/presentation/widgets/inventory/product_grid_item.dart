import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../data/models/product_model.dart';
import '../../../core/constants/app_constants.dart';

class ProductGridItem extends StatelessWidget {
  final Product product;
  final Function(Product) onTap;

  const ProductGridItem({
    Key? key,
    required this.product,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = product.getStatus();
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => onTap(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image or placeholder
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: product.imagePath != null && product.imagePath!.isNotEmpty
                      ? Image.file(
                          File(product.imagePath!),
                          width: double.infinity,
                          height: ResponsiveUtils.getAdaptiveHeight(context, 120),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
                        )
                      : _buildPlaceholder(context),
                ),
                // Status badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                      vertical: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 10),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Product info
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                  Text(
                    StringUtils.formatCurrency(product.sellPrice),
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: ResponsiveUtils.getAdaptiveIconSize(context, 14),
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                      Text(
                        'SL: ${product.quantity} ${product.unit}',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                          color: Colors.grey[600],
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
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: ResponsiveUtils.getAdaptiveHeight(context, 120),
      color: Colors.grey[200],
      child: Icon(
        Icons.image,
        size: ResponsiveUtils.getAdaptiveIconSize(context, 48),
        color: Colors.grey[400],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.productStatusInStock:
        return Colors.green;
      case AppConstants.productStatusLowStock:
        return Colors.orange;
      case AppConstants.productStatusOutOfStock:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.productStatusInStock:
        return 'Còn hàng';
      case AppConstants.productStatusLowStock:
        return 'Sắp hết';
      case AppConstants.productStatusOutOfStock:
        return 'Hết hàng';
      default:
        return 'Không xác định';
    }
  }
}
