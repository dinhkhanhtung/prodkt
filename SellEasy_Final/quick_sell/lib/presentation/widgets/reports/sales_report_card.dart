import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/responsive_utils.dart';

class SalesReportCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const SalesReportCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        _buildSummaryCards(context, currencyFormat),

        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),

        // Sales chart
        _buildSalesChart(context),

        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),

        // Top categories
        _buildTopCategories(context, currencyFormat),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, NumberFormat currencyFormat) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            'Tổng doanh thu',
            currencyFormat.format(data['total_sales']),
            Icons.monetization_on,
            Colors.green,
          ),
        ),
        SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Số đơn hàng',
            data['total_orders'].toString(),
            Icons.receipt_long,
            Colors.blue,
          ),
        ),
        SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Giá trị trung bình',
            currencyFormat.format(data['average_order_value']),
            Icons.trending_up,
            Colors.purple,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.getAdaptiveSpacing(context, 12),
        ),
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
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(
                        context,
                        12,
                      ),
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

  Widget _buildSalesChart(BuildContext context) {
    final chartData = data['chart_data'] as List<dynamic>;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.getAdaptiveSpacing(context, 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biểu đồ doanh thu',
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: _bottomTitleWidgets,
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _createSpots(chartData),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategories(
    BuildContext context,
    NumberFormat currencyFormat,
  ) {
    final topCategories = data['top_categories'] as List<dynamic>;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.getAdaptiveSpacing(context, 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danh mục bán chạy',
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            ...topCategories.map((category) {
              final name = category['name'] as String;
              final value = category['value'] as double;
              final totalSales = data['total_sales'] as double;
              final percentage = (value / totalSales * 100).toStringAsFixed(1);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                              context,
                              14,
                            ),
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                              context,
                              14,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                    ),
                    LinearProgressIndicator(
                      value: value / totalSales,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                    ),
                    Text(
                      currencyFormat.format(value),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(
                          context,
                          12,
                        ),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _createSpots(List<dynamic> chartData) {
    final List<FlSpot> spots = [];

    for (int i = 0; i < chartData.length; i++) {
      final item = chartData[i];
      spots.add(
        FlSpot(i.toDouble(), item['value'] / 1000000),
      ); // Convert to millions for better display
    }

    return spots;
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    if (value.toInt() >= 0 && value.toInt() < data['chart_data'].length) {
      final item = data['chart_data'][value.toInt()];
      final date = item['date'] as String;

      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          date,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
