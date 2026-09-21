import 'package:flutter/material.dart';
import '../../core/mauritania_data.dart';
import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_colors.dart';

/// Mirrors ui/screens/grades/GradesScreen.kt — per-term grade roster with a
/// dynamic subject grid based on the class's grade level, live total/average
/// calculation, and a ranking computed client-side. The AI educational
/// analysis and PDF export from the original screen are not yet wired to the
/// new backend.
class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final _repo = AppRepository.instance;
  bool _loading = true;
  String? _error;

  List<SchoolClass> _classes = [];
  int? _selectedClassId;
  List<Student> _students = [];
  String _term = MauritaniaData.terms.first;
  List<StudentGrade> _grades = [];
  String _search = '';

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
      setState(() {
        _classes = classes;
        _selectedClassId ??= classes.isNotEmpty ? classes.first.id : null;
        _students = students;
      });
      await _loadGrades();
    } catch (_) {
      setState(() => _error = 'تعذر تحميل البيانات. تحقق من اتصال الخادم.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadGrades() async {
    if (_selectedClassId == null) return;
    final grades = await _repo.getGrades(classId: _selectedClassId!, term: _term);
    if (!mounted) return;
    setState(() => _grades = grades);
  }

  SchoolClass? get _currentClass => _classes.where((c) => c.id == _selectedClassId).firstOrNull;

  List<Student> get _classStudents =>
      _students.where((s) => s.schoolClass == _selectedClassId).toList();

  Map<int, StudentGrade> get _gradeMap => {for (final g in _grades) g.student: g};

  /// Highest average = rank 1, matching the Kotlin dynamicRankMap logic.
  Map<int, int> get _rankMap {
    final sorted = _grades.where((g) => g.average > 0 || g.totalScore > 0).toList()
      ..sort((a, b) {
        final byAvg = b.average.compareTo(a.average);
        if (byAvg != 0) return byAvg;
        return b.totalScore.compareTo(a.totalScore);
      });
    return {for (var i = 0; i < sorted.length; i++) sorted[i].student: i + 1};
  }

  List<Student> get _filteredStudents {
    var list = _classStudents;
    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      list = list.where((s) => s.fullName.toLowerCase().contains(q) || s.studentCode.toLowerCase().contains(q)).toList();
    }
    final gradeMap = _gradeMap;
    final rankMap = _rankMap;
    list = [...list]
      ..sort((a, b) {
        final ra = rankMap[a.id] ?? 9999;
        final rb = rankMap[b.id] ?? 9999;
        if (ra != rb) return ra.compareTo(rb);
        return (gradeMap[b.id]?.average ?? 0).compareTo(gradeMap[a.id]?.average ?? 0);
      });
    return list;
  }

  Future<void> _editGrade(Student student) async {
    final gradeLevel = _currentClass?.gradeLevel ?? MauritaniaData.schoolLevels[2];
    final subjects = MauritaniaData.getSubjectsForLevel(gradeLevel);
    final existing = _gradeMap[student.id];
    final controllers = {
      for (final s in subjects)
        s.code: TextEditingController(
          text: existing != null && existing.scoreForCode(s.code) > 0 ? existing.scoreForCode(s.code).toString() : '',
        )
    };
    final notesController = TextEditingController(text: existing?.teacherNotes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double total = 0;
          for (final s in subjects) {
            total += double.tryParse(controllers[s.code]!.text) ?? 0;
          }
          final average = (total / 200) * 20;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('رصد درجات: ${student.fullName}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: average >= 10 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('المجموع: ${total.toStringAsFixed(1)} / 200', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('المعدل: ${average.toStringAsFixed(2)} / 20',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: average >= 10 ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...subjects.map((rule) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(child: Text(rule.name, style: const TextStyle(fontSize: 13))),
                              SizedBox(
                                width: 90,
                                child: TextField(
                                  controller: controllers[rule.code],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: '/ ${rule.maxPoints.toStringAsFixed(0)}',
                                  ),
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                              ),
                            ],
                          ),
                        )),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'ملاحظة المعلم'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ واحتساب المعدل')),
            ],
          );
        },
      ),
    );

    if (saved == true && _selectedClassId != null) {
      double total = 0;
      final scores = <String, double>{};
      for (final s in subjects) {
        final v = double.tryParse(controllers[s.code]!.text) ?? 0;
        scores[s.code] = v;
        total += v;
      }
      final average = (total / 200) * 20;

      final grade = StudentGrade(
        id: existing?.id ?? 0,
        schoolClass: _selectedClassId!,
        student: student.id,
        term: _term,
        arabicScore: scores['arabic'] ?? 0,
        mathScore: scores['math'] ?? 0,
        scienceScore: scores['science'] ?? 0,
        islamicScore: scores['islamic'] ?? 0,
        frenchScore: scores['french'] ?? 0,
        historyScore: scores['history'] ?? 0,
        civicScore: scores['civic'] ?? 0,
        artScore: scores['art'] ?? 0,
        peScore: scores['pe'] ?? 0,
        totalScore: total,
        average: average,
        teacherNotes: notesController.text.trim(),
      );

      try {
        await _repo.upsertGrade(grade, existing: existing);
        _loadGrades();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ الدرجات')));
      }
    }
  }

  void _showReportCard(Student student) {
    final gradeLevel = _currentClass?.gradeLevel ?? MauritaniaData.schoolLevels[2];
    final subjects = MauritaniaData.getSubjectsForLevel(gradeLevel);
    final grade = _gradeMap[student.id];
    final rank = _rankMap[student.id] ?? grade?.rank ?? 0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('كشف درجات التلميذ — $_term', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('القسم: ${_currentClass?.name ?? ''} ($gradeLevel)', style: const TextStyle(fontSize: 12)),
                const Divider(height: 24),
                if (grade == null)
                  const Text('لم يتم رصد درجات لهذا التلميذ في هذا الفصل', style: TextStyle(color: AppColors.textSecondary))
                else ...[
                  ...subjects.map((rule) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(rule.name, style: const TextStyle(fontSize: 12.5)),
                            Text('${rule.scoreForCode(grade, rule.code).toStringAsFixed(0)} / ${rule.maxPoints.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المجموع العام', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${grade.totalScore.toStringAsFixed(0)} / 200',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المعدل الفصلي', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${grade.average.toStringAsFixed(2)} / 20',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: grade.average >= 10 ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الرتبة في القسم', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(rank > 0 ? '#$rank' : '—', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (grade.teacherNotes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('ملاحظات المعلم: ${grade.teacherNotes}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF2E7D32))),
                  ],
                ],
                const SizedBox(height: 16),
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
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final gradeMap = _gradeMap;
    final rankMap = _rankMap;
    final gradedCount = _classStudents.where((s) => gradeMap[s.id] != null).length;
    final passedCount = _classStudents.where((s) => (gradeMap[s.id]?.average ?? -1) >= 10).length;

    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(title: const Text('سجل النتائج والامتحانات')),
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
                                  setState(() => _selectedClassId = v);
                                  _loadGrades();
                                },
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 40,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: MauritaniaData.terms
                                      .map((t) => Padding(
                                            padding: const EdgeInsets.only(left: 8),
                                            child: ChoiceChip(
                                              label: Text(t, style: const TextStyle(fontSize: 12)),
                                              selected: _term == t,
                                              onSelected: (_) {
                                                setState(() => _term = t);
                                                _loadGrades();
                                              },
                                              selectedColor: primary,
                                              labelStyle: TextStyle(color: _term == t ? Colors.white : AppColors.textPrimary),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'بحث عن تلميذ بالاسم...',
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                ),
                                onChanged: (v) => setState(() => _search = v),
                              ),
                            ],
                          ),
                        ),
                        if (gradedCount > 0)
                          Container(
                            width: double.infinity,
                            color: const Color(0xFFEFF6FF),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'رُصد: $gradedCount/${_classStudents.length} • نسبة النجاح: ${(_classStudents.isNotEmpty ? passedCount / gradedCount * 100 : 0).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                            ),
                          ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadGrades,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredStudents.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final student = _filteredStudents[i];
                                final grade = gradeMap[student.id];
                                final rank = rankMap[student.id];
                                return _GradeCard(
                                  student: student,
                                  grade: grade,
                                  rank: rank,
                                  primaryColor: primary,
                                  onEdit: () => _editGrade(student),
                                  onViewReport: () => _showReportCard(student),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

extension _SubjectScore on SubjectRule {
  double scoreForCode(StudentGrade grade, String code) => grade.scoreForCode(code);
}

class _GradeCard extends StatelessWidget {
  final Student student;
  final StudentGrade? grade;
  final int? rank;
  final Color primaryColor;
  final VoidCallback onEdit;
  final VoidCallback onViewReport;

  const _GradeCard({
    required this.student,
    required this.grade,
    required this.rank,
    required this.primaryColor,
    required this.onEdit,
    required this.onViewReport,
  });

  @override
  Widget build(BuildContext context) {
    final isPassed = grade != null && grade!.average >= 10;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: grade == null ? AppColors.cardBorder : (isPassed ? const Color(0xFF86EFAC) : const Color(0xFFFECACA)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                if (rank != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                    child: Text('المرتبة #$rank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
                  ),
                const SizedBox(width: 6),
                if (grade != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPassed ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(isPassed ? 'ناجح' : 'راسب',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold, color: isPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                    child: const Text('بانتظار الرصد', style: TextStyle(fontSize: 11, color: Color(0xFFB45309))),
                  ),
              ],
            ),
            if (grade != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('المجموع: ${grade!.totalScore.toStringAsFixed(0)}/200', style: const TextStyle(fontSize: 11.5)),
                    Text('المعدل: ${grade!.average.toStringAsFixed(2)}/20',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 14),
                    label: Text(grade == null ? 'إضافة ورصد الدرجات' : 'تعديل الدرجات', style: const TextStyle(fontSize: 11.5)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewReport,
                    icon: const Icon(Icons.visibility, size: 14),
                    label: const Text('كشف النتيجة', style: TextStyle(fontSize: 11.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
