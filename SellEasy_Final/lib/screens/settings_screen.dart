import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import 'package:intl/intl.dart';
import '../widgets/app_help_dialog.dart';
import '../providers/theme_provider.dart';
import '../utils/toast_helper.dart';
import '../utils/dialog_helper.dart';
import '../utils/responsive_utils.dart';
import 'advanced_settings_screen.dart';
import 'backup_screen.dart';
import 'premium_features_screen.dart';
import 'security_notifications_screen.dart';
import 'theme_settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

// Widget chung để xây dựng các phần trong tab cài đặt
class _SectionBuilder extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final IconData? icon;

  const _SectionBuilder({
    required this.title,
    required this.children,
    this.icon,
  });

  @override
  State<_SectionBuilder> createState() => _SectionBuilderState();
}

class _SectionBuilderState extends State<_SectionBuilder>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    // Lưu trữ các giá trị màu sắc để tránh rebuild khi theme thay đổi
    final textStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
    );

    return Card(
      child: Padding(
        padding:
            EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon),
                  SizedBox(
                      width: ResponsiveUtils.getAdaptiveSpacing(context, 8))
                ],
                Text(
                  widget.title,
                  style: textStyle,
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            ...widget.children,
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isFirstRun = true;
  final bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _restoreScrollPosition();

    // Lưu vị trí cuộn khi người dùng cuộn
    _scrollController.addListener(_saveScrollPosition);
  }

  Future<void> _loadData() async {
    setState(() {
      _isFirstRun = false;
    });
  }

  void _restoreScrollPosition() {
    // Đảm bảo widget đã được render trước khi cuộn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      if (_scrollController.hasClients && themeProvider.scrollPosition > 0) {
        _scrollController.jumpTo(themeProvider.scrollPosition);
      }
    });
  }

  void _saveScrollPosition() {
    if (_scrollController.hasClients) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.saveScrollPosition(_scrollController.offset);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (isError) {
      ToastHelper.showError(context, message);
    } else {
      ToastHelper.showSuccess(context, message);
    }
  }

  Widget _buildInterfaceSection() {
    return _SectionBuilder(
      title: 'Giao diện',
      icon: Icons.format_paint,
      children: [
        const _ThemeToggleWidget(),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        ListTile(
          title: const Text('Tùy chỉnh giao diện'),
          subtitle:
              const Text('Chế độ theo hệ thống, tự động, màu sắc chủ đạo'),
          leading: const Icon(Icons.color_lens),
          trailing: Icon(Icons.arrow_forward_ios,
              size: ResponsiveUtils.getAdaptiveIconSize(context, 16)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ThemeSettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return const _SecurityAndNotificationsSection();
  }

  Widget _buildDataSection() {
    return const _DataBackupSection();
  }

  Widget _buildPremiumFeaturesLink() {
    return const _PremiumFeaturesLinkSection();
  }

  Widget _buildAdvancedSettingsLink() {
    return const _AdvancedSettingsLinkSection();
  }

  Widget _buildSupportSection() {
    // Sử dụng const để tránh rebuild không cần thiết
    return const _SupportAndInformationSectionWrapper();
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question),
      children: [
        Padding(
          padding:
              EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          child: Text(answer),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstRun) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                controller:
                    _scrollController, // Sử dụng ScrollController để lưu vị trí cuộn
                padding: EdgeInsets.all(
                    ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                // Sử dụng ListView.builder để chỉ build các widget khi cần thiết
                itemCount: 6, // Số lượng mục trong danh sách
                itemBuilder: (context, index) {
                  // Sử dụng index để xác định widget cần hiển thị
                  if (index == 0) {
                    return _buildPremiumFeaturesLink();
                  } else if (index == 1) {
                    return Padding(
                      padding: EdgeInsets.only(
                          top: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                      child: _buildAdvancedSettingsLink(),
                    );
                  } else if (index == 2) {
                    return Padding(
                      padding: EdgeInsets.only(
                          top: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                      child: _buildInterfaceSection(),
                    );
                  } else if (index == 3) {
                    return Padding(
                      padding: EdgeInsets.only(
                          top: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                      child: _buildSecuritySection(),
                    );
                  } else if (index == 4) {
                    return Padding(
                      padding: EdgeInsets.only(
                          top: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                      child: _buildDataSection(),
                    );
                  } else {
                    return Padding(
                      padding: EdgeInsets.only(
                          top: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                      child: _buildSupportSection(),
                    );
                  }
                },
              ),
            ),
    );
  }

  @override
  void dispose() {
    // Hủy đăng ký listener và giải phóng controller
    _scrollController.removeListener(_saveScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String formattedValue = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (formattedValue.length > 10) {
      formattedValue = formattedValue.substring(0, 10);
    }

    if (formattedValue.isNotEmpty) {
      formattedValue = _formatter.format(int.parse(formattedValue));
    }

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}

class _UnitAndFormatSettings extends StatefulWidget {
  const _UnitAndFormatSettings();

  @override
  State<_UnitAndFormatSettings> createState() => _UnitAndFormatSettingsState();
}

class _UnitAndFormatSettingsState extends State<_UnitAndFormatSettings> {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.getUnitSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    await DatabaseHelper.instance.setUnitSetting(key, value.toString());
    if (mounted) {
      setState(() {
        _settings[key] = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Hiển thị đơn vị'),
          subtitle: const Text('Hiển thị trường đơn vị trong form sản phẩm'),
          value: _settings['show_unit'] as bool,
          onChanged: (value) => _updateSetting('show_unit', value),
        ),
        SwitchListTile(
          title: const Text('Cho phép thay đổi đơn vị'),
          subtitle: const Text(
              'Cho phép người dùng thay đổi đơn vị khi tạo/sửa sản phẩm'),
          value: _settings['enable_unit'] as bool,
          onChanged: (value) => _updateSetting('enable_unit', value),
        ),
        Divider(height: ResponsiveUtils.getAdaptiveSpacing(context, 32)),
        DropdownButtonFormField<String>(
          value: _settings['currency'] as String,
          decoration: InputDecoration(
            labelText: 'Đơn vị tiền tệ',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 16),
              vertical: ResponsiveUtils.getAdaptiveSpacing(context, 12),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'VND', child: Text('Việt Nam Đồng (VND)')),
            DropdownMenuItem(value: 'USD', child: Text('US Dollar (USD)')),
          ],
          onChanged: (value) {
            if (value != null) {
              _updateSetting('currency', value);
            }
          },
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        DropdownButtonFormField<String>(
          value: _settings['default_unit'] as String,
          decoration: InputDecoration(
            labelText: 'Đơn vị đo lường mặc định',
            border: const OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 16),
              vertical: ResponsiveUtils.getAdaptiveSpacing(context, 12),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'cái', child: Text('Cái')),
            DropdownMenuItem(value: 'chiếc', child: Text('Chiếc')),
            DropdownMenuItem(value: 'kg', child: Text('Kilogram (kg)')),
            DropdownMenuItem(value: 'g', child: Text('Gram (g)')),
            DropdownMenuItem(value: 'm', child: Text('Mét (m)')),
            DropdownMenuItem(value: 'cm', child: Text('Centimét (cm)')),
          ],
          onChanged: (value) {
            if (value != null) {
              _updateSetting('default_unit', value);
            }
          },
        ),
      ],
    );
  }
}

class _SkuSettings extends StatefulWidget {
  const _SkuSettings();

  @override
  State<_SkuSettings> createState() => _SkuSettingsState();
}

// Widget chính cho phần bảo mật và thông báo
class _SecurityAndNotificationsSection extends StatefulWidget {
  const _SecurityAndNotificationsSection();

  @override
  State<_SecurityAndNotificationsSection> createState() =>
      _SecurityAndNotificationsSectionState();
}

class _SecurityAndNotificationsSectionState
    extends State<_SecurityAndNotificationsSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    return _SectionBuilder(
      title: 'Bảo mật & Thông báo',
      icon: Icons.security,
      children: [
        ListTile(
          title: const Text('Quản lý bảo mật và thông báo'),
          subtitle: const Text('Cài đặt bảo mật và tùy chỉnh thông báo'),
          leading: const Icon(Icons.notifications_active),
          trailing: Icon(Icons.arrow_forward_ios,
              size: ResponsiveUtils.getAdaptiveIconSize(context, 16)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SecurityNotificationsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SkuSettingsState extends State<_SkuSettings> {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.getSkuSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    await DatabaseHelper.instance.setSkuSetting(key, value.toString());
    if (mounted) {
      setState(() {
        _settings[key] = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    return Column(
      children: [
        TextFormField(
          initialValue: _settings['sku_prefix'] as String,
          decoration: InputDecoration(
            labelText: 'Tiền tố SKU',
            border: const OutlineInputBorder(),
            helperText:
                'Tiền tố sẽ được thêm vào trước mã sản phẩm (VD: SP-001)',
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 16),
              vertical: ResponsiveUtils.getAdaptiveSpacing(context, 12),
            ),
          ),
          onChanged: (value) => _updateSetting('sku_prefix', value),
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        SwitchListTile(
          title: const Text('Cho phép tùy chỉnh SKU'),
          subtitle: const Text('Cho phép người dùng nhập SKU thủ công'),
          value: _settings['allow_manual_sku'] as bool? ?? true,
          onChanged: (value) => _updateSetting('allow_manual_sku', value),
        ),
      ],
    );
  }
}

class _NotificationSettings extends StatefulWidget {
  const _NotificationSettings();

  @override
  State<_NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<_NotificationSettings> {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.getNotificationSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    await DatabaseHelper.instance.setNotificationSetting(key, value);
    if (mounted) {
      setState(() {
        _settings[key] = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Thông báo hết hàng'),
          subtitle: Text(
            'Nhận thông báo khi sản phẩm còn dưới ${_settings['low_stock_threshold']} đơn vị',
          ),
          value: _settings['low_stock'] as bool,
          onChanged: (value) => _updateSetting('low_stock', value),
        ),
        if (_settings['low_stock'] as bool)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextFormField(
              initialValue: _settings['low_stock_threshold'].toString(),
              decoration: const InputDecoration(
                labelText: 'Ngưỡng cảnh báo hết hàng',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning),
                helperText: 'Số lượng tối thiểu trước khi thông báo',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final threshold = int.tryParse(value) ?? 5;
                _updateSetting('low_stock_threshold', threshold);
              },
            ),
          ),
        SwitchListTile(
          title: const Text('Thông báo công nợ'),
          subtitle: Text(
            'Nhận thông báo khi khách hàng nợ quá ${_settings['debt_reminder_days']} ngày',
          ),
          value: _settings['debt_reminder'] as bool,
          onChanged: (value) => _updateSetting('debt_reminder', value),
        ),
      ],
    );
  }
}

class _DataBackupSection extends StatefulWidget {
  const _DataBackupSection();

  @override
  State<_DataBackupSection> createState() => _DataBackupSectionState();
}

class _DataBackupSectionState extends State<_DataBackupSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    return _SectionBuilder(
      title: 'Sao lưu & Đồng bộ',
      icon: Icons.storage,
      children: [
        ListTile(
          title: const Text('Sao lưu & Đồng bộ'),
          subtitle: const Text('Sao lưu cục bộ, Google Drive, lịch sử sao lưu'),
          leading: const Icon(Icons.backup),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BackupScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PremiumFeaturesLinkSection extends StatefulWidget {
  const _PremiumFeaturesLinkSection();

  @override
  State<_PremiumFeaturesLinkSection> createState() =>
      _PremiumFeaturesLinkSectionState();
}

class _PremiumFeaturesLinkSectionState
    extends State<_PremiumFeaturesLinkSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    // Cache colors to prevent rebuilds when theme changes
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryColorWithAlpha = primaryColor.withAlpha(30);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PremiumFeaturesScreen(),
            ),
          );
        },
        child: Padding(
          padding:
              EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16.0)),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                    ResponsiveUtils.getAdaptiveSpacing(context, 10)),
                decoration: BoxDecoration(
                  color: primaryColorWithAlpha,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.workspace_premium,
                  color: primaryColor,
                  size: ResponsiveUtils.getAdaptiveIconSize(context, 28),
                ),
              ),
              SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tính năng nâng cao',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 16),
                      ),
                    ),
                    SizedBox(
                        height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                    Text(
                      'Khám phá các tính năng đặc biệt và ủng hộ nhà phát triển',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 14),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
                color: primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvancedSettingsLinkSection extends StatefulWidget {
  const _AdvancedSettingsLinkSection();

  @override
  State<_AdvancedSettingsLinkSection> createState() =>
      _AdvancedSettingsLinkSectionState();
}

class _AdvancedSettingsLinkSectionState
    extends State<_AdvancedSettingsLinkSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    return _SectionBuilder(
      title: 'Thiết lập kinh doanh',
      icon: Icons.settings_applications,
      children: [
        ListTile(
          title: const Text('Ngành hàng & tùy chỉnh'),
          subtitle: const Text('Ngành hàng, tùy chỉnh, hiển thị, đơn vị...'),
          leading: const Icon(Icons.tune),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdvancedSettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Widget riêng biệt cho phần hỗ trợ
class _SupportItems extends StatefulWidget {
  final Function(String, {bool isError}) showMessage;
  final Widget Function(String, String) buildFAQItem;

  const _SupportItems({
    required this.showMessage,
    required this.buildFAQItem,
  });

  @override
  State<_SupportItems> createState() => _SupportItemsState();
}

class _SupportItemsState extends State<_SupportItems>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    return Column(
      children: [
        ListTile(
          title: const Text('Hướng dẫn sử dụng'),
          subtitle:
              const Text('Xem hướng dẫn chi tiết về cách sử dụng ứng dụng'),
          leading: const Icon(Icons.book),
          onTap: () {
            DialogHelper.showAnimatedDialog(
              context: context,
              builder: (context) => const AppHelpDialog(),
            );
          },
        ),
        ListTile(
          title: const Text('Câu hỏi thường gặp'),
          subtitle: const Text('Giải đáp các thắc mắc phổ biến'),
          leading: const Icon(Icons.question_answer),
          onTap: () {
            DialogHelper.showAnimatedDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Câu hỏi thường gặp'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.buildFAQItem(
                        'Làm sao để thêm sản phẩm mới?',
                        'Vào màn hình Kho Hàng, nhấn nút + để thêm sản phẩm mới. Điền đầy đủ thông tin và nhấn Lưu.',
                      ),
                      widget.buildFAQItem(
                        'Cách tạo đơn hàng mới?',
                        'Vào màn hình Kho Hàng, chọn sản phẩm và nhấn nút "Tạo đơn". Thêm sản phẩm vào đơn và hoàn tất thanh toán.',
                      ),
                      widget.buildFAQItem(
                        'Làm sao để xem báo cáo?',
                        'Vào màn hình Báo Cáo để xem các báo cáo về doanh thu, lợi nhuận và tồn kho.',
                      ),
                      widget.buildFAQItem(
                        'Cách sao lưu dữ liệu?',
                        'Vào Cài đặt > Sao lưu & Đồng bộ để sao lưu dữ liệu.',
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            );
          },
        ),
        ListTile(
          title: const Text('Liên hệ hỗ trợ'),
          subtitle: const Text('Gửi phản hồi hoặc yêu cầu hỗ trợ'),
          leading: const Icon(Icons.support_agent),
          onTap: () {
            DialogHelper.showAnimatedDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Liên hệ hỗ trợ'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nếu bạn cần hỗ trợ, vui lòng liên hệ với chúng tôi qua:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email'),
                        subtitle: const Text('dinhkhanhtung@outlook.com'),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(
                                text: 'dinhkhanhtung@outlook.com'));
                            widget.showMessage('Đã sao chép email');
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text('Hotline'),
                        subtitle: const Text('0982581222'),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(
                                const ClipboardData(text: '0982581222'));
                            widget.showMessage('Đã sao chép số điện thoại');
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Thời gian làm việc:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text('Thứ 2 - Thứ 6: 8:00 - 17:00'),
                      const Text('Thứ 7: 8:00 - 12:00'),
                      const Text('Chủ nhật: Nghỉ'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// Widget wrapper để sử dụng const constructor
class _SupportAndInformationSectionWrapper extends StatelessWidget {
  const _SupportAndInformationSectionWrapper();

  @override
  Widget build(BuildContext context) {
    // Lấy _showMessage và _buildFAQItem từ context
    final settingsState =
        context.findAncestorStateOfType<_SettingsScreenState>();
    if (settingsState == null) return const SizedBox.shrink();

    return _SupportAndInformationSection(
      showMessage: settingsState._showMessage,
      buildFAQItem: settingsState._buildFAQItem,
    );
  }
}

class _SupportAndInformationSection extends StatefulWidget {
  final Function(String, {bool isError}) showMessage;
  final Widget Function(String, String) buildFAQItem;

  const _SupportAndInformationSection({
    required this.showMessage,
    required this.buildFAQItem,
  });

  @override
  State<_SupportAndInformationSection> createState() =>
      _SupportAndInformationSectionState();
}

class _SupportAndInformationSectionState
    extends State<_SupportAndInformationSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    return _SectionBuilder(
      title: 'Hỗ trợ & Thông tin',
      icon: Icons.help,
      children: [
        // Phần Hỗ trợ
        Text(
          'Hỗ trợ',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16)),
        ),
        _SupportItems(
            showMessage: widget.showMessage, buildFAQItem: widget.buildFAQItem),
        Divider(height: ResponsiveUtils.getAdaptiveSpacing(context, 32)),
        // Phần Thông tin ứng dụng
        Text(
          'Thông tin ứng dụng',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16)),
        ),
        _AppInfoSection(showMessage: widget.showMessage),
      ],
    );
  }
}

class _AppInfoSection extends StatefulWidget {
  final Function(String, {bool isError}) showMessage;

  const _AppInfoSection({required this.showMessage});

  @override
  State<_AppInfoSection> createState() => _AppInfoSectionState();
}

class _AppInfoSectionState extends State<_AppInfoSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    return Column(
      children: [
        const ListTile(
          title: Text('Phiên bản'),
          subtitle: Text('1.0.2+13'),
          leading: Icon(Icons.info),
        ),
        ListTile(
          title: const Text('Đánh giá ứng dụng'),
          subtitle: const Text('Giúp chúng tôi cải thiện bằng cách đánh giá'),
          leading: const Icon(Icons.star),
          onTap: () async {
            final Uri url = Uri.parse(
                'https://play.google.com/store/apps/details?id=com.dinhkhanhtung.selleasy');
            try {
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                widget.showMessage('Không thể mở trang đánh giá',
                    isError: true);
              }
            } catch (e) {
              widget.showMessage('Lỗi: ${e.toString()}', isError: true);
            }
          },
        ),
        ListTile(
          title: const Text('Chia sẻ ứng dụng'),
          subtitle: const Text('Giới thiệu ứng dụng với bạn bè'),
          leading: const Icon(Icons.share),
          onTap: () async {
            const String text =
                'Hãy thử SellEasy - Ứng dụng quản lý bán hàng toàn diện: https://play.google.com/store/apps/details?id=com.dinhkhanhtung.selleasy';
            try {
              final Uri url = Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.dinhkhanhtung.selleasy');
              await launchUrl(url, mode: LaunchMode.externalApplication);
              await Clipboard.setData(const ClipboardData(text: text));
              widget.showMessage('Đã sao chép liên kết ứng dụng');
            } catch (e) {
              widget.showMessage('Lỗi: ${e.toString()}', isError: true);
            }
          },
        ),
      ],
    );
  }
}

// Widget riêng biệt cho chế độ tối/sáng để tránh rebuild toàn bộ màn hình
class _ThemeToggleWidget extends StatefulWidget {
  const _ThemeToggleWidget();

  @override
  State<_ThemeToggleWidget> createState() => _ThemeToggleWidgetState();
}

class _ThemeToggleWidgetState extends State<_ThemeToggleWidget>
    with AutomaticKeepAliveClientMixin {
  // Giữ trạng thái widget khi rebuild
  @override
  bool get wantKeepAlive => true;

  // Lưu trữ trạng thái chế độ tối hiện tại để tránh rebuild không cần thiết
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    // Đọc trạng thái chế độ tối hiện tại từ ThemeProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _isDarkMode = themeProvider.themeMode == ThemeMode.dark;
      });
    });
  }

  // Xử lý khi người dùng thay đổi chế độ tối/sáng
  Future<void> _handleThemeToggle(bool value) async {
    setState(() {
      _isDarkMode = value;
    });

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    // Đọc trạng thái chế độ tối hiện tại từ ThemeProvider (chỉ đọc lần đầu)
    if (!mounted) return const SizedBox.shrink();

    return SwitchListTile(
      title: const Text('Chế độ tối'),
      subtitle: const Text('Bật/tắt giao diện tối'),
      value: _isDarkMode,
      onChanged: _handleThemeToggle,
    );
  }
}
