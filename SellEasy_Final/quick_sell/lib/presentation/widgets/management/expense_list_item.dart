import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive_utils.dart';

class ExpenseListItem extends StatelessWidget {
  final Map<String, dynamic> expense;
  final VoidCallback onTap;

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final DateTime expenseDate = DateTime.parse(expense['date']);
    
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
              // Category icon
              CircleAvatar(
                backgroundColor: _getCategoryColor(expense['category']).withAlpha(30),
                radius: 24,
                child: Icon(
                  _getCategoryIcon(expense['category']),
                  color: _getCategoryColor(expense['category']),
                ),
              ),
              SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 12)),
              // Expense details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense['description'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(expense['category']).withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            expense['category'],
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                              color: _getCategoryColor(expense['category']),
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                        Icon(
                          Icons.calendar_today,
                          size: ResponsiveUtils.getAdaptiveIconSize(context, 12),
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                        Text(
                          dateFormat.format(expenseDate),
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
              // Amount
              Text(
                currencyFormat.format(expense['amount']),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Tiền thuê':
        return Colors.blue;
      case 'Điện nước':
        return Colors.orange;
      case 'Lương':
        return Colors.green;
      case 'Vận chuyển':
        return Colors.purple;
      case 'Khác':
        return Colors.grey;
      default:
        return Colors.red;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tiền thuê':
        return Icons.home;
      case 'Điện nước':
        return Icons.flash_on;
      case 'Lương':
        return Icons.people;
      case 'Vận chuyển':
        return Icons.local_shipping;
      case 'Khác':
        return Icons.category;
      default:
        return Icons.payments;
    }
  }
}
