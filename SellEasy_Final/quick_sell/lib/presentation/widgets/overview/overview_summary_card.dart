import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive_utils.dart';

class OverviewSummaryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const OverviewSummaryCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    
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
            Text(
              'Tổng quan doanh thu',
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Hôm nay',
                    currencyFormat.format(data['today_sales']),
                    '${data['today_orders']} đơn',
                    Colors.green,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Tuần này',
                    currencyFormat.format(data['week_sales']),
                    '${data['week_orders']} đơn',
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            _buildSummaryItem(
              context,
              'Tháng này',
              currencyFormat.format(data['month_sales']),
              '${data['month_orders']} đơn',
              Colors.purple,
              isWide: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String title,
    String amount,
    String subtitle,
    Color color, {
    bool isWide = false,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: isWide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isWide ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                Icons.monetization_on,
                color: color,
                size: ResponsiveUtils.getAdaptiveIconSize(context, 20),
              ),
              SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
          Text(
            amount,
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, isWide ? 24 : 18),
              fontWeight: FontWeight.bold,
            ),
            textAlign: isWide ? TextAlign.center : TextAlign.start,
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
              color: Colors.grey[600],
            ),
            textAlign: isWide ? TextAlign.center : TextAlign.start,
          ),
        ],
      ),
    );
  }
}
