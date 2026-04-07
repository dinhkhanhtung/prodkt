import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../widgets/management/expense_list_item.dart';

class ExpensesScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ExpensesScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  bool _isLoading = true;
  bool _isDialOpen = false;
  List<Map<String, dynamic>> _expenses = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterCategory = 'Tất cả';
  String _sortBy = 'date_desc';

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
    // Giả lập tải dữ liệu
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    setState(() {
      _expenses = [
        {
          'id': 1,
          'date': '2025-04-21',
          'amount': 500000.0,
          'category': 'Tiền thuê',
          'description': 'Tiền thuê cửa hàng tháng 4',
        },
        {
          'id': 2,
          'date': '2025-04-20',
          'amount': 300000.0,
          'category': 'Điện nước',
          'description': 'Tiền điện nước tháng 4',
        },
        {
          'id': 3,
          'date': '2025-04-19',
          'amount': 800000.0,
          'category': 'Lương',
          'description': 'Lương nhân viên Nguyễn Văn A',
        },
        {
          'id': 4,
          'date': '2025-04-18',
          'amount': 200000.0,
          'category': 'Vận chuyển',
          'description': 'Phí vận chuyển hàng',
        },
        {
          'id': 5,
          'date': '2025-04-17',
          'amount': 600000.0,
          'category': 'Khác',
          'description': 'Chi phí sửa chữa thiết bị',
        },
      ];
      
      _isLoading = false;
    });
  }

  Future<void> _refreshExpenses() async {
    setState(() {
      _isLoading = true;
    });
    await _loadExpenses();
  }

  List<Map<String, dynamic>> _getFilteredExpenses() {
    return _expenses.where((expense) {
      // Lọc theo tìm kiếm
      final descriptionMatch = expense['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final categoryMatch = expense['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final searchMatch = descriptionMatch || categoryMatch;
      
      // Lọc theo danh mục
      final categoryFilterMatch = _filterCategory == 'Tất cả' || expense['category'] == _filterCategory;
      
      return searchMatch && categoryFilterMatch;
    }).toList()..sort((a, b) {
      // Sắp xếp
      switch (_sortBy) {
        case 'date_asc':
          return a['date'].toString().compareTo(b['date'].toString());
        case 'date_desc':
          return b['date'].toString().compareTo(a['date'].toString());
        case 'amount_asc':
          return (a['amount'] as double).compareTo(b['amount'] as double);
        case 'amount_desc':
          return (b['amount'] as double).compareTo(a['amount'] as double);
        default:
          return b['date'].toString().compareTo(a['date'].toString());
      }
    });
  }

  void _showFilterDialog() {
    final categoryOptions = ['Tất cả', 'Tiền thuê', 'Điện nước', 'Lương', 'Vận chuyển', 'Khác'];
    final sortOptions = [
      {'value': 'date_desc', 'label': 'Mới nhất'},
      {'value': 'date_asc', 'label': 'Cũ nhất'},
      {'value': 'amount_desc', 'label': 'Giá trị cao nhất'},
      {'value': 'amount_asc', 'label': 'Giá trị thấp nhất'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lọc chi tiêu',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  Text(
                    'Danh mục',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                  Wrap(
                    spacing: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                    children: categoryOptions.map((category) {
                      return ChoiceChip(
                        label: Text(category),
                        selected: _filterCategory == category,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _filterCategory = category;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  Text(
                    'Sắp xếp theo',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                  Wrap(
                    spacing: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                    children: sortOptions.map((option) {
                      return ChoiceChip(
                        label: Text(option['label'] as String),
                        selected: _sortBy == option['value'],
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _sortBy = option['value'] as String;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Hủy'),
                      ),
                      SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                      FilledButton(
                        onPressed: () {
                          this.setState(() {
                            // Áp dụng bộ lọc
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Áp dụng'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showExpenseDetails(Map<String, dynamic> expense) {
    // TODO: Implement expense details dialog
    DialogHelper.showToast(
      context: context,
      message: 'Chi tiết chi tiêu: ${expense['description']}',
    );
  }

  void _addNewExpense() {
    // TODO: Implement add new expense
    DialogHelper.showToast(
      context: context,
      message: 'Thêm chi tiêu mới',
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _getFilteredExpenses();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiêu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm chi tiêu',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                // Filter and sort bar
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hiển thị ${filteredExpenses.length} chi tiêu',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showFilterDialog,
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Lọc'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Expense list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            Text(
                              'Không tìm thấy chi tiêu',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshExpenses,
                        child: ListView.builder(
                          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                          itemCount: filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = filteredExpenses[index];
                            return ExpenseListItem(
                              expense: expense,
                              onTap: () => _showExpenseDetails(expense),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewExpense,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
