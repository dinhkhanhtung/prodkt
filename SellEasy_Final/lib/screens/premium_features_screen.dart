import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/dialog_helper.dart';
import '../widgets/bank_transfer_dialog.dart';
import '../widgets/purchase_success_dialog.dart';
import '../providers/purchase_provider.dart';
import '../services/in_app_purchase_service.dart';
import '../utils/responsive_utils.dart';
import 'home_screen.dart';

class PremiumFeaturesScreen extends StatefulWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  State<PremiumFeaturesScreen> createState() => _PremiumFeaturesScreenState();
}

class _PremiumFeaturesScreenState extends State<PremiumFeaturesScreen> {
  // Biến để lưu trữ subscription
  StreamSubscription<PurchaseResult>? _purchaseSubscription;

  // Biến để lưu trữ BuildContext hiện tại
  late BuildContext _safeContext;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cập nhật context an toàn mỗi khi dependencies thay đổi
    _safeContext = context;
  }

  @override
  void dispose() {
    // Hủy đăng ký lắng nghe khi widget bị hủy
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  void _showPurchaseConfirmation(BuildContext context) {
    if (!mounted) return;

    // Cập nhật context an toàn
    _safeContext = context;

    final purchaseProvider =
        Provider.of<PurchaseProvider>(_safeContext, listen: false);

    DialogHelper.showAnimatedConfirmationDialog(
      context: _safeContext,
      title: 'Xác nhận mua hàng',
      content:
          'Bạn có chắc chắn muốn mua phiên bản Pro của SellEasy không?\n\nGiá: 50.000 VNĐ',
      confirmText: 'Mua ngay',
      cancelText: 'Hủy',
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        // Cập nhật context an toàn
        _safeContext = context;

        // Hủy subscription cũ nếu có
        _purchaseSubscription?.cancel();

        // Lắng nghe kết quả giao dịch
        _purchaseSubscription =
            purchaseProvider.purchaseResultStream.listen((result) {
          if (!mounted) return;

          // Cập nhật context an toàn
          setState(() {
            _safeContext = context;
          });

          // Đóng loading dialog nếu đang hiển thị
          final navigatorState =
              Navigator.of(_safeContext, rootNavigator: true);
          if (navigatorState.canPop()) {
            navigatorState.pop();
          }

          if (result.success) {
            // Kiểm tra xem có thông báo đã sở hữu sản phẩm không
            if (result.errorMessage != null &&
                result.errorMessage!.contains('Bạn đã sở hữu')) {
              // Hiển thị thông báo đã sở hữu
              DialogHelper.showAnimatedAlertDialog(
                context: _safeContext,
                title: 'Đã mua',
                content: result.errorMessage!,
              );
            } else {
              // Hiển thị dialog thông báo thành công
              DialogHelper.showAnimatedDialog(
                context: _safeContext,
                builder: (context) => const PurchaseSuccessDialog(),
              );
            }

            // Cập nhật lại UI
            setState(() {});
          } else {
            // Hiển thị thông báo lỗi
            DialogHelper.showAnimatedAlertDialog(
              context: _safeContext,
              title: 'Lỗi giao dịch',
              content: result.errorMessage ??
                  'Không thể hoàn tất giao dịch. Vui lòng thử lại sau.',
            );
          }
        });

        // Hiển thị loading dialog
        showDialog(
          context: _safeContext,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Đang xử lý giao dịch...'),
                ],
              ),
            );
          },
        );

        // Bắt đầu quá trình mua hàng
        purchaseProvider.buyPremium().then((started) {
          if (!mounted) return;

          // Cập nhật context an toàn
          setState(() {
            _safeContext = context;
          });

          // Nếu không thể bắt đầu quá trình mua hàng
          if (!started) {
            // Hủy đăng ký lắng nghe
            _purchaseSubscription?.cancel();
            _purchaseSubscription = null;

            // Đóng loading dialog
            final navigatorState =
                Navigator.of(_safeContext, rootNavigator: true);
            if (navigatorState.canPop()) {
              navigatorState.pop();
            }

            // Hiển thị thông báo lỗi
            DialogHelper.showAnimatedAlertDialog(
              context: _safeContext,
              title: 'Lỗi giao dịch',
              content:
                  'Không thể bắt đầu quá trình mua hàng. Vui lòng thử lại sau.',
            );
          }
          // Nếu bắt đầu thành công, chờ kết quả từ stream
        });
      }
    });
  }

  void _restorePurchases(BuildContext context) {
    if (!mounted) return;

    // Cập nhật context an toàn
    _safeContext = context;

    final purchaseProvider =
        Provider.of<PurchaseProvider>(_safeContext, listen: false);

    // Hiển thị loading dialog
    showDialog(
      context: _safeContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Đang khôi phục giao dịch...'),
            ],
          ),
        );
      },
    );

    purchaseProvider.restorePurchases().then((success) {
      if (!mounted) return;

      // Cập nhật context an toàn
      setState(() {
        _safeContext = context;
      });

      // Đóng loading dialog
      final navigatorState = Navigator.of(_safeContext, rootNavigator: true);
      if (navigatorState.canPop()) {
        navigatorState.pop();
      }

      if (success && purchaseProvider.isPremiumPurchased) {
        DialogHelper.showAnimatedDialog(
          context: _safeContext,
          builder: (context) => const PurchaseSuccessDialog(),
        );
      } else {
        DialogHelper.showAnimatedAlertDialog(
          context: _safeContext,
          title: 'Khôi phục mua hàng',
          content: 'Không tìm thấy giao dịch mua hàng nào.',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tính năng nâng cao'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding:
              EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPremiumBanner(context),
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
              _buildSupportOptions(context),
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
              _buildFeaturesList(context),
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 32)),
              _buildThankYouSection(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900] // Match exactly with appBar color
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
            } else {
              Navigator.pop(context); // Return to main settings
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

  Widget _buildPremiumBanner(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final purchaseProvider = Provider.of<PurchaseProvider>(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
            ResponsiveUtils.getAdaptiveSpacing(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: ResponsiveUtils.getAdaptiveIconSize(context, 32),
              ),
              SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 12)),
              Expanded(
                child: Text(
                  'Bất ngờ! Tất cả tính năng đã mở khóa!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 12)),
          Text(
            purchaseProvider.isPremiumPurchased
                ? 'Cảm ơn bạn đã mua phiên bản Pro! Tất cả các tính năng nâng cao đã được mở khóa.'
                : 'Cảm ơn bạn đã sử dụng SellEasy. Chúng tôi đã mở khóa tất cả các tính năng nâng cao để bạn có thể trải nghiệm đầy đủ ứng dụng.',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOptions(BuildContext context) {
    final purchaseProvider = Provider.of<PurchaseProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ủng hộ nhà phát triển',
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
        Text(
          'Nếu bạn thấy ứng dụng hữu ích, hãy ủng hộ để chúng tôi có thể phát triển thêm nhiều tính năng mới.',
          style: TextStyle(
              color: Colors.grey,
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14)),
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        // Hiển thị card khác nhau tùy thuộc vào trạng thái mua hàng
        purchaseProvider.isPremiumPurchased
            ? Card(
                child: ListTile(
                  leading: Icon(Icons.check_circle,
                      color: Colors.green,
                      size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                  title: Text('Đã mua phiên bản Pro',
                      style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(
                              context, 16))),
                  subtitle: Text('Cảm ơn bạn đã ủng hộ ứng dụng',
                      style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(
                              context, 14))),
                ),
              )
            : Card(
                child: Stack(
                  children: [
                    ListTile(
                      leading: Icon(Icons.shopping_cart,
                          color: Colors.green,
                          size:
                              ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                      title: Text('Mua hàng Google Play',
                          style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 16))),
                      subtitle: Text('Mua phiên bản Pro trên Google Play',
                          style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 14))),
                      trailing: Icon(Icons.arrow_forward_ios,
                          size:
                              ResponsiveUtils.getAdaptiveIconSize(context, 16)),
                      onTap: () => _showPurchaseConfirmation(context),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal:
                                ResponsiveUtils.getAdaptiveSpacing(context, 8),
                            vertical:
                                ResponsiveUtils.getAdaptiveSpacing(context, 2)),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getAdaptiveSpacing(context, 12)),
                        ),
                        child: Text(
                          'Khuyến nghị',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
        Card(
          child: ListTile(
            leading: Icon(Icons.account_balance,
                color: Colors.blue,
                size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
            title: Text('Chuyển khoản BIDV',
                style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getAdaptiveFontSize(context, 16))),
            subtitle: Text('Ủng hộ tùy tâm',
                style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getAdaptiveFontSize(context, 14))),
            trailing: Icon(Icons.arrow_forward_ios,
                size: ResponsiveUtils.getAdaptiveIconSize(context, 16)),
            onTap: () {
              DialogHelper.showAnimatedDialog(
                context: context,
                builder: (context) => const BankTransferDialog(),
              );
            },
          ),
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
        Card(
          child: ListTile(
            leading: Icon(Icons.restore,
                color: Colors.orange,
                size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
            title: Text('Khôi phục mua hàng',
                style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getAdaptiveFontSize(context, 16))),
            subtitle: Text('Khôi phục các giao dịch đã mua trước đó',
                style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getAdaptiveFontSize(context, 14))),
            trailing: Icon(Icons.arrow_forward_ios,
                size: ResponsiveUtils.getAdaptiveIconSize(context, 16)),
            onTap: () {
              _restorePurchases(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    final features = [
      {
        'icon': Icons.backup,
        'title': 'Sao lưu không giới hạn',
        'description':
            'Sao lưu dữ liệu không giới hạn và đồng bộ với Google Drive',
      },
      {
        'icon': Icons.analytics,
        'title': 'Báo cáo nâng cao',
        'description':
            'Xem báo cáo chi tiết về doanh thu, lợi nhuận và tồn kho',
      },
      {
        'icon': Icons.inventory_2,
        'title': 'Quản lý kho hàng nâng cao',
        'description': 'Quản lý nhiều kho hàng, theo dõi hàng tồn kho chi tiết',
      },
      {
        'icon': Icons.receipt_long,
        'title': 'Xuất hóa đơn PDF',
        'description': 'Xuất hóa đơn dưới dạng PDF và gửi qua email',
      },
      {
        'icon': Icons.people,
        'title': 'Quản lý khách hàng',
        'description':
            'Quản lý thông tin khách hàng, lịch sử mua hàng và công nợ',
      },
      {
        'icon': Icons.bar_chart,
        'title': 'Biểu đồ thống kê',
        'description':
            'Xem biểu đồ thống kê doanh thu, lợi nhuận theo thời gian',
      },
      {
        'icon': Icons.notifications,
        'title': 'Thông báo tùy chỉnh',
        'description': 'Tùy chỉnh các loại thông báo theo nhu cầu của bạn',
      },
      {
        'icon': Icons.color_lens,
        'title': 'Tùy chỉnh giao diện',
        'description': 'Tùy chỉnh màu sắc, chủ đề và giao diện ứng dụng',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Các tính năng đã mở khóa',
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        ...features.map((feature) => Card(
              margin: EdgeInsets.only(
                  bottom: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
              child: ListTile(
                leading: Icon(
                  feature['icon'] as IconData,
                  color: Theme.of(context).colorScheme.primary,
                  size: ResponsiveUtils.getAdaptiveIconSize(context, 24),
                ),
                title: Text(feature['title'] as String,
                    style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 16))),
                subtitle: Text(feature['description'] as String,
                    style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 14))),
              ),
            )),
      ],
    );
  }

  Widget _buildThankYouSection(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.favorite,
            color: Colors.red,
            size: ResponsiveUtils.getAdaptiveIconSize(context, 48),
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
          Text(
            'Cảm ơn bạn đã sử dụng SellEasy',
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
          Text(
            'Chúng tôi luôn nỗ lực để mang đến trải nghiệm tốt nhất cho bạn',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
        ],
      ),
    );
  }
}
