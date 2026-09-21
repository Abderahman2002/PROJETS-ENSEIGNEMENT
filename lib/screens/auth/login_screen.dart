import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/artboard_input_field.dart';
import '../../widgets/logo_view.dart';

/// Mirrors ui/screens/auth/LoginScreen.kt — phone-or-financial-index + password.
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onNavigateToRegister;
  final VoidCallback onNavigateToForgotPassword;
  final VoidCallback onNavigateToDeveloperLogin;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onNavigateToRegister,
    required this.onNavigateToForgotPassword,
    required this.onNavigateToDeveloperLogin,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  int _devLogoClicks = 0;
  DateTime? _lastDevLogoClickTime;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogoTap() {
    final now = DateTime.now();
    if (_lastDevLogoClickTime != null && now.difference(_lastDevLogoClickTime!).inMilliseconds < 2000) {
      _devLogoClicks++;
    } else {
      _devLogoClicks = 1;
    }
    _lastDevLogoClickTime = now;
    if (_devLogoClicks >= 4) {
      _devLogoClicks = 0;
      widget.onNavigateToDeveloperLogin();
    }
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال رقم الهاتف أو الدليل المالي');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال كلمة المرور');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthProvider>().login(phoneOrIndex: phone, password: password);
      if (mounted) widget.onLoginSuccess();
    } catch (_) {
      setState(() => _errorMessage = 'رقم الهاتف أو كلمة المرور غير صحيحة');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              LogoView(onTitleClick: _handleLogoTap),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                  child: Column(
                    children: [
                      const Text('تسجيل الدخول', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 22),
                      ArtboardInputField(
                        label: 'رقم الهاتف أو الدليل المالي',
                        controller: _phoneController,
                        placeholder: 'أدخل رقم الهاتف أو الدليل المالي',
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 14),
                      ArtboardInputField(
                        label: 'كلمة المرور',
                        controller: _passwordController,
                        placeholder: 'أدخل كلمة المرور',
                        isPassword: true,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: widget.onNavigateToForgotPassword,
                          child: const Text('هل نسيت كلمة المرور؟', style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text('دخول'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('ليس لدي حساب؟ '),
                          GestureDetector(
                            onTap: widget.onNavigateToRegister,
                            child: Text(
                              'إنشاء حساب',
                              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
