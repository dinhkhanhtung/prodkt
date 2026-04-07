import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../widgets/management/customer_list_item.dart';

class CustomersScreen extends StatefulWidget {
  final VoidCallback onBack;

  const CustomersScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  bool _isLoading = true;
  bool _isDialOpen = false;
  List<Map<String, dynamic>> _customers = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
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
    // Giả lập tải dữ liệu
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    setState(() {
      _customers = [
        {
          'id': 1,
          'name': 'Nguyễn Văn A',
          'phone': '0901234567',
          'email': 'nguyenvana@example.com',
          'address': 'Hà Nội',
          'debt': 0.0,
          'total_orders': 5,
          'total_spent': 2500000.0,
        },
        {
          'id': 2,
          'name': 'Trần Thị B',
          'phone': '0912345678',
          'email': 'tranthib@example.com',
          'address': 'Hồ Chí Minh',
          'debt': 0.0,
          'total_orders': 3,
          'total_spent': 1500000.0,
        },
        {
          'id': 3,
          'name': 'Lê Văn C',
          'phone': '0923456789',
          'email': 'levanc@example.com',
          'address': 'Đà Nẵng',
          'debt': 600000.0,
          'total_orders': 4,
          'total_spent': 3000000.0,
        },
        {
          'id': 4,
          'name': 'Phạm Thị D',
          'phone': '0934567890',
          'email': 'phamthid@example.com',
          'address': 'Hải Phòng',
          'debt': 0.0,
          'total_orders': 2,
          'total_spent': 1200000.0,
        },
        {
          'id': 5,
          'name': 'Hoàng Văn E',
          'phone': '0945678901',
          'email': 'hoangvane@example.com',
          'address': 'Cần Thơ',
          'debt': 1500000.0,
          'total_orders': 6,
          'total_spent': 4500000.0,
        },
      ];
      
      _isLoading = false;
    });
  }

  Future<void> _refreshCustomers() async {
    setState(() {
      _isLoading = true;
    });
    await _loadCustomers();
  }

  List<Map<String, dynamic>> _getFilteredCustomers() {
    return _customers.where((customer) {
      // Lọc theo tìm kiếm
      final nameMatch = customer['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final phoneMatch = customer['phone'].toString().contains(_searchQuery);
      final emailMatch = customer['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final searchMatch = nameMatch || phoneMatch || emailMatch;
      
      return searchMatch;
    }).toList()..sort((a, b) {
      // Sắp xếp
      switch (_sortBy) {
        case 'name_asc':
          return a['name'].toString().compareTo(b['name'].toString());
        case 'name_desc':
          return b['name'].toString().compareTo(a['name'].toString());
        case 'total_spent_asc':
          return (a['total_spent'] as double).compareTo(b['total_spent'] as double);
        case 'total_spent_desc':
          return (b['total_spent'] as double).compareTo(a['total_spent'] as double);
        case 'total_orders_asc':
          return (a['total_orders'] as int).compareTo(b['total_orders'] as int);
        case 'total_orders_desc':
          return (b['total_orders'] as int).compareTo(a['total_orders'] as int);
        default:
          return a['name'].toString().compareTo(b['name'].toString());
      }
    });
  }

  void _showSortDialog() {
    final sortOptions = [
      {'value': 'name_asc', 'label': 'Tên (A-Z)'},
      {'value': 'name_desc', 'label': 'Tên (Z-A)'},
      {'value': 'total_spent_desc', 'label': 'Chi tiêu nhiều nhất'},
      {'value': 'total_spent_asc', 'label': 'Chi tiêu ít nhất'},
      {'value': 'total_orders_desc', 'label': 'Nhiều đơn nhất'},
      {'value': 'total_orders_asc', 'label': 'Ít đơn nhất'},
    ];

    showModalBottomSheet(
      context: context,
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
                    'Sắp xếp khách hàng',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  ...sortOptions.map((option) {
                    return RadioListTile<String>(
                      title: Text(option['label'] as String),
                      value: option['value'] as String,
                      groupValue: _sortBy,
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                        });
                        this.setState(() {});
                      },
                    );
                  }).toList(),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Đóng'),
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

  void _showCustomerDetails(Map<String, dynamic> customer) {
    // TODO: Implement customer details dialog
    DialogHelper.showToast(
      context: context,
      message: 'Chi tiết khách hàng: ${customer['name']}',
    );
  }

  void _addNewCustomer() {
    // TODO: Implement add new customer
    DialogHelper.showToast(
      context: context,
      message: 'Thêm khách hàng mới',
    );
  }

  void _importCustomers() {
    // TODO: Implement import customers
    DialogHelper.showToast(
      context: context,
      message: 'Nhập danh sách khách hàng',
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = _getFilteredCustomers();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khách hàng'),
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
                    hintText: 'Tìm kiếm khách hàng',
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
                        'Hiển thị ${filteredCustomers.length} khách hàng',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showSortDialog,
                      icon: const Icon(Icons.sort),
                      label: const Text('Sắp xếp'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Customer list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            Text(
                              'Không tìm thấy khách hàng',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshCustomers,
                        child: ListView.builder(
                          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                          itemCount: filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = filteredCustomers[index];
                            return CustomerListItem(
                              customer: customer,
                              onTap: () => _showCustomerDetails(customer),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        spacing: ResponsiveUtils.getAdaptiveSpacing(context, 8),
        openCloseDial: ValueNotifier(_isDialOpen),
        onOpen: () => setState(() => _isDialOpen = true),
        onClose: () => setState(() => _isDialOpen = false),
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 8.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              ResponsiveUtils.getAdaptiveSpacing(context, 8)),
        ),
        children: [
          SpeedDialChild(
            child: Icon(Icons.person_add,
                size: ResponsiveUtils.getAdaptiveIconSize(
                    context, 24)),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            label: 'Thêm khách hàng',
            labelStyle: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                    context, 16)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getAdaptiveSpacing(context, 8)),
            ),
            onTap: _addNewCustomer,
          ),
          SpeedDialChild(
            child: Icon(Icons.upload_file,
                size: ResponsiveUtils.getAdaptiveIconSize(
                    context, 24)),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Nhập danh sách',
            labelStyle: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                    context, 16)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getAdaptiveSpacing(context, 8)),
            ),
            onTap: _importCustomers,
          ),
        ],
      ),
    );
  }
}
