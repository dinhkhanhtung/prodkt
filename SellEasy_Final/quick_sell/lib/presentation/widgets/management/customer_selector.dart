import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/customer_provider.dart';

class CustomerSelector extends StatefulWidget {
  final Customer? selectedCustomer;
  final Function(Customer?) onCustomerSelected;

  const CustomerSelector({
    Key? key,
    this.selectedCustomer,
    required this.onCustomerSelected,
  }) : super(key: key);

  @override
  State<CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends State<CustomerSelector> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredCustomers = [];
      });
    } else {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final customers = customerProvider.customers;
      
      setState(() {
        _isSearching = true;
        _filteredCustomers = customers.where((customer) {
          final nameMatch = customer.normalizedName.contains(query);
          final phoneMatch = customer.phone?.toLowerCase().contains(query) ?? false;
          return nameMatch || phoneMatch;
        }).toList();
      });
    }
  }

  void _selectCustomer(Customer customer) {
    widget.onCustomerSelected(customer);
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _filteredCustomers = [];
    });
  }

  void _clearCustomer() {
    widget.onCustomerSelected(null);
    _searchController.clear();
  }

  void _showAddCustomerDialog() {
    // TODO: Implement add customer dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm khách hàng mới'),
        content: const Text('Tính năng đang phát triển'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selectedCustomer != null)
          _buildSelectedCustomer()
        else
          _buildCustomerSearch(),
        
        if (_isSearching && _filteredCustomers.isNotEmpty)
          _buildSearchResults(),
      ],
    );
  }

  Widget _buildSelectedCustomer() {
    final customer = widget.selectedCustomer!;
    
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 12)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveUtils.getAdaptiveWidth(context, 40),
            height: ResponsiveUtils.getAdaptiveWidth(context, 40),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 12)),
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
                if (customer.phone != null && customer.phone!.isNotEmpty)
                  Text(
                    customer.phone!,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _clearCustomer,
            tooltip: 'Xóa khách hàng',
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSearch() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm khách hàng...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.getAdaptiveSpacing(context, 12),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
          ),
        ),
        SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
        ElevatedButton(
          onPressed: _showAddCustomerDialog,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 12)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: EdgeInsets.only(top: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
      constraints: BoxConstraints(
        maxHeight: ResponsiveUtils.getAdaptiveHeight(context, 200),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 8)),
        itemCount: _filteredCustomers.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final customer = _filteredCustomers[index];
          return ListTile(
            leading: Container(
              width: ResponsiveUtils.getAdaptiveWidth(context, 40),
              height: ResponsiveUtils.getAdaptiveWidth(context, 40),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            title: Text(customer.name),
            subtitle: customer.phone != null && customer.phone!.isNotEmpty
                ? Text(customer.phone!)
                : null,
            onTap: () => _selectCustomer(customer),
          );
        },
      ),
    );
  }
}
