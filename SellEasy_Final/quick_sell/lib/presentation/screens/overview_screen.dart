import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/order_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/overview/overview_header.dart';
import '../widgets/overview/sales_summary_card.dart';
import '../widgets/overview/inventory_summary_card.dart';
import '../widgets/overview/customer_summary_card.dart';
import '../widgets/overview/recent_orders_card.dart';
import '../widgets/overview/top_products_card.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/string_utils.dart';
import 'management/orders_screen.dart';
import 'management/customers_screen.dart';
import 'inventory/inventory_screen.dart';
import 'reports/reports_screen.dart';
import 'notifications_screen.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({Key? key}) : super(key: key);

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  bool _isLoading = true;
  String _currentDate = StringUtils.getCurrentDate();
  String _startDate = '';
  String _endDate = '';
  List<Map<String, dynamic>> _topProducts = [];

  @override
  void initState() {
    super.initState();
    _startDate = _getStartOfMonth(_currentDate);
    _endDate = _currentDate;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    await Future.wait([
      productProvider.loadProducts(),
      customerProvider.loadCustomers(),
      orderProvider.loadOrders(),
      notificationProvider.loadNotifications(),
    ]);

    // Load top products
    _topProducts = await orderProvider.getTopSellingProductsByDateRange(
      _startDate,
      _endDate,
      10,
    );

    setState(() {
      _isLoading = false;
    });
  }

  String _getStartOfMonth(String date) {
    final dateTime = DateTime.parse(date);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-01';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OverviewHeader(
                      userName: 'Admin',
                      onNotificationTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.all(
                        ResponsiveUtils.getAdaptiveSpacing(context, 16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSalesSummary(),
                          SizedBox(
                            height: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                          ),
                          _buildInventorySummary(),
                          SizedBox(
                            height: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                          ),
                          _buildCustomerSummary(),
                          SizedBox(
                            height: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                          ),
                          _buildRecentOrders(),
                          SizedBox(
                            height: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                          ),
                          _buildTopProducts(),
                          SizedBox(
                            height: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSalesSummary() {
    final orderProvider = Provider.of<OrderProvider>(context);
    
    return FutureBuilder<double>(
      future: orderProvider.getTotalSalesByDateRange(_startDate, _endDate),
      builder: (context, salesSnapshot) {
        return FutureBuilder<double>(
          future: orderProvider.getTotalProfitByDateRange(_startDate, _endDate),
          builder: (context, profitSnapshot) {
            return FutureBuilder<int>(
              future: orderProvider.getOrderCountByDateRange(_startDate, _endDate),
              builder: (context, countSnapshot) {
                final totalSales = salesSnapshot.data ?? 0.0;
                final totalProfit = profitSnapshot.data ?? 0.0;
                final orderCount = countSnapshot.data ?? 0;

                return SalesSummaryCard(
                  totalSales: totalSales,
                  totalProfit: totalProfit,
                  orderCount: orderCount,
                  period: 'tháng này',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportsScreen(),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInventorySummary() {
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products;
    final totalProducts = products.length;
    
    return FutureBuilder<List<Product>>(
      future: productProvider.getLowStockProducts(),
      builder: (context, lowStockSnapshot) {
        return FutureBuilder<List<Product>>(
          future: productProvider.getOutOfStockProducts(),
          builder: (context, outOfStockSnapshot) {
            final lowStockProducts = lowStockSnapshot.data?.length ?? 0;
            final outOfStockProducts = outOfStockSnapshot.data?.length ?? 0;
            
            // Calculate inventory value
            double inventoryValue = 0.0;
            for (final product in products) {
              inventoryValue += product.costPrice * product.quantity;
            }

            return InventorySummaryCard(
              totalProducts: totalProducts,
              lowStockProducts: lowStockProducts,
              outOfStockProducts: outOfStockProducts,
              inventoryValue: inventoryValue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InventoryScreen(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCustomerSummary() {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final customers = customerProvider.customers;
    final totalCustomers = customers.length;
    
    return FutureBuilder<List<Customer>>(
      future: customerProvider.getCustomersWithDebt(),
      builder: (context, debtSnapshot) {
        final customersWithDebt = debtSnapshot.data?.length ?? 0;
        
        // Calculate total debt
        double totalDebt = 0.0;
        for (final customer in customers) {
          totalDebt += customer.debt;
        }

        return CustomerSummaryCard(
          totalCustomers: totalCustomers,
          customersWithDebt: customersWithDebt,
          totalDebt: totalDebt,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CustomersScreen(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentOrders() {
    final orderProvider = Provider.of<OrderProvider>(context);
    final recentOrders = orderProvider.orders.take(5).toList();

    return RecentOrdersCard(
      recentOrders: recentOrders,
      onViewAll: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OrdersScreen(),
          ),
        );
      },
      onOrderTap: (order) {
        // Navigate to order details
      },
    );
  }

  Widget _buildTopProducts() {
    return TopProductsCard(
      topProducts: _topProducts,
      onViewAll: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReportsScreen(),
          ),
        );
      },
      onProductTap: (productId) {
        // Navigate to product details
      },
    );
  }
}
