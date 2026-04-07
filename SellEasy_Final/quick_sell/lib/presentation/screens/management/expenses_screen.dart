import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expense_provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../data/models/expense_model.dart';
import '../../../core/constants/app_constants.dart';
import 'expense_detail_screen.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({Key? key}) : super(key: key);

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterCategory = 'Tất cả';
  
  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadExpenses() async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    await expenseProvider.loadExpenses();
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc theo danh mục'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('Tất cả'),
              ...AppConstants.defaultExpenseCategories.map(
                (category) => _buildFilterOption(category),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterOption(String category) {
    return RadioListTile<String>(
      title: Text(category),
      value: category,
      groupValue: _filterCategory,
      onChanged: (value) {
        setState(() {
          _filterCategory = value!;
        });
        final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
        expenseProvider.filterByCategory(value!);
        Navigator.pop(context);
      },
    );
  }
  
  void _navigateToExpenseDetail(Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseDetailScreen(expenseId: expense.id!),
      ),
    ).then((_) => _loadExpenses());
  }
  
  void _navigateToAddExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    ).then((_) => _loadExpenses());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiêu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Lọc chi tiêu',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm chi tiêu...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.getAdaptiveSpacing(context, 12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
                          expenseProvider.searchExpenses('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
                expenseProvider.searchExpenses(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<ExpenseProvider>(
              builder: (context, expenseProvider, child) {
                if (expenseProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (expenseProvider.error.isNotEmpty) {
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
                          expenseProvider.error,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        ElevatedButton(
                          onPressed: () {
                            expenseProvider.clearError();
                            _loadExpenses();
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                
                final expenses = expenseProvider.filteredExpenses;
                
                if (expenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.money_off,
                          size: ResponsiveUtils.getAdaptiveIconSize(context, 64),
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        Text(
                          'Không tìm thấy chi tiêu nào',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        ElevatedButton.icon(
                          onPressed: _navigateToAddExpense,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm chi tiêu'),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _loadExpenses,
                  child: ListView.separated(
                    padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    itemCount: expenses.length,
                    separatorBuilder: (context, index) => SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                    ),
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return _buildExpenseItem(expense);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExpense,
        child: const Icon(Icons.add),
        tooltip: 'Thêm chi tiêu',
      ),
    );
  }
  
  Widget _buildExpenseItem(Expense expense) {
    final categoryIcon = _getCategoryIcon(expense.category);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToExpenseDetail(expense),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          child: Row(
            children: [
              Container(
                width: ResponsiveUtils.getAdaptiveWidth(context, 50),
                height: ResponsiveUtils.getAdaptiveWidth(context, 50),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  categoryIcon,
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
                      expense.category,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                    if (expense.description != null && expense.description!.isNotEmpty)
                      Text(
                        expense.description!,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                        Text(
                          StringUtils.formatDate(expense.date),
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                StringUtils.formatCurrency(expense.amount),
                style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
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
