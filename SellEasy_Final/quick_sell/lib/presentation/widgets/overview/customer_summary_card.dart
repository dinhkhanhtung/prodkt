import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';

class CustomerSummaryCard extends StatelessWidget {
  final int totalCustomers;
  final int customersWithDebt;
  final double totalDebt;
  final VoidCallback onTap;

  const CustomerSummaryCard({
    Key? key,
    required this.totalCustomers,
    required this.customersWithDebt,
    required this.totalDebt,
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
                    'Khách hàng',
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
                      'Tổng khách hàng',
                      totalCustomers.toString(),
                      Icons.people,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Khách nợ',
                      customersWithDebt.toString(),
                      Icons.account_balance_wallet,
                      Colors.orange,
                      showWarning: customersWithDebt > 0,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              _buildInfoItem(
                context,
                'Tổng công nợ',
                StringUtils.formatCurrency(totalDebt),
                Icons.money_off,
                Colors.red,
                showWarning: totalDebt > 0,
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
