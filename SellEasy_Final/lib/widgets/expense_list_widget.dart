import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/database_helper.dart';
import '../utils/format_utils.dart';
import '../utils/toast_helper.dart';
import 'expense_detail_dialog.dart';

class ExpenseListWidget extends StatefulWidget {
  final String timeRange;
  final String selectedYear;
  final String expenseType;

  const ExpenseListWidget({
    super.key,
    required this.timeRange,
    required this.selectedYear,
    required this.expenseType,
  });

  @override
  State<ExpenseListWidget> createState() => _ExpenseListWidgetState();
}

class _ExpenseListWidgetState extends State<ExpenseListWidget> {
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _filteredExpenses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void didUpdateWidget(ExpenseListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRange != widget.timeRange ||
        oldWidget.selectedYear != widget.selectedYear ||
        oldWidget.expenseType != widget.expenseType) {
      _loadExpenses();
    }
  }

  Future<void> _loadExpenses() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final expenses = await DatabaseHelper.instance.getExpenses();

      if (mounted) {
        setState(() {
          _expenses = expenses;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading expenses: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ToastHelper.showError(
            context, 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.');
      }
    }
  }

  void _applyFilters() {
    final now = DateTime.now();
    final filteredExpenses = _expenses.where((expense) {
      final expenseDate = DateTime.parse(expense['date']);
      final isInTimeRange = widget.timeRange == 'today'
          ? expenseDate.year == now.year &&
              expenseDate.month == now.month &&
              expenseDate.day == now.day
          : widget.timeRange == 'week'
              ? expenseDate.isAfter(now.subtract(const Duration(days: 7)))
              : expenseDate.year == now.year && expenseDate.month == now.month;

      final isInYear = expenseDate.year.toString() == widget.selectedYear;

      final matchesType = widget.expenseType == 'all'
          ? true
          : expense['category'] == widget.expenseType;

      return isInTimeRange && isInYear && matchesType;
    }).toList();

    setState(() {
      _filteredExpenses = filteredExpenses;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredExpenses.length,
          itemBuilder: (context, index) {
            final expense = _filteredExpenses[index];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          ExpenseDetailDialog(expense: expense),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense['description'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              expense['date'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatCurrency(expense['amount']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            Text(
                              expense['category'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (_filteredExpenses.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Không có chi tiêu nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng chi:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                formatCurrency(_filteredExpenses.fold(
                    0.0, (sum, expense) => sum + expense['amount'])),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
