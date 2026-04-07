import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../data/models/expense_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/expense_provider.dart';

class EditExpenseScreen extends StatefulWidget {
  final Expense expense;

  const EditExpenseScreen({
    Key? key,
    required this.expense,
  }) : super(key: key);

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late DateTime _selectedDate;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: StringUtils.formatNumber(widget.expense.amount));
    _descriptionController = TextEditingController(text: widget.expense.description ?? '');
    _selectedCategory = widget.expense.category;
    _selectedDate = DateTime.parse(widget.expense.date);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.trim().replaceAll('.', ''));
      final description = _descriptionController.text.trim();
      final date = StringUtils.dbDateFormat.format(_selectedDate);

      final updatedExpense = widget.expense.copyWith(
        amount: amount,
        category: _selectedCategory,
        description: description.isNotEmpty ? description : null,
        date: date,
      );

      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final success = await expenseProvider.updateExpense(updatedExpense);

      if (success) {
        if (mounted) {
          DialogHelper.showSuccessToast(
            context: context,
            message: 'Đã cập nhật chi tiêu thành công',
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          DialogHelper.showErrorToast(
            context: context,
            message: 'Không thể cập nhật chi tiêu: ${expenseProvider.error}',
          );
        }
      }
    } catch (e) {
      DialogHelper.showErrorToast(
        context: context,
        message: 'Đã xảy ra lỗi: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa chi tiêu'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền *',
                        hintText: 'Nhập số tiền',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.monetization_on),
                        prefixText: '₫ ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập số tiền';
                        }
                        if (double.tryParse(value.replaceAll('.', '')) == null) {
                          return 'Số tiền không hợp lệ';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          // Format the price with thousand separators
                          final numericValue = value.replaceAll('.', '');
                          if (numericValue.isNotEmpty) {
                            final formattedValue = StringUtils.formatNumber(double.parse(numericValue));
                            _amountController.value = TextEditingValue(
                              text: formattedValue,
                              selection: TextSelection.collapsed(offset: formattedValue.length),
                            );
                          }
                        }
                      },
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    
                    // Category
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: AppConstants.defaultExpenseCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    
                    // Date
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          StringUtils.formatDate(StringUtils.dbDateFormat.format(_selectedDate)),
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        hintText: 'Nhập mô tả chi tiêu',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 32)),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateExpense,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cập nhật chi tiêu',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
