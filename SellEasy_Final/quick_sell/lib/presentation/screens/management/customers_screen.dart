import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../data/models/customer_model.dart';
import 'customer_detail_screen.dart';
import 'add_customer_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({Key? key}) : super(key: key);

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'name_asc';
  
  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCustomers() async {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    await customerProvider.loadCustomers();
  }
  
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sắp xếp theo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('name_asc', 'Tên (A-Z)'),
            _buildSortOption('name_desc', 'Tên (Z-A)'),
            _buildSortOption('debt_asc', 'Nợ (Thấp - Cao)'),
            _buildSortOption('debt_desc', 'Nợ (Cao - Thấp)'),
          ],
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
  
  Widget _buildSortOption(String value, String label) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _sortBy,
      onChanged: (value) {
        setState(() {
          _sortBy = value!;
        });
        final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
        customerProvider.sortCustomers(value!);
        Navigator.pop(context);
      },
    );
  }
  
  void _navigateToCustomerDetail(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customerId: customer.id!),
      ),
    ).then((_) => _loadCustomers());
  }
  
  void _navigateToAddCustomer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCustomerScreen(),
      ),
    ).then((_) => _loadCustomers());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khách hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: 'Sắp xếp',
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
                hintText: 'Tìm kiếm khách hàng...',
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
                          final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
                          customerProvider.searchCustomers('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
                customerProvider.searchCustomers(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, customerProvider, child) {
                if (customerProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (customerProvider.error.isNotEmpty) {
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
                          customerProvider.error,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        ElevatedButton(
                          onPressed: () {
                            customerProvider.clearError();
                            _loadCustomers();
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                
                final customers = customerProvider.filteredCustomers;
                
                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people,
                          size: ResponsiveUtils.getAdaptiveIconSize(context, 64),
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        Text(
                          'Không tìm thấy khách hàng nào',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        ElevatedButton.icon(
                          onPressed: _navigateToAddCustomer,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm khách hàng'),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _loadCustomers,
                  child: ListView.separated(
                    padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    itemCount: customers.length,
                    separatorBuilder: (context, index) => SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                    ),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return _buildCustomerItem(customer);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCustomer,
        child: const Icon(Icons.add),
        tooltip: 'Thêm khách hàng',
      ),
    );
  }
  
  Widget _buildCustomerItem(Customer customer) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToCustomerDetail(customer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          child: Row(
            children: [
              Container(
                width: ResponsiveUtils.getAdaptiveWidth(context, 50),
                height: ResponsiveUtils.getAdaptiveWidth(context, 50),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 20),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                    if (customer.phone != null && customer.phone!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                          Text(
                            customer.phone!,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    if (customer.email != null && customer.email!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                            Text(
                              customer.email!,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (customer.debt > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Nợ',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      StringUtils.formatCurrency(customer.debt),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
