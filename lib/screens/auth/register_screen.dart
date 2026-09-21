import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/artboard_input_field.dart';

/// Mirrors ui/screens/auth/RegisterScreen.kt.
class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegisterSuccess;
  final VoidCallback onNavigateToLogin;

  const RegisterScreen({super.key, required this.onRegisterSuccess, required this.onNavigateToLogin});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _nationalId = TextEditingController();
  final _financialIndex = TextEditingController();
  final _schoolName = TextEditingController();
  final _wilaya = TextEditingController();
  final _moughataa = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in [
      _fullName, _phone, _nationalId, _financialIndex, _schoolName, _wilaya, _moughataa, _password, _confirmPassword
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_fullName.text.trim().isEmpty || _phone.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _errorMessage = 'يرجى تعبئة الحقول المطلوبة (الاسم، الهاتف، كلمة المرور)');
      return;
    }
    if (_password.text != _confirmPassword.text) {
      setState(() => _errorMessage = 'كلمتا المرور غير متطابقتين');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthProvider>().register(
            phone: _phone.text.trim(),
            password: _password.text,
            fullName: _fullName.text.trim(),
            nationalId: _nationalId.text.trim(),
            financialIndex: _financialIndex.text.trim(),
            schoolName: _schoolName.text.trim(),
            wilaya: _wilaya.text.trim(),
            moughataa: _moughataa.text.trim(),
          );
      if (mounted) widget.onRegisterSuccess();
    } catch (_) {
      setState(() => _errorMessage = 'تعذر إنشاء الحساب. قد يكون رقم الهاتف مستخدماً من قبل.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: widget.onNavigateToLogin),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              const Text('إنشاء حساب معلم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ArtboardInputField(label: 'الاسم الكامل', controller: _fullName, placeholder: 'اسمك الكامل'),
                      const SizedBox(height: 12),
                      ArtboardInputField(
                        label: 'رقم الهاتف',
                        controller: _phone,
                        placeholder: 'مثال: 22212345678',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      ArtboardInputField(
                        label: 'الرقم الوطني (اختياري)',
                        controller: _nationalId,
                        placeholder: 'الرقم الوطني للتعريف',
                      ),
                      const SizedBox(height: 12),
                      ArtboardInputField(
                        label: 'الدليل المالي (اختياري)',
                        controller: _financialIndex,
                        placeholder: 'الدليل المالي',
                      ),
                      const SizedBox(height: 12),
                      ArtboardInputField(label: 'اسم المدرسة', controller: _schoolName, placeholder: 'المدرسة الابتدائية'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ArtboardInputField(label: 'الولاية', controller: _wilaya, placeholder: 'نواكشوط'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ArtboardInputField(label: 'المقاطعة', controller: _moughataa, placeholder: 'المقاطعة'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ArtboardInputField(
                        label: 'كلمة المرور',
                        controller: _password,
                        placeholder: 'كلمة المرور',
                        isPassword: true,
                      ),
                      const SizedBox(height: 12),
                      ArtboardInputField(
                        label: 'تأكيد كلمة المرور',
                        controller: _confirmPassword,
                        placeholder: 'أعد إدخال كلمة المرور',
                        isPassword: true,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
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
                              : const Text('إنشاء الحساب'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
