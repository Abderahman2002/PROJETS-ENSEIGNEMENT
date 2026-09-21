import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_colors.dart';

/// Mirrors ui/screens/reports/ParentReportsScreen.kt — manual monthly
/// progress report per student, sent individually to guardians via
/// WhatsApp. Bulk auto-dispatch from the original screen is not yet wired
/// to the new backend.
class ParentReportsScreen extends StatefulWidget {
  const ParentReportsScreen({super.key});

  @override
  State<ParentReportsScreen> createState() => _ParentReportsScreenState();
}

class _ParentReportsScreenState extends State<ParentReportsScreen> {
  final _repo = AppRepository.instance;
  bool _loading = true;
  String? _error;
  List<SchoolClass> _classes = [];
  List<Student> _students = [];
  List<MonthlyParentReport> _reports = [];
  int? _classFilter;
  String _search = '';

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
      final students = await _repo.getStudents();
      final reports = await _repo.getParentReports();
      setState(() {
        _classes = classes;
        _students = students;
        _reports = reports;
      });
    } catch (_) {
      setState(() => _error = 'تعذر تحميل التقارير. تحقق من اتصال الخادم.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MonthlyParentReport> get _filtered {
    var list = _classFilter == null ? _reports : _reports.where((r) => r.schoolClass == _classFilter).toList();
    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      list = list.where((r) => r.studentName.toLowerCase().contains(q) || r.guardianName.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> _showCreateDialog() async {
    if (_students.isEmpty) {
      _showError('يرجى إضافة تلاميذ أولاً');
      return;
    }
    Student student = _students.first;
    final monthController = TextEditingController();
    final progressController = TextEditingController();
    final attendanceController = TextEditingController();
    final evaluationController = TextEditingController();
    final difficultyController = TextEditingController();
    final recommendationsController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('إعداد تقرير شهري جديد'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('التلميذ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<Student>(
                    initialValue: student,
                    items: _students.map((s) => DropdownMenuItem(value: s, child: Text(s.fullName))).toList(),
                    onChanged: (v) => setDialogState(() => student = v ?? student),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: monthController, decoration: const InputDecoration(labelText: 'الشهر (مثال: أكتوبر 2026)')),
                  const SizedBox(height: 8),
                  TextField(controller: progressController, decoration: const InputDecoration(labelText: 'مستوى التقدم')),
                  const SizedBox(height: 8),
                  TextField(controller: attendanceController, decoration: const InputDecoration(labelText: 'ملخص الحضور')),
                  const SizedBox(height: 8),
                  TextField(controller: evaluationController, decoration: const InputDecoration(labelText: 'نتائج التقويم')),
                  const SizedBox(height: 8),
                  TextField(controller: difficultyController, decoration: const InputDecoration(labelText: 'الدروس التي بها صعوبات')),
                  const SizedBox(height: 8),
                  TextField(controller: recommendationsController, decoration: const InputDecoration(labelText: 'توصيات المعلم')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ التقرير')),
          ],
        ),
      ),
    );

    if (saved == true && monthController.text.trim().isNotEmpty) {
      try {
        await _repo.createParentReport(MonthlyParentReport(
          id: 0,
          schoolClass: student.schoolClass,
          student: student.id,
          monthYear: monthController.text.trim(),
          progressLevel: progressController.text.trim(),
          attendanceSummary: attendanceController.text.trim(),
          evaluationResults: evaluationController.text.trim(),
          difficultyLessons: difficultyController.text.trim(),
          teacherRecommendations: recommendationsController.text.trim(),
        ));
        _load();
      } catch (_) {
        _showError('تعذر حفظ التقرير');
      }
    }
  }

  Future<void> _sendWhatsapp(MonthlyParentReport report) async {
    final student = _students.where((s) => s.id == report.student).firstOrNull;
    final phone = student?.guardianPhone ?? '';
    if (phone.isEmpty) {
      _showError('لا يوجد رقم هاتف مسجل لولي الأمر');
      return;
    }
    final message = '''السلام عليكم ورحمة الله،
تقرير المتابعة الشهري للتلميذ(ة) ${report.studentName.isNotEmpty ? report.studentName : student?.fullName ?? ''} — ${report.monthYear}

مستوى التقدم: ${report.progressLevel}
الحضور: ${report.attendanceSummary}
نتائج التقويم: ${report.evaluationResults}
${report.difficultyLessons.isNotEmpty ? 'دروس تحتاج متابعة: ${report.difficultyLessons}\n' : ''}${report.teacherRecommendations.isNotEmpty ? 'توصيات المعلم: ${report.teacherRecommendations}' : ''}''';
    final uri = Uri.parse('https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('تعذر فتح واتساب');
    }
  }

  Future<void> _confirmDelete(MonthlyParentReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التقرير', style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
        content: const Text('هل تريد حذف هذا التقرير؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _repo.deleteParentReport(report.id);
        _load();
      } catch (_) {
        _showError('تعذر حذف التقرير');
      }
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(
        title: const Text('تقارير أولياء الأمور الشهرية'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('تقرير جديد'),
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
                            hintText: 'بحث بالاسم...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                      if (_classes.length > 1)
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: ChoiceChip(
                                  label: const Text('الكل', style: TextStyle(fontSize: 12)),
                                  selected: _classFilter == null,
                                  onSelected: (_) => setState(() => _classFilter = null),
                                ),
                              ),
                              ..._classes.map((c) => Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: ChoiceChip(
                                      label: Text(c.name, style: const TextStyle(fontSize: 12)),
                                      selected: _classFilter == c.id,
                                      onSelected: (_) => setState(() => _classFilter = c.id),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _filtered.isEmpty
                            ? const Center(child: Text('لا توجد تقارير بعد'))
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final report = _filtered[i];
                                  final student = _students.where((s) => s.id == report.student).firstOrNull;
                                  final name = report.studentName.isNotEmpty ? report.studentName : (student?.fullName ?? '');
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
                                              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF5350)),
                                                onPressed: () => _confirmDelete(report),
                                              ),
                                            ],
                                          ),
                                          Text(report.monthYear, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                          if (report.progressLevel.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text('التقدم: ${report.progressLevel}', style: const TextStyle(fontSize: 12)),
                                          ],
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _sendWhatsapp(report),
                                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                                              icon: const Icon(Icons.chat, size: 16),
                                              label: const Text('إرسال لولي الأمر عبر واتساب', style: TextStyle(fontSize: 12)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
