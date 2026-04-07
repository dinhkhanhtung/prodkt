import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import 'home_screen.dart';
import '../extensions/app_bar_extensions.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarExtensions.noColorTinting(
        context: context,
        title: Text(
          'Tùy chỉnh giao diện',
          style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 20)),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: ResponsiveUtils.getAdaptiveIconSize(context, 24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding:
            EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        children: [
          Text(
            'Chế độ giao diện',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16)),
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          const _ThemeModeOptionsWidget(),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
          Text(
            'Màu sắc chủ đạo',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16)),
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          const _ThemeColorSelectionWidget(),
        ],
      ),
      bottomNavigationBar: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Sử dụng theme hiện tại để xác định màu sắc
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final primaryColor = Theme.of(context).colorScheme.primary;
          // Trong dark mode, sử dụng chính xác màu của appBar (Colors.grey[900])
          final backgroundColor = isDark ? Colors.grey[900] : primaryColor;

          return NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: backgroundColor,
              indicatorColor: isDark
                  ? primaryColor.withAlpha(51)
                  : Colors.white.withAlpha(51), // 0.2 opacity
              elevation: 2,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(color: isDark ? primaryColor : Colors.white);
                }
                return TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.white70);
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return IconThemeData(
                      color: isDark ? primaryColor : Colors.white);
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
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.inventory,
                      size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                  selectedIcon: Icon(Icons.inventory,
                      size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                  label: 'Kho Hàng',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart,
                      size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                  selectedIcon: Icon(Icons.bar_chart,
                      size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                  label: 'Báo Cáo',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings,
                      size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                  selectedIcon: Icon(Icons.settings,
                      size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                  label: 'Cài Đặt',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Widget riêng biệt cho các tùy chọn chế độ giao diện
class _ThemeModeOptionsWidget extends StatefulWidget {
  const _ThemeModeOptionsWidget();

  @override
  State<_ThemeModeOptionsWidget> createState() =>
      _ThemeModeOptionsWidgetState();
}

class _ThemeModeOptionsWidgetState extends State<_ThemeModeOptionsWidget>
    with AutomaticKeepAliveClientMixin {
  // Giữ trạng thái widget khi rebuild
  @override
  bool get wantKeepAlive => true;

  // Lưu trữ tùy chọn chế độ hiện tại
  ThemeModeOption _currentThemeOption = ThemeModeOption.light;

  // Danh sách các tùy chọn chế độ
  final Map<ThemeModeOption, String> _themeOptions = {
    ThemeModeOption.light: 'Sáng',
    ThemeModeOption.dark: 'Tối',
    ThemeModeOption.system: 'Theo hệ thống',
    ThemeModeOption.auto: 'Tự động theo thời gian',
  };

  @override
  void initState() {
    super.initState();
    // Đọc trạng thái chế độ tối hiện tại từ ThemeProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _currentThemeOption = themeProvider.themeModeOption;
      });
    });
  }

  // Xử lý khi người dùng thay đổi chế độ theme
  Future<void> _handleThemeOptionChange(ThemeModeOption? option) async {
    if (option != null && option != _currentThemeOption) {
      setState(() {
        _currentThemeOption = option;
      });

      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      await themeProvider.setThemeModeOption(option);

      // Hiển thị hộp thoại cài đặt thời gian nếu chọn chế độ tự động
      if (option == ThemeModeOption.auto) {
        _showAutoThemeTimeSettings();
      }
    }
  }

  // Hiển thị hộp thoại cài đặt thời gian cho chế độ tự động
  void _showAutoThemeTimeSettings() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    int startHour = themeProvider.darkModeStartHour;
    int endHour = themeProvider.darkModeEndHour;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cài đặt thời gian',
            style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Chọn thời gian bắt đầu và kết thúc chế độ tối',
                style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getAdaptiveFontSize(context, 14))),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Bắt đầu',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bedtime,
                          size:
                              ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal:
                            ResponsiveUtils.getAdaptiveSpacing(context, 12),
                        vertical:
                            ResponsiveUtils.getAdaptiveSpacing(context, 8),
                      ),
                    ),
                    value: startHour,
                    items: List.generate(24, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text('$index:00'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        startHour = value;
                      }
                    },
                  ),
                ),
                SizedBox(
                    width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Kết thúc',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.wb_sunny,
                          size:
                              ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal:
                            ResponsiveUtils.getAdaptiveSpacing(context, 12),
                        vertical:
                            ResponsiveUtils.getAdaptiveSpacing(context, 8),
                      ),
                    ),
                    value: endHour,
                    items: List.generate(24, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text('$index:00'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        endHour = value;
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              themeProvider.setDarkModeStartHour(startHour);
              themeProvider.setDarkModeEndHour(endHour);
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    // Đọc trạng thái chế độ tối hiện tại từ ThemeProvider (chỉ đọc lần đầu)
    if (!mounted) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin:
              EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 0)),
          child: Column(
            children: _themeOptions.entries.map((entry) {
              return RadioListTile<ThemeModeOption>(
                title: Text(entry.value,
                    style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 16))),
                value: entry.key,
                groupValue: _currentThemeOption,
                onChanged: _handleThemeOptionChange,
              );
            }).toList(),
          ),
        ),
        if (_currentThemeOption == ThemeModeOption.auto)
          Padding(
            padding: EdgeInsets.only(
                top: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
            child: TextButton.icon(
              onPressed: _showAutoThemeTimeSettings,
              icon: Icon(Icons.access_time,
                  size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
              label: Text('Cài đặt thời gian',
                  style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 14))),
            ),
          ),
      ],
    );
  }
}

// Widget riêng biệt cho một màu chủ đạo
class _ColorItem extends StatelessWidget {
  final MapEntry<String, Color> colorEntry;
  final bool isSelected;
  final double size;
  final Function(String) onColorSelected;

  const _ColorItem({
    required this.colorEntry,
    required this.isSelected,
    required this.size,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onColorSelected(colorEntry.key),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorEntry.value,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: Colors.white,
                size: ResponsiveUtils.getAdaptiveIconSize(context, size * 0.5),
              )
            : null,
      ),
    );
  }
}

// Widget riêng biệt cho chọn màu chủ đạo để tránh rebuild toàn bộ màn hình
class _ThemeColorSelectionWidget extends StatefulWidget {
  const _ThemeColorSelectionWidget();

  @override
  State<_ThemeColorSelectionWidget> createState() =>
      _ThemeColorSelectionWidgetState();
}

class _ThemeColorSelectionWidgetState extends State<_ThemeColorSelectionWidget>
    with AutomaticKeepAliveClientMixin {
  // Giữ trạng thái widget khi rebuild
  @override
  bool get wantKeepAlive => true;

  // Lưu trữ màu được chọn hiện tại để tránh rebuild không cần thiết
  String _currentSelectedColor = '';

  @override
  void initState() {
    super.initState();
    // Đọc màu hiện tại từ ThemeProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _currentSelectedColor = themeProvider.themeColor;
      });
    });
  }

  // Xử lý khi người dùng chọn màu mới
  Future<void> _handleColorSelection(String colorKey) async {
    if (_currentSelectedColor != colorKey) {
      setState(() {
        _currentSelectedColor = colorKey;
      });

      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      await themeProvider.setThemeColor(colorKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    // Đọc màu hiện tại từ ThemeProvider (chỉ đọc lần đầu)
    if (_currentSelectedColor.isEmpty) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      _currentSelectedColor = themeProvider.themeColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn màu chủ đạo cho ứng dụng:',
            style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14))),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
        LayoutBuilder(
          builder: (context, constraints) {
            final colors = AppTheme.themeColors.entries.toList();
            final itemCount = colors.length;
            final spacing = ResponsiveUtils.getAdaptiveSpacing(context, 8);
            final availableWidth = constraints.maxWidth;
            final itemWidth =
                (availableWidth - (spacing * (itemCount - 1))) / itemCount;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: colors.map((entry) {
                final isSelected = _currentSelectedColor == entry.key;
                return _ColorItem(
                  colorEntry: entry,
                  isSelected: isSelected,
                  size: itemWidth,
                  onColorSelected: _handleColorSelection,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
