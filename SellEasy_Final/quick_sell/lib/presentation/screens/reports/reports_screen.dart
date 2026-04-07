import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../widgets/reports/sales_report_card.dart';
import '../../widgets/reports/profit_report_card.dart';
import '../../widgets/reports/inventory_report_card.dart';
import '../../widgets/reports/expense_report_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  String _selectedPeriod = 'Tháng này';
  final List<String> _periods = ['Hôm nay', 'Tuần này', 'Tháng này', 'Năm nay', 'Tùy chọn'];
  
  Map<String, dynamic> _salesData = {};
  Map<String, dynamic> _profitData = {};
  Map<String, dynamic> _inventoryData = {};
  Map<String, dynamic> _expenseData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    // Giả lập tải dữ liệu
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    setState(() {
      // Dữ liệu báo cáo doanh thu
      _salesData = {
        'total_sales': 45000000.0,
        'total_orders': 120,
        'average_order_value': 375000.0,
        'chart_data': [
          {'date': '01/04', 'value': 1500000.0},
          {'date': '02/04', 'value': 1200000.0},
          {'date': '03/04', 'value': 1800000.0},
          {'date': '04/04', 'value': 1300000.0},
          {'date': '05/04', 'value': 1600000.0},
          {'date': '06/04', 'value': 2100000.0},
          {'date': '07/04', 'value': 1900000.0},
        ],
        'top_categories': [
          {'name': 'Áo', 'value': 18000000.0},
          {'name': 'Quần', 'value': 15000000.0},
          {'name': 'Giày', 'value': 12000000.0},
        ],
      };
      
      // Dữ liệu báo cáo lợi nhuận
      _profitData = {
        'total_profit': 13500000.0,
        'profit_margin': 30.0,
        'total_cost': 31500000.0,
        'chart_data': [
          {'date': '01/04', 'revenue': 1500000.0, 'cost': 1050000.0, 'profit': 450000.0},
          {'date': '02/04', 'revenue': 1200000.0, 'cost': 840000.0, 'profit': 360000.0},
          {'date': '03/04', 'revenue': 1800000.0, 'cost': 1260000.0, 'profit': 540000.0},
          {'date': '04/04', 'revenue': 1300000.0, 'cost': 910000.0, 'profit': 390000.0},
          {'date': '05/04', 'revenue': 1600000.0, 'cost': 1120000.0, 'profit': 480000.0},
          {'date': '06/04', 'revenue': 2100000.0, 'cost': 1470000.0, 'profit': 630000.0},
          {'date': '07/04', 'revenue': 1900000.0, 'cost': 1330000.0, 'profit': 570000.0},
        ],
        'top_products': [
          {'name': 'Giày thể thao', 'profit': 2400000.0},
          {'name': 'Quần jean nữ', 'profit': 1800000.0},
          {'name': 'Áo thun nam', 'profit': 1250000.0},
        ],
      };
      
      // Dữ liệu báo cáo tồn kho
      _inventoryData = {
        'total_products': 120,
        'total_value': 85000000.0,
        'low_stock_products': 15,
        'out_of_stock_products': 8,
        'inventory_status': [
          {'status': 'Đủ hàng', 'count': 97, 'value': 68000000.0},
          {'status': 'Sắp hết', 'count': 15, 'value': 17000000.0},
          {'status': 'Hết hàng', 'count': 8, 'value': 0.0},
        ],
        'top_value_products': [
          {'name': 'Laptop', 'quantity': 5, 'value': 25000000.0},
          {'name': 'Điện thoại', 'quantity': 8, 'value': 16000000.0},
          {'name': 'Máy tính bảng', 'quantity': 6, 'value': 12000000.0},
        ],
      };
      
      // Dữ liệu báo cáo chi tiêu
      _expenseData = {
        'total_expenses': 8500000.0,
        'chart_data': [
          {'date': '01/04', 'value': 500000.0},
          {'date': '02/04', 'value': 300000.0},
          {'date': '03/04', 'value': 800000.0},
          {'date': '04/04', 'value': 200000.0},
          {'date': '05/04', 'value': 600000.0},
          {'date': '06/04', 'value': 400000.0},
          {'date': '07/04', 'value': 700000.0},
        ],
        'expense_categories': [
          {'category': 'Tiền thuê', 'amount': 3000000.0},
          {'category': 'Lương', 'amount': 2500000.0},
          {'category': 'Vận chuyển', 'amount': 1500000.0},
          {'category': 'Điện nước', 'amount': 800000.0},
          {'category': 'Khác', 'amount': 700000.0},
        ],
      };
      
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadReportData();
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      _isLoading = true;
    });
    _loadReportData();
  }

  void _showDateRangePicker() async {
    final initialDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    
    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDateRange != null) {
      // TODO: Implement custom date range filtering
      setState(() {
        _selectedPeriod = 'Tùy chọn';
        _isLoading = true;
      });
      _loadReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Period selector
          Padding(
            padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Báo cáo',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _periods.length,
                    itemBuilder: (context, index) {
                      final period = _periods[index];
                      final isSelected = period == _selectedPeriod;
                      
                      return Padding(
                        padding: EdgeInsets.only(right: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                        child: ChoiceChip(
                          label: Text(period),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              if (period == 'Tùy chọn') {
                                _showDateRangePicker();
                              } else {
                                _changePeriod(period);
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Doanh thu'),
              Tab(text: 'Lợi nhuận'),
              Tab(text: 'Tồn kho'),
              Tab(text: 'Chi tiêu'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          
          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Sales report tab
                      RefreshIndicator(
                        onRefresh: _refreshData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                          child: SalesReportCard(data: _salesData),
                        ),
                      ),
                      
                      // Profit report tab
                      RefreshIndicator(
                        onRefresh: _refreshData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                          child: ProfitReportCard(data: _profitData),
                        ),
                      ),
                      
                      // Inventory report tab
                      RefreshIndicator(
                        onRefresh: _refreshData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                          child: InventoryReportCard(data: _inventoryData),
                        ),
                      ),
                      
                      // Expense report tab
                      RefreshIndicator(
                        onRefresh: _refreshData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                          child: ExpenseReportCard(data: _expenseData),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
