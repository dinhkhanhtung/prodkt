import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/custom_field.dart';
import '../services/database_helper.dart';
import '../providers/theme_provider.dart';
import '../utils/dialog_helper.dart';
import '../utils/responsive_utils.dart';
import 'home_screen.dart';

// Widget chung để xây dựng các phần trong trang cài đặt nâng cao
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
                  Icon(widget.icon,
                      size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                  SizedBox(
                      width: ResponsiveUtils.getAdaptiveSpacing(context, 8))
                ],
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                  ),
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

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  String? _industry;
  List<CustomField> _customFields = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Chỉ hiển thị loading khi chưa có dữ liệu
    if (_industry == null) {
      setState(() => _isLoading = true);
    }

    try {
      final industry = await DatabaseHelper.instance.getIndustry();
      final customFieldsData = await DatabaseHelper.instance.getCustomFields();

      if (mounted) {
        setState(() {
          _industry = industry;
          _customFields =
              customFieldsData.map((f) => CustomField.fromMap(f)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Lỗi khi tải dữ liệu: $e');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showAddCustomFieldDialog() async {
    final nameController = TextEditingController();
    String selectedType = 'text';

    final result = await DialogHelper.showAnimatedDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Thêm trường tùy chỉnh'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên trường',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.text_fields),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Loại dữ liệu',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.data_array),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'text', child: Text('Văn bản')),
                    DropdownMenuItem(value: 'number', child: Text('Số')),
                    DropdownMenuItem(value: 'date', child: Text('Ngày')),
                    DropdownMenuItem(value: 'list', child: Text('Danh sách')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
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
                  if (nameController.text.trim().isEmpty) {
                    return;
                  }
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'type': selectedType,
                  });
                },
                child: const Text('Thêm'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      final fieldData = {
        'name': result['name'],
        'type': result['type'],
      };

      final id = await DatabaseHelper.instance.insertCustomField(fieldData);
      final field = CustomField(
        id: id,
        name: result['name'],
        type: result['type'],
      );

      setState(() {
        _customFields.add(field);
      });
    }
  }

  Future<void> _deleteCustomField(int id) async {
    final confirmed = await DialogHelper.showAnimatedDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa trường này? Dữ liệu đã nhập sẽ bị mất.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteCustomField(id);
      setState(() {
        _customFields.removeWhere((field) => field.id == id);
      });
    }
  }

  Widget _buildGeneralSection() {
    return _GeneralSettingsSection(
      industry: _industry,
      customFields: _customFields,
      onIndustryChanged: (value) async {
        if (value != null) {
          await DatabaseHelper.instance.setIndustry(value);
          setState(() => _industry = value);
        }
      },
      onAddCustomField: _showAddCustomFieldDialog,
      onDeleteCustomField: _deleteCustomField,
    );
  }

  Widget _buildDisplaySection() {
    return const _DisplayAndLanguageSection();
  }

  Widget _buildUnitSection() {
    return const _UnitAndFormatSettings();
  }

  Widget _buildPricingSection() {
    return const _PricingSection();
  }

  Widget _buildTaxSection() {
    return const _TaxAndFeesSection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thiết lập kinh doanh',
            style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 20))),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.all(
                    ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                children: [
                  _buildGeneralSection(),
                  SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  _buildDisplaySection(),
                  SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  _buildUnitSection(),
                  SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  _buildPricingSection(),
                  SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  _buildTaxSection(),
                ],
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
}

// Reusing the existing settings components
class _UnitAndFormatSettings extends StatefulWidget {
  const _UnitAndFormatSettings();

  @override
  State<_UnitAndFormatSettings> createState() => _UnitAndFormatSettingsState();
}

class _UnitAndFormatSettingsState extends State<_UnitAndFormatSettings>
    with AutomaticKeepAliveClientMixin {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await DatabaseHelper.instance.getUnitSettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin
    return _SectionBuilder(
      title: 'Đơn vị & Định dạng',
      icon: Icons.straighten,
      children: [
        const Text(
          'Đơn vị mặc định',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Column(
            children: [
              SwitchListTile(
                title: const Text('Hiển thị đơn vị'),
                subtitle:
                    const Text('Hiển thị trường đơn vị trong form sản phẩm'),
                value: _settings['show_unit'] as bool? ?? true,
                onChanged: (value) => _updateSetting('show_unit', value),
              ),
              SwitchListTile(
                title: const Text('Cho phép thay đổi đơn vị'),
                subtitle: const Text(
                    'Cho phép người dùng thay đổi đơn vị khi tạo/sửa sản phẩm'),
                value: _settings['enable_unit'] as bool? ?? true,
                onChanged: (value) => _updateSetting('enable_unit', value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _settings['default_unit'] as String? ?? 'cái',
                decoration: const InputDecoration(
                  labelText: 'Đơn vị đo lường mặc định',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
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

class _SkuSettingsState extends State<_SkuSettings>
    with AutomaticKeepAliveClientMixin {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await DatabaseHelper.instance.getSkuSettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin
    return _isLoading
        ? const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          )
        : Column(
            children: [
              TextFormField(
                initialValue: _settings['sku_prefix'] as String? ?? 'SP-',
                decoration: const InputDecoration(
                  labelText: 'Tiền tố SKU',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                  helperText:
                      'Tiền tố sẽ được thêm vào trước mã sản phẩm (VD: SP-001)',
                ),
                onChanged: (value) => _updateSetting('sku_prefix', value),
              ),
              const SizedBox(height: 16),
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

// Thêm các widget mới để tránh flickering
class _GeneralSettingsSection extends StatefulWidget {
  final String? industry;
  final List<CustomField> customFields;
  final Function(String?) onIndustryChanged;
  final VoidCallback onAddCustomField;
  final Function(int) onDeleteCustomField;

  const _GeneralSettingsSection({
    required this.industry,
    required this.customFields,
    required this.onIndustryChanged,
    required this.onAddCustomField,
    required this.onDeleteCustomField,
  });

  @override
  State<_GeneralSettingsSection> createState() =>
      _GeneralSettingsSectionState();
}

class _GeneralSettingsSectionState extends State<_GeneralSettingsSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    return _SectionBuilder(
      title: 'Cài đặt chung',
      icon: Icons.settings,
      children: [
        const Text(
          'Ngành hàng & Tùy chỉnh',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: widget.industry,
          decoration: const InputDecoration(
            labelText: 'Ngành hàng',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: const [
            DropdownMenuItem(value: 'retail', child: Text('Bán lẻ')),
            DropdownMenuItem(value: 'food', child: Text('Thực phẩm')),
            DropdownMenuItem(value: 'fashion', child: Text('Thời trang')),
            DropdownMenuItem(value: 'electronics', child: Text('Điện tử')),
            DropdownMenuItem(value: 'other', child: Text('Khác')),
          ],
          onChanged: widget.onIndustryChanged,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onAddCustomField,
                icon: const Icon(Icons.add),
                label: const Text('Thêm trường tùy chỉnh'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.customFields.map(
          (field) => Card(
            child: ListTile(
              title: Text(field.name),
              subtitle: Text(
                field.type == 'text'
                    ? 'Văn bản'
                    : field.type == 'number'
                        ? 'Số'
                        : field.type == 'date'
                            ? 'Ngày'
                            : 'Danh sách',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => widget.onDeleteCustomField(field.id),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DisplayAndLanguageSection extends StatefulWidget {
  const _DisplayAndLanguageSection();

  @override
  State<_DisplayAndLanguageSection> createState() =>
      _DisplayAndLanguageSectionState();
}

class _DisplayAndLanguageSectionState extends State<_DisplayAndLanguageSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    return _SectionBuilder(
      title: 'Hiển thị & Ngôn ngữ',
      icon: Icons.language,
      children: [
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: 'vi',
          decoration: const InputDecoration(
            labelText: 'Ngôn ngữ',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.language),
          ),
          items: const [
            DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (value) {
            // Implement language change in the future
          },
        ),
      ],
    );
  }
}

class _TaxAndFeesSection extends StatefulWidget {
  const _TaxAndFeesSection();

  @override
  State<_TaxAndFeesSection> createState() => _TaxAndFeesSectionState();
}

class _TaxAndFeesSectionState extends State<_TaxAndFeesSection>
    with AutomaticKeepAliveClientMixin {
  Map<String, dynamic> _data = {
    'default_tax': 0.0,
    'default_shipping': 0.0,
  };
  bool _isLoading = true;
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _shippingController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _taxController.dispose();
    _shippingController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await DatabaseHelper.instance.getDefaultTaxAndFees();
      if (mounted) {
        setState(() {
          _data = data;
          _taxController.text = _data['default_tax'].toString();
          _shippingController.text = _data['default_shipping'].toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin
    return _SectionBuilder(
      title: 'Thuế & Phí',
      icon: Icons.receipt_long,
      children: [
        const SizedBox(height: 16),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TextFormField(
                    controller: _taxController,
                    decoration: const InputDecoration(
                      labelText: 'Thuế mặc định (%)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.percent),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (value) async {
                      final tax = double.tryParse(value) ?? 0.0;
                      await DatabaseHelper.instance.setDefaultTax(tax);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _shippingController,
                    decoration: const InputDecoration(
                      labelText: 'Phí vận chuyển mặc định',
                      border: OutlineInputBorder(),
                      suffixText: 'đ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) async {
                      final shipping = double.tryParse(value) ?? 0.0;
                      await DatabaseHelper.instance
                          .setDefaultShipping(shipping);
                    },
                  ),
                ],
              ),
      ],
    );
  }
}

// Thêm widget mới cho phần Cài đặt & Tính toán
class _PricingSection extends StatefulWidget {
  const _PricingSection();

  @override
  State<_PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends State<_PricingSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    return const _SectionBuilder(
      title: 'Cài đặt & Tính toán',
      icon: Icons.calculate,
      children: [
        Text(
          'Mã sản phẩm (SKU)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 16),
        _SkuSettings(),
      ],
    );
  }
}
