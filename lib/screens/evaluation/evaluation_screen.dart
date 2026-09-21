import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_colors.dart';

/// Mirrors ui/screens/evaluation/EvaluationScreen.kt's core purpose — rate
/// each student on a chosen skill (متقن / في طور الاكتساب / غير مكتسب). The
/// original screen evaluates completed *lessons*; this ports it against the
/// simpler Skill model already wired to the backend. PDF export/print/share
/// from the original screen are not yet wired to the new backend.
class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final _repo = AppRepository.instance;
  bool _loading = true;
  String? _error;

  List<SchoolClass> _classes = [];
  int? _selectedClassId;
  List<Student> _students = [];
  List<Skill> _skills = [];
  int? _selectedSkillId;
  List<SkillEvaluation> _evaluations = [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classes = await _repo.getClasses();
      final students = await _repo.getStudents();
      final skills = await _repo.getSkills();
      setState(() {
        _classes = classes;
        _selectedClassId ??= classes.isNotEmpty ? classes.first.id : null;
        _students = students;
        _skills = skills;
        _selectedSkillId ??= _classSkills.isNotEmpty ? _classSkills.first.id : null;
      });
      await _loadEvaluations();
    } catch (_) {
      setState(() => _error = 'تعذر تحميل البيانات. تحقق من اتصال الخادم.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Skill> get _classSkills => _skills.where((s) => s.schoolClass == _selectedClassId).toList();

  List<Student> get _classStudents => _students.where((s) => s.schoolClass == _selectedClassId).toList();

  Skill? get _currentSkill => _classSkills.where((s) => s.id == _selectedSkillId).firstOrNull;

  Future<void> _loadEvaluations() async {
    if (_selectedSkillId == null) {
      setState(() => _evaluations = []);
      return;
    }
    final evals = await _repo.getSkillEvaluations(skillId: _selectedSkillId!);
    if (!mounted) return;
    setState(() => _evaluations = evals);
  }

  Map<int, SkillEvaluation> get _evalMap => {for (final e in _evaluations) e.student: e};

  Future<void> _rate(Student student, String rating) async {
    if (_selectedSkillId == null || _selectedClassId == null) return;
    final existing = _evalMap[student.id];
    try {
      await _repo.upsertSkillEvaluation(
        SkillEvaluation(
          id: existing?.id ?? 0,
          skill: _selectedSkillId!,
          student: student.id,
          schoolClass: _selectedClassId!,
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          rating: rating,
        ),
        existing: existing,
      );
      _loadEvaluations();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ التقييم')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final evalMap = _evalMap;
    final mastered = evalMap.values.where((e) => e.rating == 'متقن').length;
    final acquiring = evalMap.values.where((e) => e.rating == 'في طور الاكتساب').length;
    final notAcquired = evalMap.values.where((e) => e.rating == 'غير مكتسب').length;

    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(title: const Text('تقويم التلاميذ على المهارات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadInitial, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                )
              : _classes.isEmpty
                  ? const Center(child: Text('يرجى إضافة قسم أولاً من شاشة الأقسام'))
                  : Column(
                      children: [
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              DropdownButtonFormField<int>(
                                initialValue: _selectedClassId,
                                decoration: const InputDecoration(labelText: 'القسم'),
                                items: _classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                onChanged: (v) {
                                  setState(() {
                                    _selectedClassId = v;
                                    _selectedSkillId = _classSkills.isNotEmpty ? _classSkills.first.id : null;
                                  });
                                  _loadEvaluations();
                                },
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                initialValue: _selectedSkillId,
                                decoration: const InputDecoration(labelText: 'اختر المهارة/الدرس للتقييم'),
                                items: _classSkills
                                    .map((s) => DropdownMenuItem(value: s.id, child: Text(s.title, overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() => _selectedSkillId = v);
                                  _loadEvaluations();
                                },
                              ),
                            ],
                          ),
                        ),
                        if (_currentSkill == null)
                          const Expanded(
                            child: Center(child: Text('لا توجد مهارات مسجلة لهذا القسم بعد. أضف مهارة من شاشة المهارات.')),
                          )
                        else ...[
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                _StatBox(label: 'متقن', value: '$mastered', color: AppColors.skillMastered),
                                const SizedBox(width: 8),
                                _StatBox(label: 'في طور الاكتساب', value: '$acquiring', color: AppColors.skillAcquiring),
                                const SizedBox(width: 8),
                                _StatBox(label: 'غير مكتسب', value: '$notAcquired', color: AppColors.skillNotAcquired),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _classStudents.isEmpty
                                ? const Center(child: Text('لا يوجد تلاميذ في هذا القسم'))
                                : RefreshIndicator(
                                    onRefresh: _loadEvaluations,
                                    child: ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      itemCount: _classStudents.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, i) {
                                        final student = _classStudents[i];
                                        final rating = evalMap[student.id]?.rating;
                                        return Card(
                                          margin: EdgeInsets.zero,
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    _RatingChip(
                                                      label: 'متقن',
                                                      color: AppColors.skillMastered,
                                                      selected: rating == 'متقن',
                                                      onTap: () => _rate(student, 'متقن'),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    _RatingChip(
                                                      label: 'في طور الاكتساب',
                                                      color: AppColors.skillAcquiring,
                                                      selected: rating == 'في طور الاكتساب',
                                                      onTap: () => _rate(student, 'في طور الاكتساب'),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    _RatingChip(
                                                      label: 'غير مكتسب',
                                                      color: AppColors.skillNotAcquired,
                                                      selected: rating == 'غير مكتسب',
                                                      onTap: () => _rate(student, 'غير مكتسب'),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ],
                    ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text(value, style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RatingChip({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: selected ? Colors.white : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}
