import 'package:flutter/material.dart';
import '../../core/mauritania_data.dart';
import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_colors.dart';

/// Mirrors ui/screens/subjects/SubjectsScreen.kt's grid view — a visual
/// entry point into the skills recorded per subject. Tapping a subject opens
/// SkillsScreen pre-filtered to it. The AI lesson-plan generation from the
/// original screen is not yet wired to the new backend.
class SubjectsScreen extends StatefulWidget {
  final void Function(String subject) onOpenSubject;

  const SubjectsScreen({super.key, required this.onOpenSubject});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final _repo = AppRepository.instance;
  bool _loading = true;
  String? _error;
  List<SchoolClass> _classes = [];
  int? _selectedClassId;
  List<Skill> _skills = [];

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
      final classes = await _repo.getClasses();
      final skills = await _repo.getSkills();
      setState(() {
        _classes = classes;
        _selectedClassId ??= classes.isNotEmpty ? classes.first.id : null;
        _skills = skills;
      });
    } catch (_) {
      setState(() => _error = 'تعذر تحميل البيانات. تحقق من اتصال الخادم.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  SchoolClass? get _currentClass => _classes.where((c) => c.id == _selectedClassId).firstOrNull;

  List<String> get _visibleSubjects => MauritaniaData.getSubjectsForGrade(_currentClass?.gradeLevel);

  int _skillCountFor(String subject) =>
      _skills.where((s) => s.subject == subject && (_selectedClassId == null || s.schoolClass == _selectedClassId)).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(title: const Text('المواد الدراسية')),
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
                      if (_classes.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Wrap(
                            spacing: 8,
                            children: _classes
                                .map((c) => ChoiceChip(
                                      label: Text(c.name, style: const TextStyle(fontSize: 12)),
                                      selected: _selectedClassId == c.id,
                                      onSelected: (_) => setState(() => _selectedClassId = c.id),
                                    ))
                                .toList(),
                          ),
                        ),
                      const Text('اختر مادة لعرض الكفايات وإضافتها:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.15,
                        children: _visibleSubjects
                            .map((subject) => _SubjectCard(
                                  subject: subject,
                                  emoji: MauritaniaData.subjectEmojis[subject] ?? '📘',
                                  skillCount: _skillCountFor(subject),
                                  onTap: () => widget.onOpenSubject(subject),
                                ))
                            .toList(),
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

class _SubjectCard extends StatelessWidget {
  final String subject;
  final String emoji;
  final int skillCount;
  final VoidCallback onTap;

  const _SubjectCard({required this.subject, required this.emoji, required this.skillCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('$skillCount كفايات', style: TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  const Text('دخول للمادة', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
