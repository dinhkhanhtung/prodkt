import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../services/database_helper.dart';
import '../../utils/toast_helper.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/customer_help_dialog.dart';
import '../home_screen.dart';

class AddCustomerForm extends StatefulWidget {
  const AddCustomerForm({super.key});

  @override
  State<AddCustomerForm> createState() => _AddCustomerFormState();
}

class _AddCustomerFormState extends State<AddCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _nameFocusNode = FocusNode();

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      await DatabaseHelper.instance.insertCustomer({
        'name': _nameController.text,
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'address':
            _addressController.text.isEmpty ? null : _addressController.text,
        'normalized_name': _nameController.text.toLowerCase(),
      });

      if (mounted) {
        Navigator.pop(context);
        ToastHelper.showSuccess(context, 'Đã lưu khách hàng');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thêm khách hàng',
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
                builder: (context) => const CustomerHelpDialog(),
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
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              decoration: InputDecoration(
                labelText: 'Tên khách hàng *',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.person,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                labelStyle: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên khách hàng';
                }
                return null;
              },
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                border: const OutlineInputBorder(),
                helperText: 'Khuyến khích nhập để liên hệ',
                prefixIcon: Icon(Icons.phone,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                labelStyle: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                ),
                helperStyle: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.email,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                labelStyle: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Địa chỉ',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                labelStyle: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                ),
              ),
              maxLines: 2,
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.cancel_outlined,
                      size: ResponsiveUtils.getAdaptiveIconSize(context, 18),
                    ),
                    label: Text(
                      'Hủy',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 14),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                    width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saveCustomer,
                    icon: Icon(
                      Icons.save_outlined,
                      size: ResponsiveUtils.getAdaptiveIconSize(context, 18),
                    ),
                    label: Text(
                      'Lưu',
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
          selectedIndex: 2, // Settings tab selected
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            if (index != 2) {
              // If not the current tab
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return HomeScreen(initialPage: index);
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
    // Auto-focus on the name field
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_nameFocusNode.canRequestFocus) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }
}
