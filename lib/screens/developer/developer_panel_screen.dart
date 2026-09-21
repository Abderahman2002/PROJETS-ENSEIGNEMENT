import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_repository.dart';
import '../../theme/app_colors.dart';

/// Mirrors ui/screens/developer/DeveloperPanelScreen.kt — admin-only teacher
/// directory with subscription/account management and an audit log.
/// AdminUsersScreen.kt forwards to this same screen in the original app, so
/// both `/developer-panel` and `/admin-users` route here.
class DeveloperPanelScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const DeveloperPanelScreen({super.key, required this.onLogout});

  @override
  State<DeveloperPanelScreen> createState() => _DeveloperPanelScreenState();
}

class _DeveloperPanelScreenState extends State<DeveloperPanelScreen> {
  final _repo = AppRepository.instance;
  bool _loading = true;
  String? _error;
  List<AdminTeacher> _teachers = [];
  String _search = '';
  String _filter = 'الكل';

  static const _filters = ['الكل', 'الحسابات النشطة', 'الحسابات المعطلة', 'التجربة المجانية', 'الاشتراكات النشطة', 'الاشتراكات المنتهية'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final teachers = await _repo.getAdminTeachers();
      setState(() => _teachers = teachers);
    } catch (_) {
      setState(() => _error = 'تعذر تحميل قائمة المعلمين. تأكد أن حسابك بصلاحية مدير.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AdminTeacher> get _filtered {
    var list = _teachers;
    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      list = list.where((t) => t.fullName.toLowerCase().contains(q) || t.phone.contains(q)).toList();
    }
    switch (_filter) {
      case 'الحسابات النشطة':
        return list.where((t) => t.accountStatus == 'active').toList();
      case 'الحسابات المعطلة':
        return list.where((t) => t.accountStatus == 'disabled' || t.accountStatus == 'suspended').toList();
      case 'التجربة المجانية':
        return list.where((t) => t.subscriptionStatus == 'TRIAL').toList();
      case 'الاشتراكات النشطة':
        return list.where((t) => t.subscriptionStatus == 'ACTIVE').toList();
      case 'الاشتراكات المنتهية':
        return list.where((t) => t.subscriptionStatus == 'EXPIRED').toList();
      default:
        return list;
    }
  }

  Future<void> _activateSubscription(AdminTeacher teacher) async {
    final controller = TextEditingController(text: '365');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفعيل اشتراك ${teacher.fullName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'عدد أيام الاشتراك'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تفعيل')),
        ],
      ),
    );
    if (saved == true) {
      try {
        await _repo.activateSubscription(teacher.id, durationDays: int.tryParse(controller.text) ?? 365);
        _load();
      } catch (_) {
        _showError('تعذر تفعيل الاشتراك');
      }
    }
  }

  Future<void> _extendSubscription(AdminTeacher teacher) async {
    final controller = TextEditingController(text: '30');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تمديد اشتراك ${teacher.fullName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'عدد أيام التمديد'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تمديد')),
        ],
      ),
    );
    if (saved == true) {
      try {
        await _repo.extendSubscription(teacher.id, durationDays: int.tryParse(controller.text) ?? 30);
        _load();
      } catch (_) {
        _showError('تعذر تمديد الاشتراك');
      }
    }
  }

  Future<void> _toggleAccount(AdminTeacher teacher) async {
    final disabling = teacher.accountStatus == 'active' || teacher.accountStatus == 'pending';
    String reason = '';
    if (disabling) {
      final controller = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('تعطيل حساب ${teacher.fullName}'),
          content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'سبب التعطيل')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تعطيل'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      reason = controller.text.trim();
    }
    try {
      if (disabling) {
        await _repo.disableAccount(teacher.id, reason: reason);
      } else {
        await _repo.activateAccount(teacher.id);
      }
      _load();
    } catch (_) {
      _showError('تعذر تحديث حالة الحساب');
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _showAuditLog() async {
    try {
      final log = await _repo.getAdminActionLog();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('سجل إجراءات الإدارة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: log.isEmpty
                        ? const Center(child: Text('لا توجد إجراءات مسجلة بعد'))
                        : ListView.separated(
                            itemCount: log.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, i) {
                              final entry = log[i];
                              return ListTile(
                                dense: true,
                                title: Text('${entry.teacherName} — ${entry.actionType}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                subtitle: Text('${entry.oldValue} → ${entry.newValue}${entry.note.isNotEmpty ? " • ${entry.note}" : ""}',
                                    style: const TextStyle(fontSize: 11)),
                              );
                            },
                          ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (_) {
      _showError('تعذر تحميل السجل');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().teacherProfile?.isAdmin ?? false;

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.iceBackground,
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block, color: Color(0xFFEF4444), size: 54),
                  const SizedBox(height: 14),
                  const Text('غير مصرح بالوصول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'هذه اللوحة مخصصة لإدارة النظام ومطوّري تطبيق رفيق المعلم فقط، وتتطلب حساباً بصلاحية مدير.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('الرجوع للخلف')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(
        title: const Text('لوحة تحكم المطور'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: _showAuditLog, tooltip: 'سجل الإجراءات'),
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout, tooltip: 'تسجيل الخروج'),
        ],
      ),
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
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'بحث بالاسم أو الهاتف...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: _filters
                              .map((f) => Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: ChoiceChip(
                                      label: Text(f, style: const TextStyle(fontSize: 11.5)),
                                      selected: _filter == f,
                                      onSelected: (_) => setState(() => _filter = f),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _filtered.isEmpty
                            ? const Center(child: Text('لا يوجد معلمون مطابقون'))
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final teacher = _filtered[i];
                                  return _TeacherCard(
                                    teacher: teacher,
                                    onActivate: () => _activateSubscription(teacher),
                                    onExtend: () => _extendSubscription(teacher),
                                    onToggleAccount: () => _toggleAccount(teacher),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final AdminTeacher teacher;
  final VoidCallback onActivate;
  final VoidCallback onExtend;
  final VoidCallback onToggleAccount;

  const _TeacherCard({required this.teacher, required this.onActivate, required this.onExtend, required this.onToggleAccount});

  Color get _statusColor {
    switch (teacher.subscriptionStatus) {
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
    final disabled = teacher.accountStatus == 'disabled' || teacher.accountStatus == 'suspended';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(teacher.fullName.isNotEmpty ? teacher.fullName : teacher.phone,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${teacher.phone} • ${teacher.schoolName}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(teacher.subscriptionStatus, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: _statusColor)),
                ),
              ],
            ),
            if (disabled)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('الحساب معطل', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton(onPressed: onActivate, child: const Text('تفعيل اشتراك', style: TextStyle(fontSize: 11))),
                OutlinedButton(onPressed: onExtend, child: const Text('تمديد', style: TextStyle(fontSize: 11))),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: disabled ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                  onPressed: onToggleAccount,
                  child: Text(disabled ? 'تفعيل الحساب' : 'تعطيل الحساب', style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
