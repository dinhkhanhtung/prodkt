import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive_utils.dart';

class CustomerListItem extends StatelessWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onTap;

  const CustomerListItem({
    super.key,
    required this.customer,
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
              // Customer avatar
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                radius: 24,
                child: Text(
                  _getInitials(customer['name']),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 12)),
              // Customer details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: ResponsiveUtils.getAdaptiveIconSize(context, 14),
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                        Text(
                          customer['phone'],
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (customer['debt'] > 0) ...[
                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                      Row(
                        children: [
                          Icon(
                            Icons.warning,
                            size: ResponsiveUtils.getAdaptiveIconSize(context, 14),
                            color: Colors.orange,
                          ),
                          SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                          Text(
                            'Nợ: ${currencyFormat.format(customer['debt'])}',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
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
              // Customer stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(customer['total_spent']),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                  Text(
                    '${customer['total_orders']} đơn hàng',
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
      ),
    );
  }

  String _getInitials(String name) {
    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts.first[0].toUpperCase();
    }
    return '?';
  }
}
