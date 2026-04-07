import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../utils/toast_helper.dart';
import '../utils/responsive_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _usernameFocusNode = FocusNode();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await DatabaseHelper.instance.getUser(
        _usernameController.text,
        _passwordController.text,
      );

      if (user != null && mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: user,
        );
      } else if (mounted) {
        ToastHelper.showError(
            context, 'Tên đăng nhập hoặc mật khẩu không đúng');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Đã xảy ra lỗi. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding:
              EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.store,
                  size: ResponsiveUtils.getAdaptiveIconSize(context, 64),
                  color: Colors.blue,
                ),
                SizedBox(
                    height: ResponsiveUtils.getAdaptiveSpacing(context, 32)),
                Text(
                  'SellEasy',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 32),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                    height: ResponsiveUtils.getAdaptiveSpacing(context, 32)),
                TextFormField(
                  controller: _usernameController,
                  focusNode: _usernameFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Tên đăng nhập',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person,
                        size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                    labelStyle: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 16)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên đăng nhập';
                    }
                    return null;
                  },
                ),
                SizedBox(
                    height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock,
                        size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                    labelStyle: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 16)),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    return null;
                  },
                ),
                SizedBox(
                    height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _login,
                  icon: _isLoading
                      ? SizedBox(
                          width:
                              ResponsiveUtils.getAdaptiveIconSize(context, 20),
                          height:
                              ResponsiveUtils.getAdaptiveIconSize(context, 20),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.login,
                          size:
                              ResponsiveUtils.getAdaptiveIconSize(context, 20),
                        ),
                  label: Text('Đăng nhập',
                      style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(
                              context, 16))),
                ),
                SizedBox(
                    height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                TextButton.icon(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      await DatabaseHelper.instance.resetDatabase();
                      if (mounted) {
                        ToastHelper.showSuccess(
                            context, 'Đã khôi phục cài đặt gốc');
                      }
                    } catch (e) {
                      if (mounted) {
                        ToastHelper.showError(
                            context, 'Không thể khôi phục. Vui lòng thử lại.');
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                  icon: Icon(
                    Icons.restore,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 18),
                  ),
                  label: Text('Khôi phục cài đặt gốc',
                      style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(
                              context, 14))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Auto-focus on the username field
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_usernameFocusNode.canRequestFocus) {
        _usernameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }
}
