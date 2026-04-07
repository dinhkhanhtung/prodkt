import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/responsive_utils.dart';

class InventoryReportCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const InventoryReportCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        _buildSummaryCards(context, currencyFormat),
        
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        
        // Inventory status chart
        _buildInventoryStatusChart(context),
        
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        
        // Top value products
        _buildTopValueProducts(context, currencyFormat),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, NumberFormat currencyFormat) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            'Tổng sản phẩm',
            data['total_products'].toString(),
            Icons.inventory_2,
            Colors.blue,
          ),
        ),
        SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Giá trị tồn kho',
            currencyFormat.format(data['total_value']),
            Icons.monetization_on,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: ResponsiveUtils.getAdaptiveIconSize(context, 20),
                ),
                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryStatusChart(BuildContext context) {
    final inventoryStatus = data['inventory_status'] as List<dynamic>;
    
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
              'Tình trạng tồn kho',
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            Row(
              children: [
                // Pie chart
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _createPieSections(inventoryStatus),
                      ),
                    ),
                  ),
                ),
                // Legend
                Expanded(
                  flex: 3,
                  child: Column(
                    children: inventoryStatus.map((status) {
                      final statusName = status['status'] as String;
                      final count = status['count'] as int;
                      final color = _getStatusColor(statusName);
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                            Expanded(
                              child: Text(
                                statusName,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                ),
                              ),
                            ),
                            Text(
                              '$count sản phẩm',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            // Low stock and out of stock summary
            Row(
              children: [
                Expanded(
                  child: _buildAlertCard(
                    context,
                    'Sắp hết hàng',
                    data['low_stock_products'].toString(),
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                Expanded(
                  child: _buildAlertCard(
                    context,
                    'Hết hàng',
                    data['out_of_stock_products'].toString(),
                    Icons.error,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 12)),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: ResponsiveUtils.getAdaptiveIconSize(context, 24),
          ),
          SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                    color: color,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopValueProducts(BuildContext context, NumberFormat currencyFormat) {
    final topValueProducts = data['top_value_products'] as List<dynamic>;
    
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
              'Sản phẩm có giá trị tồn kho cao nhất',
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            ...topValueProducts.map((product) {
              final name = product['name'] as String;
              final quantity = product['quantity'] as int;
              final value = product['value'] as double;
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                  child: Icon(
                    Icons.inventory_2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                  ),
                ),
                subtitle: Text(
                  'Số lượng: $quantity',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                  ),
                ),
                trailing: Text(
                  currencyFormat.format(value),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _createPieSections(List<dynamic> inventoryStatus) {
    final List<PieChartSectionData> sections = [];
    
    for (int i = 0; i < inventoryStatus.length; i++) {
      final status = inventoryStatus[i];
      final statusName = status['status'] as String;
      final count = status['count'] as int;
      final totalProducts = data['total_products'] as int;
      final percentage = count / totalProducts;
      
      sections.add(
        PieChartSectionData(
          color: _getStatusColor(statusName),
          value: percentage * 100,
          title: '${(percentage * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    
    return sections;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đủ hàng':
        return Colors.green;
      case 'Sắp hết':
        return Colors.orange;
      case 'Hết hàng':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
