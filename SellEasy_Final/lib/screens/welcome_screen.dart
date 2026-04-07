import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../utils/toast_helper.dart';
import '../utils/responsive_utils.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Chào mừng đến với SellEasy',
      'description': 'Ứng dụng quản lý bán hàng đơn giản và hiệu quả',
      'icon': Icons.store,
      'color': Colors.blue,
    },
    {
      'title': 'Quản lý kho hàng',
      'description':
          'Theo dõi số lượng, giá cả và thông tin sản phẩm. Nhập hàng, xuất hàng và kiểm kho dễ dàng.',
      'icon': Icons.inventory_2,
      'color': Colors.green,
    },
    {
      'title': 'Bán hàng nhanh chóng',
      'description':
          'Tạo đơn hàng nhanh chóng, tính tiền chính xác và in hóa đơn chuyên nghiệp.',
      'icon': Icons.shopping_cart,
      'color': Colors.orange,
    },
    {
      'title': 'Quản lý khách hàng',
      'description':
          'Lưu thông tin khách hàng, theo dõi công nợ và lịch sử mua hàng.',
      'icon': Icons.people,
      'color': Colors.purple,
    },
    {
      'title': 'Báo cáo thống kê',
      'description':
          'Xem báo cáo doanh thu, lợi nhuận, tồn kho và công nợ theo thời gian.',
      'icon': Icons.analytics,
      'color': Colors.red,
    },
  ];

  Future<void> _startApp() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseHelper.instance.setFirstRun(false);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print('Error starting app: $e');
      if (mounted) {
        ToastHelper.showError(context, 'Lỗi: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return _buildSlide(
                        icon: slide['icon'],
                        color: slide['color'],
                        title: slide['title'],
                        description: slide['description'],
                      );
                    },
                  ),
                ),
                SizedBox(
                    height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? _slides[_currentPage]['color']
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                    height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
                Padding(
                  padding: EdgeInsets.all(
                      ResponsiveUtils.getAdaptiveSpacing(context, 24)),
                  child: Column(
                    children: [
                      // Only show the start button on the last slide or when loading
                      if (_currentPage == _slides.length - 1 || _isLoading)
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _startApp,
                          style: FilledButton.styleFrom(
                            minimumSize: Size.fromHeight(
                                ResponsiveUtils.getAdaptiveSpacing(
                                    context, 48)),
                            backgroundColor: _slides[_currentPage]['color'],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  ResponsiveUtils.getAdaptiveSpacing(
                                      context, 8)),
                            ),
                          ),
                          icon: _isLoading
                              ? SizedBox(
                                  width: ResponsiveUtils.getAdaptiveIconSize(
                                      context, 20),
                                  height: ResponsiveUtils.getAdaptiveIconSize(
                                      context, 20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(
                            'Bắt đầu sử dụng',
                            style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                    context, 16)),
                          ),
                        ),
                      // Show the next button on all slides except the last one
                      if (_currentPage < _slides.length - 1) ...[
                        SizedBox(
                            height: ResponsiveUtils.getAdaptiveSpacing(
                                context, 12)),
                        TextButton.icon(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: TextButton.styleFrom(
                            minimumSize: Size.fromHeight(
                                ResponsiveUtils.getAdaptiveSpacing(
                                    context, 48)),
                            foregroundColor: _slides[_currentPage]['color'],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  ResponsiveUtils.getAdaptiveSpacing(
                                      context, 8)),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(
                            'Tiếp theo',
                            style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                    context, 16)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Skip button in top right corner
            Positioned(
              top: ResponsiveUtils.getAdaptiveSpacing(context, 16),
              right: ResponsiveUtils.getAdaptiveSpacing(context, 16),
              child: TextButton.icon(
                onPressed: _startApp,
                style: TextButton.styleFrom(
                  foregroundColor: _slides[_currentPage]['color'],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                  ),
                ),
                icon: const Icon(Icons.skip_next),
                label: Text(
                  'Bỏ qua',
                  style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 24)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: ResponsiveUtils.getAdaptiveIconSize(context, 120),
            color: color,
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 32)),
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 28),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          Text(
            description,
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
