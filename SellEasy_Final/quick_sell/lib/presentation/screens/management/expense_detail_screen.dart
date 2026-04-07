import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../data/models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/custom_button.dart';
import 'edit_expense_screen.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final int expenseId;

  const ExpenseDetailScreen({
    Key? key,
    required this.expenseId,
  }) : super(key: key);

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  late Future<Expense?> _expenseFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExpense();
  }

  Future<void> _loadExpense() async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    _expenseFuture = expenseProvider.getExpenseById(widget.expenseId);
  }

  void _showDeleteConfirmation(Expense expense) {
    DialogHelper.showConfirmDialog(
      context: context,
      title: 'Xóa chi tiêu',
      content: 'Bạn có chắc chắn muốn xóa chi tiêu này không?',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
    ).then((confirmed) {
      if (confirmed == true) {
        _deleteExpense(expense);
      }
    });
  }

  Future<void> _deleteExpense(Expense expense) async {
    setState(() {
      _isLoading = true;
    });

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final success = await expenseProvider.deleteExpense(expense.id!);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        DialogHelper.showSuccessToast(
          context: context,
          message: 'Đã xóa chi tiêu thành công',
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        DialogHelper.showErrorToast(
          context: context,
          message: 'Không thể xóa chi tiêu: ${expenseProvider.error}',
        );
      }
    }
  }

  void _navigateToEditExpense(Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseScreen(expense: expense),
      ),
    ).then((_) {
      _loadExpense();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết chi tiêu'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Expense?>(
              future: _expenseFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đã xảy ra lỗi',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _loadExpense();
                            });
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final expense = snapshot.data;
                if (expense == null) {
                  return Center(
                    child: Text(
                      'Không tìm thấy chi tiêu',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Expense header
                      Container(
                        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        color: Colors.red.withOpacity(0.1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: ResponsiveUtils.getAdaptiveWidth(context, 60),
                                  height: ResponsiveUtils.getAdaptiveWidth(context, 60),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _getCategoryIcon(expense.category),
                                      size: ResponsiveUtils.getAdaptiveIconSize(context, 32),
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense.category,
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                                      Text(
                                        StringUtils.formatDate(expense.date),
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  StringUtils.formatCurrency(expense.amount),
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Action buttons
                      Padding(
                        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomButton(
                              icon: Icons.edit,
                              label: 'Sửa',
                              onPressed: () => _navigateToEditExpense(expense),
                              color: Colors.blue,
                            ),
                            SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            CustomButton(
                              icon: Icons.delete,
                              label: 'Xóa',
                              onPressed: () => _showDeleteConfirmation(expense),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),

                      // Description
                      if (expense.description != null && expense.description!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mô tả',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  expense.description!,
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tiền thuê':
        return Icons.home;
      case 'Điện nước':
        return Icons.electric_bolt;
      case 'Lương':
        return Icons.people;
      case 'Vận chuyển':
        return Icons.local_shipping;
      default:
        return Icons.money_off;
    }
  }
}
