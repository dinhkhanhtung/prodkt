import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/customer_provider.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({Key? key}) : super(key: key);

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _debtController = TextEditingController(text: '0');
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _debtController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final address = _addressController.text.trim();
      final debt = double.parse(_debtController.text.trim().replaceAll('.', ''));

      final customer = Customer(
        name: name,
        normalizedName: StringUtils.normalize(name),
        phone: phone.isNotEmpty ? phone : null,
        email: email.isNotEmpty ? email : null,
        address: address.isNotEmpty ? address : null,
        debt: debt,
        createdAt: StringUtils.getCurrentDate(),
      );

      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final success = await customerProvider.addCustomer(customer);

      if (success) {
        if (mounted) {
          DialogHelper.showSuccessToast(
            context: context,
            message: 'Đã thêm khách hàng thành công',
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          DialogHelper.showErrorToast(
            context: context,
            message: 'Không thể thêm khách hàng: ${customerProvider.error}',
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
        title: const Text('Thêm khách hàng'),
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
                    // Customer name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên khách hàng *',
                        hintText: 'Nhập tên khách hàng',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên khách hàng';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    
                    // Phone number
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        hintText: 'Nhập số điện thoại',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Nhập email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          // Simple email validation
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Email không hợp lệ';
                          }
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    
                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ',
                        hintText: 'Nhập địa chỉ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    
                    // Debt
                    TextFormField(
                      controller: _debtController,
                      decoration: const InputDecoration(
                        labelText: 'Công nợ ban đầu',
                        hintText: 'Nhập công nợ ban đầu',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                        prefixText: '₫ ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập công nợ';
                        }
                        if (double.tryParse(value.replaceAll('.', '')) == null) {
                          return 'Công nợ không hợp lệ';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          // Format the price with thousand separators
                          final numericValue = value.replaceAll('.', '');
                          if (numericValue.isNotEmpty) {
                            final formattedValue = StringUtils.formatNumber(double.parse(numericValue));
                            _debtController.value = TextEditingValue(
                              text: formattedValue,
                              selection: TextSelection.collapsed(offset: formattedValue.length),
                            );
                          }
                        }
                      },
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 32)),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveCustomer,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Lưu khách hàng',
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
