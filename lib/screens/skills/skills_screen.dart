import 'package:flutter/material.dart';
import '../../core/mauritania_data.dart';
import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_colors.dart';

/// Mirrors ui/screens/skills/SkillsScreen.kt — skill roster with subject
/// tabs and status cycling. The AI lesson-plan generation dialog from the
/// original screen (Gemini-backed) is not yet wired to the new backend.
class SkillsScreen extends StatefulWidget {
  final String? initialSubject;
  final void Function(int skillId) onNavigateToEvaluation;

  const SkillsScreen({super.key, this.initialSubject, required this.onNavigateToEvaluation});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final _repo = AppRepository.instance;
  bool _loading = true;
  String? _error;

  List<SchoolClass> _classes = [];
  int? _selectedClassId;
  List<Skill> _skills = [];
  late String _subjectFilter;

  @override
  void initState() {
    super.initState();
    _subjectFilter = widget.initialSubject ?? 'الكل';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classes = await _repo.getClasses();
      setState(() {
        _classes = classes;
        _selectedClassId ??= classes.isNotEmpty ? classes.first.id : null;
      });
      final skills = await _repo.getSkills();
      setState(() => _skills = skills);
    } catch (_) {
      setState(() => _error = 'تعذر تحميل البيانات. تحقق من اتصال الخادم.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  SchoolClass? get _currentClass => _classes.where((c) => c.id == _selectedClassId).firstOrNull;

  List<String> get _subjectTabs => ['الكل', ...MauritaniaData.getSubjectsForGrade(_currentClass?.gradeLevel)];

  List<Skill> get _filteredSkills => _skills
      .where((s) =>
          (_subjectFilter == 'الكل' || s.subject == _subjectFilter) &&
          (_selectedClassId == null || s.schoolClass == _selectedClassId))
      .toList();

  Future<void> _cycleStatus(Skill skill) async {
    const order = ['مخطط لها', 'قيد التنفيذ', 'تم الإنجاز'];
    final next = order[(order.indexOf(skill.status) + 1) % order.length];
    try {
      await _repo.updateSkill(
        skill.id,
        Skill(
          id: skill.id,
          schoolClass: skill.schoolClass,
          subject: skill.subject,
          title: skill.title,
          description: skill.description,
          term: skill.term,
          priority: skill.priority,
          domain: skill.domain,
          status: next,
        ),
      );
      _load();
    } catch (_) {}
  }

  Future<void> _showSkillDialog({Skill? existing}) async {
    final subject = existing?.subject ?? (_subjectFilter != 'الكل' ? _subjectFilter : MauritaniaData.standardSubjects.first);
    final domainOptions = MauritaniaData.getDomainOptionsForSubject(subject);
    String domain = existing?.domain.isNotEmpty == true ? existing!.domain : domainOptions.first;
    String subjectValue = subject;
    int? classId = existing?.schoolClass ?? _selectedClassId ?? _classes.firstOrNull?.id;
    final titleController = TextEditingController(text: existing?.title ?? '');

    if (classId == null) {
      _showError('يرجى إضافة قسم أولاً');
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentDomains = MauritaniaData.getDomainOptionsForSubject(subjectValue);
          if (!currentDomains.contains(domain)) domain = currentDomains.first;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(existing == null ? 'إضافة مهارة جديدة' : 'تعديل المهارة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('القسم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<int>(
                    initialValue: classId,
                    items: _classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (v) => setDialogState(() => classId = v),
                  ),
                  const SizedBox(height: 10),
                  const Text('المادة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    initialValue: subjectValue,
                    items: MauritaniaData.standardSubjects
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => subjectValue = v ?? subjectValue),
                  ),
                  const SizedBox(height: 10),
                  const Text('المجال', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    initialValue: domain,
                    items: currentDomains.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setDialogState(() => domain = v ?? domain),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'عنوان الدرس'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(existing == null ? 'إضافة المهارة' : 'حفظ التعديل'),
              ),
            ],
          );
        },
      ),
    );

    if (saved == true && titleController.text.trim().isNotEmpty && classId != null) {
      try {
        if (existing == null) {
          await _repo.createSkill(Skill(
            id: 0,
            schoolClass: classId!,
            subject: subjectValue,
            title: titleController.text.trim(),
            domain: domain,
          ));
        } else {
          await _repo.updateSkill(
            existing.id,
            Skill(
              id: existing.id,
              schoolClass: classId!,
              subject: subjectValue,
              title: titleController.text.trim(),
              domain: domain,
              term: existing.term,
              priority: existing.priority,
              status: existing.status,
            ),
          );
        }
        _load();
      } catch (_) {
        _showError('تعذر حفظ المهارة');
      }
    }
  }

  Future<void> _confirmDelete(Skill skill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد حذف المهارة', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف مهارة «${skill.title}» في مادة ${skill.subject}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _repo.deleteSkill(skill.id);
        _load();
      } catch (_) {
        _showError('تعذر حذف المهارة');
      }
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(title: const Text('سجل الكفايات والمهارات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSkillDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة مهارة'),
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
                      if (_classes.length > 1)
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            children: _classes
                                .map((c) => Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: ChoiceChip(
                                        label: Text(c.name, style: const TextStyle(fontSize: 12)),
                                        selected: _selectedClassId == c.id,
                                        onSelected: (_) => setState(() => _selectedClassId = c.id),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: _subjectTabs
                              .map((s) => Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: ChoiceChip(
                                      label: Text(s, style: const TextStyle(fontSize: 12)),
                                      selected: _subjectFilter == s,
                                      onSelected: (_) => setState(() => _subjectFilter = s),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('بطاقات المهارات (${_filteredSkills.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      Expanded(
                        child: _filteredSkills.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.lightbulb_outline, size: 56, color: Color(0xFFCBD5E1)),
                                    const SizedBox(height: 8),
                                    const Text('لا توجد مهارات مسجلة في هذا التحديد'),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                                itemCount: _filteredSkills.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final skill = _filteredSkills[i];
                                  return _SkillCard(
                                    skill: skill,
                                    onToggleStatus: () => _cycleStatus(skill),
                                    onEdit: () => _showSkillDialog(existing: skill),
                                    onDelete: () => _confirmDelete(skill),
                                    onEvaluate: () => widget.onNavigateToEvaluation(skill.id),
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _SkillCard extends StatelessWidget {
  final Skill skill;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onEvaluate;

  const _SkillCard({
    required this.skill,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
    required this.onEvaluate,
  });

  Color get _statusColor {
    switch (skill.status) {
      case 'تم الإنجاز':
        return const Color(0xFF2E7D32);
      case 'قيد التنفيذ':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFFE65100);
    }
  }

  Color get _statusBg {
    switch (skill.status) {
      case 'تم الإنجاز':
        return const Color(0xFFE8F5E9);
      case 'قيد التنفيذ':
        return const Color(0xFFE3F2FD);
      default:
        return const Color(0xFFFFF3E0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                  child: Text(skill.domain.isNotEmpty ? skill.domain : 'المجال الأساسي',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                ),
                InkWell(
                  onTap: onToggleStatus,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(skill.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(skill.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(skill.subject, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEvaluate,
                    child: const Text('تقويم', style: TextStyle(fontSize: 11.5)),
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryBlue), onPressed: onEdit),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF5350)), onPressed: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
