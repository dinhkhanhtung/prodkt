import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../widgets/overview/overview_summary_card.dart';
import '../../widgets/overview/recent_orders_card.dart';
import '../../widgets/overview/top_products_card.dart';
import '../../widgets/overview/inventory_status_card.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _summaryData = {};
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _inventoryStatus = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Giả lập tải dữ liệu
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    setState(() {
      _summaryData = {
        'today_sales': 2500000.0,
        'today_orders': 5,
        'today_profit': 750000.0,
        'week_sales': 15000000.0,
        'week_orders': 32,
        'week_profit': 4500000.0,
        'month_sales': 45000000.0,
        'month_orders': 120,
        'month_profit': 13500000.0,
      };
      
      _recentOrders = [
        {
          'id': 1,
          'date': '2025-04-21 08:30:00',
          'customer_name': 'Nguyễn Văn A',
          'total': 850000.0,
          'status': 'Hoàn thành',
        },
        {
          'id': 2,
          'date': '2025-04-21 10:15:00',
          'customer_name': 'Trần Thị B',
          'total': 450000.0,
          'status': 'Hoàn thành',
        },
        {
          'id': 3,
          'date': '2025-04-21 11:45:00',
          'customer_name': 'Lê Văn C',
          'total': 1200000.0,
          'status': 'Đang xử lý',
        },
      ];
      
      _topProducts = [
        {
          'id': 1,
          'name': 'Áo thun nam',
          'sold_quantity': 25,
          'revenue': 3750000.0,
          'profit': 1250000.0,
        },
        {
          'id': 2,
          'name': 'Quần jean nữ',
          'sold_quantity': 18,
          'revenue': 5400000.0,
          'profit': 1800000.0,
        },
        {
          'id': 3,
          'name': 'Giày thể thao',
          'sold_quantity': 12,
          'revenue': 6000000.0,
          'profit': 2400000.0,
        },
      ];
      
      _inventoryStatus = [
        {
          'id': 1,
          'name': 'Áo thun nam',
          'quantity': 45,
          'status': 'Đủ hàng',
        },
        {
          'id': 2,
          'name': 'Quần jean nữ',
          'quantity': 8,
          'status': 'Sắp hết',
        },
        {
          'id': 3,
          'name': 'Giày thể thao',
          'quantity': 3,
          'status': 'Sắp hết',
        },
        {
          'id': 4,
          'name': 'Áo khoác',
          'quantity': 0,
          'status': 'Hết hàng',
        },
      ];
      
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng quan',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 24),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  OverviewSummaryCard(data: _summaryData),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  RecentOrdersCard(orders: _recentOrders),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  TopProductsCard(products: _topProducts),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  InventoryStatusCard(products: _inventoryStatus),
                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                ],
              ),
            ),
    );
  }
}
