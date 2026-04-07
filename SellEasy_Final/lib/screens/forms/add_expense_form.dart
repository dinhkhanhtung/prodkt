import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../services/database_helper.dart';
import '../../widgets/expense_help_dialog.dart';
import '../../utils/toast_helper.dart';
import '../../utils/responsive_utils.dart';
import '../home_screen.dart';

class AddExpenseForm extends StatefulWidget {
  const AddExpenseForm({super.key});

  @override
  State<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Khác';
  bool _isSaving = false;
  final _amountFocusNode = FocusNode();

  void _resetForm() {
    // Clear controllers first
    _amountController.clear();
    _descriptionController.clear();

    // Reset form state
    _formKey.currentState?.reset();

    // Force update UI
    setState(() {
      _selectedCategory = 'Khác';
      // Ensure amount field is completely cleared
      _amountController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      // Ensure description field is completely cleared
      _descriptionController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    });
  }

  Future<bool> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      ToastHelper.showError(context, 'Vui lòng nhập đầy đủ thông tin chi tiêu');
      return false;
    }

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll('.', ''));
      final description = _descriptionController.text;

      if (amount <= 0) {
        ToastHelper.showError(context, 'Số tiền phải lớn hơn 0');
        setState(() => _isSaving = false);
        return false;
      }

      // Check if amount is more than 10x average
      final expenses = await DatabaseHelper.instance.getExpenses();
      if (expenses.isNotEmpty) {
        final avgAmount = expenses.fold<double>(
              0,
              (sum, e) => sum + (e['amount'] as double),
            ) /
            expenses.length;

        if (amount > avgAmount * 10) {
          if (!mounted) return false;

          final shouldConfirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Xác nhận'),
              content: const Text(
                  'Số tiền này cao hơn 10 lần trung bình. Bạn có chắc chắn?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Xác nhận'),
                ),
              ],
            ),
          );

          if (shouldConfirm != true) {
            setState(() => _isSaving = false);
            return false;
          }
        }
      }

      final expense = Expense(
        date: DateTime.now(),
        description: description,
        amount: amount,
        category: _selectedCategory,
      );

      await DatabaseHelper.instance.insertExpense(expense.toMap());

      if (!mounted) return false;
      ToastHelper.showSuccess(context, 'Đã lưu chi tiêu thành công');

      setState(() => _isSaving = false);
      return true;
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return false;
      ToastHelper.showError(context, 'Lỗi: ${e.toString()}');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ghi chi tiêu',
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 20),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline,
                size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ExpenseHelpDialog(),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Danh mục *',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.category,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                labelStyle: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'Quảng cáo',
                  child: Text(
                    'Quảng cáo',
                    style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 14),
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Vận chuyển',
                  child: Text(
                    'Vận chuyển',
                    style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 14),
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Xăng xe',
                  child: Text('Xăng xe'),
                ),
                DropdownMenuItem(
                  value: 'Điện nước',
                  child: Text('Điện nước'),
                ),
                DropdownMenuItem(
                  value: 'Thuê mặt bằng',
                  child: Text('Thuê mặt bằng'),
                ),
                DropdownMenuItem(
                  value: 'Lương nhân viên',
                  child: Text('Lương nhân viên'),
                ),
                DropdownMenuItem(
                  value: 'Bao bì đóng gói',
                  child: Text('Bao bì đóng gói'),
                ),
                DropdownMenuItem(
                  value: 'Thiết bị văn phòng',
                  child: Text('Thiết bị văn phòng'),
                ),
                DropdownMenuItem(
                  value: 'Phí ngân hàng',
                  child: Text('Phí ngân hàng'),
                ),
                DropdownMenuItem(
                  value: 'Khác',
                  child: Text('Khác'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            TextFormField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              decoration: InputDecoration(
                labelText: 'Số tiền *',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                suffixText: 'đ',
                labelStyle: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số tiền';
                }
                if (double.tryParse(value.replaceAll('.', '')) == null) {
                  return 'Số tiền phải là số';
                }
                return null;
              },
              onChanged: (value) {
                if (value.isEmpty) return;

                // Remove all non-numeric characters
                String numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (numericValue.isEmpty) return;

                // Parse to number and format
                try {
                  final amount = int.parse(numericValue);
                  final formatted = amount.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]}.',
                      );

                  // Only update if the formatted value is different
                  if (formatted != value) {
                    _amountController.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                } catch (e) {
                  // If parsing fails, do nothing
                  return;
                }
              },
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Mô tả',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.description,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                labelStyle: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                ),
              ),
              maxLines: 3,
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            final success = await _saveExpense();
                            if (success && mounted) {
                              Navigator.pop(context);
                            }
                          },
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.save_outlined,
                            size: ResponsiveUtils.getAdaptiveIconSize(
                                context, 18),
                          ),
                    label: Text(
                      'Lưu',
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 14),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            final success = await _saveExpense();
                            if (success && mounted) {
                              // Ensure form is completely reset before showing success message
                              _resetForm();
                              // Focus the amount field for next entry
                              FocusScope.of(context)
                                  .requestFocus(_amountFocusNode);
                              ToastHelper.showSuccess(
                                context,
                                'Đã lưu chi tiêu. Tiếp tục ghi chi tiêu mới.',
                              );
                            }
                          },
                    icon: Icon(Icons.add_circle_outline,
                        size: ResponsiveUtils.getAdaptiveIconSize(context, 18)),
                    label: Text(
                      'Chi tiêu khác',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 32)),
            Container(
              padding: EdgeInsets.all(
                  ResponsiveUtils.getAdaptiveSpacing(context, 12)),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.orange.withAlpha(40)
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 20),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.orange[300]
                        : Colors.orange[700],
                  ),
                  SizedBox(
                      width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                  Expanded(
                    child: Text(
                      'Lưu ý: Chỉ sử dụng để ghi chép các khoản chi phí liên quan đến hàng hóa trong kho. Đây không phải là sổ theo dõi chi tiêu cá nhân.',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.orange[300]
                            : Colors.orange[900],
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 32)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.primary,
          indicatorColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.primary.withAlpha(51)
              : Colors.white.withAlpha(51),
          elevation: 2,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                  color: isDark
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white);
            }
            return TextStyle(color: isDark ? Colors.grey[400] : Colors.white70);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(
                  color: isDark
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white);
            }
            return IconThemeData(
                color: isDark ? Colors.grey[400] : Colors.white70);
          }),
        ),
        child: NavigationBar(
          selectedIndex: 1, // Reports tab selected
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            if (index != 1) {
              // If not the current tab
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    switch (index) {
                      case 0:
                        return const HomeScreen(initialPage: 0); // Inventory
                      case 2:
                        return const HomeScreen(initialPage: 2); // Settings
                      default:
                        return const HomeScreen(initialPage: 1); // Reports
                    }
                  },
                ),
              );
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory),
              selectedIcon: Icon(Icons.inventory),
              label: 'Kho Hàng',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Báo Cáo',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings),
              selectedIcon: Icon(Icons.settings),
              label: 'Cài Đặt',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Auto-focus on the amount field after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_amountFocusNode.canRequestFocus) {
        _amountFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }
}
