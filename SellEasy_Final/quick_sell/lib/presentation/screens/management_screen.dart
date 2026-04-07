import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import 'management/orders_screen.dart';
import 'management/customers_screen.dart';
import 'management/expenses_screen.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({Key? key}) : super(key: key);

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Get the last selected management screen from ThemeProvider
    _selectedIndex = Provider.of<ThemeProvider>(context, listen: false).lastManagementScreen;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Save the selected index to ThemeProvider
    Provider.of<ThemeProvider>(context, listen: false).lastManagementScreen = index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          OrdersScreen(),
          CustomersScreen(),
          ExpensesScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBar.item(
            icon: Icon(Icons.receipt),
            label: 'Đơn hàng',
          ),
          BottomNavigationBar.item(
            icon: Icon(Icons.people),
            label: 'Khách hàng',
          ),
          BottomNavigationBar.item(
            icon: Icon(Icons.money_off),
            label: 'Chi tiêu',
          ),
        ],
      ),
    );
  }
}
