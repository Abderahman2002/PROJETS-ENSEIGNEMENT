import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/artboard_input_field.dart';

/// Mirrors ui/screens/auth/ForgotPasswordScreen.kt — 2-step phone reset flow.
class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onSuccessReset;
  final VoidCallback onNavigateBack;

  const ForgotPasswordScreen({super.key, required this.onSuccessReset, required this.onNavigateBack});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();

  bool _codeRequested = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _devCodeHint;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (_phone.text.trim().isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال رقم الهاتف');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthProvider>().requestPasswordReset(_phone.text.trim());
      setState(() => _codeRequested = true);
    } catch (_) {
      setState(() => _errorMessage = 'تعذر إرسال رمز التحقق. تحقق من رقم الهاتف.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmReset() async {
    if (_code.text.trim().isEmpty || _newPassword.text.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال رمز التحقق وكلمة المرور الجديدة');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthProvider>().confirmPasswordReset(
            phone: _phone.text.trim(),
            code: _code.text.trim(),
            newPassword: _newPassword.text,
          );
      if (mounted) widget.onSuccessReset();
    } catch (_) {
      setState(() => _errorMessage = 'رمز التحقق غير صحيح أو منتهي الصلاحية');
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
        leading: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: widget.onNavigateBack),
        title: const Text('استعادة كلمة المرور', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ArtboardInputField(
                    label: 'رقم الهاتف',
                    controller: _phone,
                    placeholder: 'أدخل رقم الهاتف المسجل',
                    keyboardType: TextInputType.phone,
                  ),
                  if (_codeRequested) ...[
                    const SizedBox(height: 14),
                    if (_devCodeHint != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('رمز التطوير: $_devCodeHint', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ),
                    ArtboardInputField(label: 'رمز التحقق', controller: _code, placeholder: 'أدخل الرمز المرسل'),
                    const SizedBox(height: 14),
                    ArtboardInputField(
                      label: 'كلمة المرور الجديدة',
                      controller: _newPassword,
                      placeholder: 'كلمة المرور الجديدة',
                      isPassword: true,
                    ),
                  ],
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
                      onPressed: _isLoading ? null : (_codeRequested ? _confirmReset : _requestCode),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(_codeRequested ? 'تأكيد كلمة المرور الجديدة' : 'إرسال رمز التحقق'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
