import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/responsive_utils.dart';

class ProfitReportCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProfitReportCard({super.key, required this.data});

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

        // Profit chart
        _buildProfitChart(context),

        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),

        // Top products
        _buildTopProducts(context, currencyFormat),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, NumberFormat currencyFormat) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            'Tổng lợi nhuận',
            currencyFormat.format(data['total_profit']),
            Icons.trending_up,
            Colors.green,
          ),
        ),
        SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Biên lợi nhuận',
            '${data['profit_margin']}%',
            Icons.pie_chart,
            Colors.blue,
          ),
        ),
        SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Tổng chi phí',
            currencyFormat.format(data['total_cost']),
            Icons.money_off,
            Colors.red,
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
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitChart(BuildContext context) {
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
              'Biểu đồ lợi nhuận',
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
                    // Revenue line
                    LineChartBarData(
                      spots: _createRevenueSpots(chartData),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withAlpha(50),
                      ),
                    ),
                    // Cost line
                    LineChartBarData(
                      spots: _createCostSpots(chartData),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    ),
                    // Profit line
                    LineChartBarData(
                      spots: _createProfitSpots(chartData),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withAlpha(50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(context, 'Doanh thu', Colors.blue),
                SizedBox(
                  width: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                ),
                _buildLegendItem(context, 'Chi phí', Colors.red),
                SizedBox(
                  width: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                ),
                _buildLegendItem(context, 'Lợi nhuận', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
    );
  }

  Widget _buildTopProducts(BuildContext context, NumberFormat currencyFormat) {
    final topProducts = data['top_products'] as List<dynamic>;

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
              'Sản phẩm có lợi nhuận cao nhất',
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            ...topProducts.map((product) {
              final name = product['name'] as String;
              final profit = product['profit'] as double;
              final totalProfit = data['total_profit'] as double;
              final percentage = (profit / totalProfit * 100).toStringAsFixed(
                1,
              );

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
                      value: profit / totalProfit,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                    ),
                    Text(
                      currencyFormat.format(profit),
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

  List<FlSpot> _createRevenueSpots(List<dynamic> chartData) {
    final List<FlSpot> spots = [];

    for (int i = 0; i < chartData.length; i++) {
      final item = chartData[i];
      spots.add(
        FlSpot(i.toDouble(), item['revenue'] / 1000000),
      ); // Convert to millions for better display
    }

    return spots;
  }

  List<FlSpot> _createCostSpots(List<dynamic> chartData) {
    final List<FlSpot> spots = [];

    for (int i = 0; i < chartData.length; i++) {
      final item = chartData[i];
      spots.add(
        FlSpot(i.toDouble(), item['cost'] / 1000000),
      ); // Convert to millions for better display
    }

    return spots;
  }

  List<FlSpot> _createProfitSpots(List<dynamic> chartData) {
    final List<FlSpot> spots = [];

    for (int i = 0; i < chartData.length; i++) {
      final item = chartData[i];
      spots.add(
        FlSpot(i.toDouble(), item['profit'] / 1000000),
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
