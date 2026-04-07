import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive_utils.dart';

class TopProductsCard extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  const TopProductsCard({
    super.key,
    required this.products,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sản phẩm bán chạy',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to products screen
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
                    backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
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
                    'Đã bán: ${product['sold_quantity']} sản phẩm',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(product['revenue']),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                        ),
                      ),
                      Text(
                        'Lợi nhuận: ${currencyFormat.format(product['profit'])}',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                        ),
                      ),
                    ],
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
}
