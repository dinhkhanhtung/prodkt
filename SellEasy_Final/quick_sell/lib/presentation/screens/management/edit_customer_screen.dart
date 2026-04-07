import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/customer_provider.dart';

class EditCustomerScreen extends StatefulWidget {
  final Customer customer;

  const EditCustomerScreen({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _debtController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone ?? '');
    _emailController = TextEditingController(text: widget.customer.email ?? '');
    _addressController = TextEditingController(text: widget.customer.address ?? '');
    _debtController = TextEditingController(text: StringUtils.formatNumber(widget.customer.debt));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _debtController.dispose();
    super.dispose();
  }

  Future<void> _updateCustomer() async {
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

      final updatedCustomer = widget.customer.copyWith(
        name: name,
        normalizedName: StringUtils.normalize(name),
        phone: phone.isNotEmpty ? phone : null,
        email: email.isNotEmpty ? email : null,
        address: address.isNotEmpty ? address : null,
        debt: debt,
      );

      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final success = await customerProvider.updateCustomer(updatedCustomer);

      if (success) {
        if (mounted) {
          DialogHelper.showSuccessToast(
            context: context,
            message: 'Đã cập nhật khách hàng thành công',
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          DialogHelper.showErrorToast(
            context: context,
            message: 'Không thể cập nhật khách hàng: ${customerProvider.error}',
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
        title: const Text('Sửa khách hàng'),
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
                        labelText: 'Công nợ',
                        hintText: 'Nhập công nợ',
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
                        onPressed: _updateCustomer,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cập nhật khách hàng',
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
