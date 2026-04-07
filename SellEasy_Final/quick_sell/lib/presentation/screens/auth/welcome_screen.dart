import 'package:flutter/material.dart';
import '../../../services/database_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_utils.dart';
import '../home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Chào mừng đến với ${AppConstants.appName}',
      'description': 'Ứng dụng quản lý bán hàng đơn giản và hiệu quả',
      'image': 'assets/images/welcome_1.png',
    },
    {
      'title': 'Quản lý kho hàng',
      'description': 'Theo dõi tồn kho, nhập hàng và quản lý sản phẩm dễ dàng',
      'image': 'assets/images/welcome_2.png',
    },
    {
      'title': 'Quản lý đơn hàng',
      'description': 'Tạo đơn hàng, theo dõi thanh toán và quản lý khách hàng',
      'image': 'assets/images/welcome_3.png',
    },
    {
      'title': 'Báo cáo chi tiết',
      'description': 'Xem báo cáo doanh thu, lợi nhuận và tồn kho theo thời gian',
      'image': 'assets/images/welcome_4.png',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _getStarted();
    }
  }

  Future<void> _getStarted() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Đánh dấu đã hoàn thành lần chạy đầu tiên
      await DatabaseHelper.instance.setFirstRunCompleted();

      if (!mounted) return;

      // Chuyển đến màn hình chính
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      print('Error in get started: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(
                    _pages[index]['title'],
                    _pages[index]['description'],
                    _pages[index]['image'],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.withAlpha(100),
                        ),
                      ),
                    ),
                  ),
                  // Next button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : FilledButton(
                          onPressed: _nextPage,
                          child: Text(
                            _currentPage < _pages.length - 1
                                ? 'Tiếp tục'
                                : 'Bắt đầu',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 16),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(String title, String description, String imagePath) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder for image
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.image,
              size: 100,
              color: Colors.grey.withAlpha(100),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 24),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
