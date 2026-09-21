import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bottom_bar.dart';
import '../../widgets/app_main_bottom_bar.dart';
import '../../widgets/artboard_input_field.dart';

/// Mirrors ui/screens/profile/ProfileScreen.kt — teacher info, color theme
/// picker, and logout. Avatar upload/photo picker from the original screen
/// is not yet wired to the new backend.
class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onNavigateToSubscription;
  final VoidCallback onNavigateToAdminUsers;

  const ProfileScreen({
    super.key,
    required this.onLogout,
    required this.onNavigateToSubscription,
    required this.onNavigateToAdminUsers,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  late TextEditingController _fullName;
  late TextEditingController _schoolName;
  late TextEditingController _wilaya;
  late TextEditingController _moughataa;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().teacherProfile;
    _fullName = TextEditingController(text: profile?.fullName ?? '');
    _schoolName = TextEditingController(text: profile?.schoolName ?? '');
    _wilaya = TextEditingController(text: profile?.wilaya ?? '');
    _moughataa = TextEditingController(text: profile?.moughataa ?? '');
  }

  @override
  void dispose() {
    _fullName.dispose();
    _schoolName.dispose();
    _wilaya.dispose();
    _moughataa.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile({
        'full_name': _fullName.text.trim(),
        'school_name': _schoolName.text.trim(),
        'wilaya': _wilaya.text.trim(),
        'moughataa': _moughataa.text.trim(),
      });
      if (mounted) setState(() => _editing = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ التعديلات')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickColorTheme() async {
    final auth = context.read<AuthProvider>();
    final chosen = await showDialog<AppColorTheme>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('اختر لون التطبيق'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: AppColorTheme.all
                .map((theme) => ListTile(
                      leading: CircleAvatar(backgroundColor: theme.primaryColor),
                      title: Text(theme.title),
                      subtitle: Text(theme.subtitle, style: const TextStyle(fontSize: 11)),
                      trailing: auth.colorTheme == theme.id ? const Icon(Icons.check_circle, color: Colors.green) : null,
                      onTap: () => Navigator.pop(context, theme),
                    ))
                .toList(),
          ),
        ),
      ),
    );
    if (chosen != null) {
      try {
        await auth.updateProfile({'color_theme': chosen.id});
      } catch (_) {}
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تسجيل الخروج')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.teacherProfile;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(title: const Text('الملف الشخصي والإعدادات')),
      bottomNavigationBar: const AppMainBottomBar(current: BottomTab.profile),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: primary.withValues(alpha: 0.12),
                      child: Icon(Icons.person, size: 46, color: primary),
                    ),
                    const SizedBox(height: 10),
                    Text(profile?.fullName.isNotEmpty == true ? profile!.fullName : 'المعلم',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('رقم الهاتف: ${profile?.phone ?? ''}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        profile?.isSuspended == true ? 'الحساب موقوف' : (profile?.isPending == true ? 'قيد المراجعة' : 'حساب معلم نشط وموثق'),
                        style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.bold),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('البيانات الشخصية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        TextButton(
                          onPressed: () => setState(() => _editing = !_editing),
                          child: Text(_editing ? 'إلغاء' : 'تعديل'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_editing) ...[
                      ArtboardInputField(label: 'الاسم الكامل', controller: _fullName),
                      const SizedBox(height: 10),
                      ArtboardInputField(label: 'اسم المدرسة', controller: _schoolName),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: ArtboardInputField(label: 'الولاية', controller: _wilaya)),
                          const SizedBox(width: 8),
                          Expanded(child: ArtboardInputField(label: 'المقاطعة', controller: _moughataa)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('حفظ التعديلات'),
                        ),
                      ),
                    ] else ...[
                      _InfoRow(label: 'المدرسة', value: profile?.schoolName ?? '—'),
                      _InfoRow(label: 'الولاية', value: profile?.wilaya ?? '—'),
                      _InfoRow(label: 'المقاطعة', value: profile?.moughataa ?? '—'),
                      _InfoRow(label: 'الدليل المالي', value: profile?.financialIndex.isNotEmpty == true ? profile!.financialIndex : '—'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(Icons.palette, color: primary),
                title: const Text('لون التطبيق'),
                subtitle: const Text('اختر من بين 7 ألوان مختلفة', style: TextStyle(fontSize: 11)),
                trailing: CircleAvatar(radius: 12, backgroundColor: primary),
                onTap: _pickColorTheme,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(Icons.workspace_premium, color: primary),
                title: const Text('الاشتراك والعضوية'),
                subtitle: Text(profile?.subscriptionStatus ?? '', style: const TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_left),
                onTap: widget.onNavigateToSubscription,
              ),
            ),
            if (profile?.isAdmin == true) ...[
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(Icons.manage_accounts, color: primary),
                  title: const Text('إدارة المستخدمين'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: widget.onNavigateToAdminUsers,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmLogout,
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFD32F2F)),
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
