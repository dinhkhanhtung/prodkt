import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart';
import 'orders/orders_screen.dart';
import 'customers/customers_screen.dart';
import 'expenses/expenses_screen.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  int _selectedScreen = 0;
  bool _showOptions = true;

  @override
  void initState() {
    super.initState();
    _loadLastScreen();
  }

  void _loadLastScreen() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      _selectedScreen = themeProvider.lastManagementScreen;
      _showOptions = true;
    });
  }

  void _saveSelectedScreen(int index) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.saveLastManagementScreen(index);
  }

  void _selectScreen(int index) {
    setState(() {
      _selectedScreen = index;
      _showOptions = false;
    });
    _saveSelectedScreen(index);
  }

  void _showSelectionOptions() {
    setState(() {
      _showOptions = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOptions) {
      return _buildOptionsScreen();
    } else {
      switch (_selectedScreen) {
        case AppConstants.managementOrders:
          return OrdersScreen(onBack: _showSelectionOptions);
        case AppConstants.managementCustomers:
          return CustomersScreen(onBack: _showSelectionOptions);
        case AppConstants.managementExpenses:
          return ExpensesScreen(onBack: _showSelectionOptions);
        default:
          return _buildOptionsScreen();
      }
    }
  }

  Widget _buildOptionsScreen() {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý',
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 24),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                mainAxisSpacing: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                children: [
                  _buildOptionCard(
                    title: 'Đơn hàng',
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                    onTap: () => _selectScreen(AppConstants.managementOrders),
                  ),
                  _buildOptionCard(
                    title: 'Khách hàng',
                    icon: Icons.people,
                    color: Colors.green,
                    onTap: () => _selectScreen(AppConstants.managementCustomers),
                  ),
                  _buildOptionCard(
                    title: 'Chi tiêu',
                    icon: Icons.payments,
                    color: Colors.orange,
                    onTap: () => _selectScreen(AppConstants.managementExpenses),
                  ),
                  _buildOptionCard(
                    title: 'Thống kê',
                    icon: Icons.insert_chart,
                    color: Colors.purple,
                    onTap: () {
                      // TODO: Implement statistics screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tính năng đang phát triển'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: ResponsiveUtils.getAdaptiveIconSize(context, 32),
                  color: color,
                ),
              ),
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
