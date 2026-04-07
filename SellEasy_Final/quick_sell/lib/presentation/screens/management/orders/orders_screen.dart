import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../widgets/management/order_list_item.dart';

class OrdersScreen extends StatefulWidget {
  final VoidCallback onBack;

  const OrdersScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoading = true;
  bool _isDialOpen = false;
  List<Map<String, dynamic>> _orders = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'Tất cả';
  String _sortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    // Giả lập tải dữ liệu
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    setState(() {
      _orders = [
        {
          'id': 1,
          'date': '2025-04-21 08:30:00',
          'customer_name': 'Nguyễn Văn A',
          'total': 850000.0,
          'paid': 850000.0,
          'debt': 0.0,
          'status': 'Hoàn thành',
          'items_count': 3,
        },
        {
          'id': 2,
          'date': '2025-04-21 10:15:00',
          'customer_name': 'Trần Thị B',
          'total': 450000.0,
          'paid': 450000.0,
          'debt': 0.0,
          'status': 'Hoàn thành',
          'items_count': 2,
        },
        {
          'id': 3,
          'date': '2025-04-21 11:45:00',
          'customer_name': 'Lê Văn C',
          'total': 1200000.0,
          'paid': 600000.0,
          'debt': 600000.0,
          'status': 'Đang xử lý',
          'items_count': 4,
        },
        {
          'id': 4,
          'date': '2025-04-20 15:30:00',
          'customer_name': 'Phạm Thị D',
          'total': 750000.0,
          'paid': 750000.0,
          'debt': 0.0,
          'status': 'Hoàn thành',
          'items_count': 2,
        },
        {
          'id': 5,
          'date': '2025-04-20 09:15:00',
          'customer_name': 'Hoàng Văn E',
          'total': 1500000.0,
          'paid': 0.0,
          'debt': 1500000.0,
          'status': 'Chưa thanh toán',
          'items_count': 5,
        },
      ];
      
      _isLoading = false;
    });
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _isLoading = true;
    });
    await _loadOrders();
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    return _orders.where((order) {
      // Lọc theo tìm kiếm
      final nameMatch = order['customer_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final idMatch = order['id'].toString().contains(_searchQuery);
      final searchMatch = nameMatch || idMatch;
      
      // Lọc theo trạng thái
      final statusMatch = _filterStatus == 'Tất cả' || order['status'] == _filterStatus;
      
      return searchMatch && statusMatch;
    }).toList()..sort((a, b) {
      // Sắp xếp
      switch (_sortBy) {
        case 'date_asc':
          return a['date'].toString().compareTo(b['date'].toString());
        case 'date_desc':
          return b['date'].toString().compareTo(a['date'].toString());
        case 'total_asc':
          return (a['total'] as double).compareTo(b['total'] as double);
        case 'total_desc':
          return (b['total'] as double).compareTo(a['total'] as double);
        default:
          return b['date'].toString().compareTo(a['date'].toString());
      }
    });
  }

  void _showFilterDialog() {
    final statusOptions = ['Tất cả', 'Hoàn thành', 'Đang xử lý', 'Chưa thanh toán'];
    final sortOptions = [
      {'value': 'date_desc', 'label': 'Mới nhất'},
      {'value': 'date_asc', 'label': 'Cũ nhất'},
      {'value': 'total_desc', 'label': 'Giá trị cao nhất'},
      {'value': 'total_asc', 'label': 'Giá trị thấp nhất'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                    'Lọc đơn hàng',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  Text(
                    'Trạng thái',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                  Wrap(
                    spacing: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                    children: statusOptions.map((status) {
                      return ChoiceChip(
                        label: Text(status),
                        selected: _filterStatus == status,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _filterStatus = status;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  Text(
                    'Sắp xếp theo',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                  Wrap(
                    spacing: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                    children: sortOptions.map((option) {
                      return ChoiceChip(
                        label: Text(option['label'] as String),
                        selected: _sortBy == option['value'],
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _sortBy = option['value'] as String;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Hủy'),
                      ),
                      SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                      FilledButton(
                        onPressed: () {
                          this.setState(() {
                            // Áp dụng bộ lọc
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Áp dụng'),
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

  void _showOrderDetails(Map<String, dynamic> order) {
    // TODO: Implement order details dialog
    DialogHelper.showToast(
      context: context,
      message: 'Chi tiết đơn hàng: ${order['id']}',
    );
  }

  void _createNewOrder() {
    // TODO: Implement create new order
    DialogHelper.showToast(
      context: context,
      message: 'Tạo đơn hàng mới',
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _getFilteredOrders();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng'),
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
                    hintText: 'Tìm kiếm đơn hàng',
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
                        'Hiển thị ${filteredOrders.length} đơn hàng',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showFilterDialog,
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Lọc'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Order list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            Text(
                              'Không tìm thấy đơn hàng',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshOrders,
                        child: ListView.builder(
                          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            return OrderListItem(
                              order: order,
                              onTap: () => _showOrderDetails(order),
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
            child: Icon(Icons.add_circle_outline,
                size: ResponsiveUtils.getAdaptiveIconSize(
                    context, 24)),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Tạo đơn hàng',
            labelStyle: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                    context, 16)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getAdaptiveSpacing(context, 8)),
            ),
            onTap: _createNewOrder,
          ),
        ],
      ),
    );
  }
}
