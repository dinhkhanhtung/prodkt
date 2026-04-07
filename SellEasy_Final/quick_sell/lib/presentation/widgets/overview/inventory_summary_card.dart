import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';

class InventorySummaryCard extends StatelessWidget {
  final int totalProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final double inventoryValue;
  final VoidCallback onTap;

  const InventorySummaryCard({
    Key? key,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.inventoryValue,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tồn kho',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
                    color: Colors.grey,
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Tổng sản phẩm',
                      totalProducts.toString(),
                      Icons.inventory_2,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Giá trị tồn kho',
                      StringUtils.formatCurrency(inventoryValue),
                      Icons.monetization_on,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Sắp hết hàng',
                      lowStockProducts.toString(),
                      Icons.warning_amber,
                      Colors.orange,
                      showWarning: lowStockProducts > 0,
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Hết hàng',
                      outOfStockProducts.toString(),
                      Icons.error,
                      Colors.red,
                      showWarning: outOfStockProducts > 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    bool showWarning = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
              color: color,
            ),
            SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
            Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                fontWeight: FontWeight.bold,
                color: showWarning ? color : null,
              ),
            ),
            if (showWarning) ...[
              SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
              Icon(
                Icons.warning,
                size: ResponsiveUtils.getAdaptiveIconSize(context, 14),
                color: color,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
