import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_repository.dart';
import '../../theme/app_colors.dart';

/// Mirrors ui/screens/subscription/SubscriptionScreen.kt — payment info
/// (Bankily/Masrivi), a transaction-reference form, and a WhatsApp handoff
/// to admin for manual verification. Activation-code redemption from the
/// original screen is not yet wired to the new backend.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  static const adminBankilyNumber = '38333003';
  static const adminMasrviNumber = '38333003';
  static const adminWhatsapp = '22233336731';
  static const priceOuguiya = 6000;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _repo = AppRepository.instance;
  final _referenceController = TextEditingController();
  String _paymentMethod = 'BANKILY';
  bool _loading = true;
  String? _error;
  List<TeacherSubscription> _subscriptions = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final subs = await _repo.getSubscriptions();
      setState(() => _subscriptions = subs);
    } catch (_) {
      setState(() => _error = 'تعذر تحميل بيانات الاشتراك.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyNumber(String number) async {
    await Clipboard.setData(ClipboardData(text: number));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ الرقم: $number')));
  }

  Future<void> _submitAndSendWhatsapp() async {
    final profile = context.read<AuthProvider>().teacherProfile;
    setState(() => _submitting = true);
    try {
      await _repo.submitSubscriptionProof(
        paymentMethod: _paymentMethod,
        paymentReference: _referenceController.text.trim(),
      );
      final message = '''السلام عليكم ورحمة الله وبركاته،
إدارة تطبيق رفيق المعلم الموريتاني المحترمة،

لقد قمت بسداد رسوم العضوية السنوية (${SubscriptionScreen.priceOuguiya} أوقية).

بيانات الحساب:
- اسم المعلم: ${profile?.fullName ?? ''}
- رقم الهاتف المسجل: ${profile?.phone ?? ''}
- المدرسة: ${profile?.schoolName ?? ''}
- الولاية: ${profile?.wilaya ?? ''}
${_referenceController.text.trim().isNotEmpty ? '- رقم إشعار التحويل: ${_referenceController.text.trim()}' : ''}

مرفق صورة وصل التحويل لتأكيد التفعيل السنوي.''';
      final uri = Uri.parse('https://api.whatsapp.com/send?phone=${SubscriptionScreen.adminWhatsapp}&text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إرسال طلب التفعيل')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'نشط';
      case 'TRIAL':
        return 'تجريبي';
      case 'EXPIRED':
        return 'منتهي';
      case 'EXPIRING_SOON':
        return 'ينتهي قريباً';
      default:
        return 'قيد التحقق';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return const Color(0xFF16A34A);
      case 'EXPIRED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final profile = context.watch<AuthProvider>().teacherProfile;

    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(title: const Text('الاشتراك والعضوية السنوية')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: primary,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              const Icon(Icons.workspace_premium, color: Colors.white, size: 36),
                              const SizedBox(height: 8),
                              Text('العضوية السنوية للمعلم', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('${SubscriptionScreen.priceOuguiya} أوقية / سنة', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                  'الحالة الحالية: ${_statusLabel(profile?.subscriptionStatus ?? 'TRIAL')}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('طرق الدفع المتاحة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 10),
                              _PaymentNumberRow(label: 'بنكيلي Bankily', number: SubscriptionScreen.adminBankilyNumber, onCopy: _copyNumber),
                              const SizedBox(height: 8),
                              _PaymentNumberRow(label: 'مصرفي Masrvi', number: SubscriptionScreen.adminMasrviNumber, onCopy: _copyNumber),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('إرسال إشعار الدفع للإدارة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                initialValue: _paymentMethod,
                                decoration: const InputDecoration(labelText: 'وسيلة الدفع'),
                                items: const [
                                  DropdownMenuItem(value: 'BANKILY', child: Text('بنكيلي')),
                                  DropdownMenuItem(value: 'MASRVI', child: Text('مصرفي')),
                                  DropdownMenuItem(value: 'SEDAD', child: Text('سداد')),
                                  DropdownMenuItem(value: 'CASH', child: Text('نقداً')),
                                ],
                                onChanged: (v) => setState(() => _paymentMethod = v ?? _paymentMethod),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _referenceController,
                                decoration: const InputDecoration(labelText: 'رقم إشعار التحويل (اختياري)'),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _submitting ? null : _submitAndSendWhatsapp,
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                                  icon: _submitting
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.chat),
                                  label: const Text('إرسال وصل الدفع عبر واتساب'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_subscriptions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('سجل طلبات الاشتراك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        ..._subscriptions.map((s) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(s.planName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                subtitle: Text('${s.paymentMethod} • ${s.createdAt.split("T").first}', style: const TextStyle(fontSize: 11)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: _statusColor(s.status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                  child: Text(_statusLabel(s.status), style: TextStyle(fontSize: 10.5, color: _statusColor(s.status), fontWeight: FontWeight.bold)),
                                ),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _PaymentNumberRow extends StatelessWidget {
  final String label;
  final String number;
  final void Function(String) onCopy;

  const _PaymentNumberRow({required this.label, required this.number, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(number, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () => onCopy(number)),
        ],
      ),
    );
  }
}
