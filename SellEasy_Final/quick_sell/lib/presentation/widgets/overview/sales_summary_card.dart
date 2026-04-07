import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';

class SalesSummaryCard extends StatelessWidget {
  final double totalSales;
  final double totalProfit;
  final int orderCount;
  final String period;
  final VoidCallback onTap;

  const SalesSummaryCard({
    Key? key,
    required this.totalSales,
    required this.totalProfit,
    required this.orderCount,
    required this.period,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profitMargin = totalSales > 0 ? (totalProfit / totalSales * 100) : 0.0;

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
                    'Doanh số $period',
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
                      'Doanh thu',
                      StringUtils.formatCurrency(totalSales),
                      Icons.attach_money,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Lợi nhuận',
                      StringUtils.formatCurrency(totalProfit),
                      Icons.trending_up,
                      Colors.green,
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
                      'Đơn hàng',
                      orderCount.toString(),
                      Icons.shopping_cart,
                      Colors.orange,
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Tỷ suất LN',
                      '${profitMargin.toStringAsFixed(1)}%',
                      Icons.pie_chart,
                      Colors.purple,
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
    Color color,
  ) {
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
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
