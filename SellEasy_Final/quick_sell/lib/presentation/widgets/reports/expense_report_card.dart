import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/responsive_utils.dart';

class ExpenseReportCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ExpenseReportCard({super.key, required this.data});

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
        // Summary card
        _buildSummaryCard(context, currencyFormat),

        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),

        // Expense chart
        _buildExpenseChart(context),

        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),

        // Expense categories
        _buildExpenseCategories(context, currencyFormat),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, NumberFormat currencyFormat) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.getAdaptiveSpacing(context, 16),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(
                ResponsiveUtils.getAdaptiveSpacing(context, 12),
              ),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payments,
                color: Colors.red,
                size: ResponsiveUtils.getAdaptiveIconSize(context, 24),
              ),
            ),
            SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng chi tiêu',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(
                        context,
                        14,
                      ),
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                  ),
                  Text(
                    currencyFormat.format(data['total_expenses']),
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(
                        context,
                        20,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseChart(BuildContext context) {
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
              'Biểu đồ chi tiêu',
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
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
                  barGroups: _createBarGroups(chartData, context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCategories(
    BuildContext context,
    NumberFormat currencyFormat,
  ) {
    final expenseCategories = data['expense_categories'] as List<dynamic>;
    final totalExpenses = data['total_expenses'] as double;

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
              'Chi tiêu theo danh mục',
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            ...expenseCategories.map((category) {
              final categoryName = category['category'] as String;
              final amount = category['amount'] as double;
              final percentage = (amount / totalExpenses * 100).toStringAsFixed(
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
                          categoryName,
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
                      value: amount / totalExpenses,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                    ),
                    Text(
                      currencyFormat.format(amount),
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

  List<BarChartGroupData> _createBarGroups(
    List<dynamic> chartData,
    BuildContext context,
  ) {
    final List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < chartData.length; i++) {
      final item = chartData[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY:
                  item['value'] /
                  100000, // Convert to hundred thousands for better display
              color: Colors.red,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return barGroups;
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
