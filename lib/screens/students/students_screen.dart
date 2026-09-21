import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bottom_bar.dart';
import '../../widgets/app_main_bottom_bar.dart';

/// Mirrors ui/screens/students/StudentsScreen.kt — class tabs, search, and
/// full student CRUD. The AI collaborative-grouping helper and PDF/Excel
/// exports from the original screen are not yet wired to the new backend.
class StudentsScreen extends StatefulWidget {
  final int? initialClassId;
  final VoidCallback onNavigateToClasses;

  const StudentsScreen({super.key, this.initialClassId, required this.onNavigateToClasses});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _repo = AppRepository.instance;
  List<SchoolClass> _classes = [];
  List<Student> _students = [];
  int? _selectedClassId;
  String _search = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([_repo.getClasses(), _repo.getStudents()]);
      setState(() {
        _classes = results[0] as List<SchoolClass>;
        _students = results[1] as List<Student>;
      });
    } catch (_) {
      setState(() => _error = 'تعذر تحميل البيانات. تحقق من اتصال الخادم.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Student> get _filtered {
    var list = _selectedClassId == null
        ? _students
        : _students.where((s) => s.schoolClass == _selectedClassId).toList();
    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      list = list
          .where((s) =>
              s.fullName.toLowerCase().contains(q) ||
              s.studentCode.toLowerCase().contains(q) ||
              s.guardianName.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  SchoolClass? get _currentClass => _classes.where((c) => c.id == _selectedClassId).firstOrNull;

  Future<void> _showStudentDialog({Student? existing}) async {
    final nameController = TextEditingController(text: existing?.fullName ?? '');
    final guardianNameController = TextEditingController(text: existing?.guardianName ?? '');
    final guardianPhoneController = TextEditingController(text: existing?.guardianPhone ?? '');
    final healthController = TextEditingController(text: existing?.healthNotes ?? '');
    final pedagogicalController = TextEditingController(text: existing?.pedagogicalNotes ?? '');
    String gender = existing?.gender ?? 'ذكر';
    int? classId = existing?.schoolClass ?? _selectedClassId ?? _classes.firstOrNull?.id;

    if (classId == null) {
      _showError('يرجى إضافة قسم أولاً قبل إضافة التلاميذ');
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'إضافة تلميذ جديد' : 'تعديل بيانات التلميذ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('القسم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  initialValue: classId,
                  items: _classes
                      .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.gradeLevel})')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => classId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل للتلميذ'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: guardianNameController,
                        decoration: const InputDecoration(labelText: 'اسم الوكيل'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: guardianPhoneController,
                        decoration: const InputDecoration(labelText: 'هاتف الوكيل'),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('الجنس:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Radio<String>(
                      value: 'ذكر',
                      groupValue: gender,
                      onChanged: (v) => setDialogState(() => gender = v ?? gender),
                    ),
                    const Text('ذكر'),
                    Radio<String>(
                      value: 'أنثى',
                      groupValue: gender,
                      onChanged: (v) => setDialogState(() => gender = v ?? gender),
                    ),
                    const Text('أنثى'),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: healthController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'ملاحظات صحية خاصة (اختياري)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pedagogicalController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'ملاحظات تربوية/سلوكية خاصة (اختياري)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(existing == null ? 'حفظ التلميذ' : 'حفظ التعديل'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && nameController.text.trim().isNotEmpty && classId != null) {
      final student = Student(
        id: existing?.id ?? 0,
        schoolClass: classId!,
        fullName: nameController.text.trim(),
        studentCode: existing?.studentCode ?? '',
        guardianName: guardianNameController.text.trim(),
        guardianPhone: guardianPhoneController.text.trim(),
        gender: gender,
        healthNotes: healthController.text.trim(),
        pedagogicalNotes: pedagogicalController.text.trim(),
      );
      try {
        if (existing == null) {
          await _repo.createStudent(student);
        } else {
          await _repo.updateStudent(existing.id, student);
        }
        _load();
      } catch (_) {
        _showError('تعذر حفظ بيانات التلميذ');
      }
    }
  }

  Future<void> _confirmDelete(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('حذف التلميذ', style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف التلميذ «${student.fullName}»؟ سيتم حذف جميع بياناته المرتبطة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _repo.deleteStudent(student.id);
        _load();
      } catch (_) {
        _showError('تعذر حذف التلميذ');
      }
    }
  }

  Future<void> _callGuardian(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(title: const Text('سجل التلاميذ')),
      bottomNavigationBar: const AppMainBottomBar(current: BottomTab.sections),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStudentDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة تلميذ'),
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
                      SizedBox(
                        height: 64,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          children: [
                            _ClassTab(
                              label: 'الكل',
                              count: _students.length,
                              selected: _selectedClassId == null,
                              primaryColor: primary,
                              onTap: () => setState(() => _selectedClassId = null),
                            ),
                            ..._classes.map((c) => _ClassTab(
                                  label: c.name,
                                  count: _students.where((s) => s.schoolClass == c.id).length,
                                  selected: _selectedClassId == c.id,
                                  primaryColor: primary,
                                  onTap: () => setState(() => _selectedClassId = c.id),
                                )),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'بحث عن تلميذ...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text('قائمة التلاميذ (${_filtered.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            if (_currentClass != null) ...[
                              const SizedBox(width: 8),
                              Text('${_currentClass!.name} • ${_currentClass!.gradeLevel}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        child: _filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.people_outline, size: 48, color: Color(0xFF94A3B8)),
                                    const SizedBox(height: 10),
                                    Text(
                                      _search.isNotEmpty ? 'لم يتم العثور على نتائج للبحث' : 'لا يوجد تلاميذ مسجلين',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final student = _filtered[i];
                                  return _StudentCard(
                                    student: student,
                                    primaryColor: primary,
                                    onEdit: () => _showStudentDialog(existing: student),
                                    onDelete: () => _confirmDelete(student),
                                    onCall: student.guardianPhone.isNotEmpty
                                        ? () => _callGuardian(student.guardianPhone)
                                        : null,
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

class _ClassTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color primaryColor;
  final VoidCallback onTap;

  const _ClassTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? primaryColor : AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: selected ? Colors.white : AppColors.textPrimary)),
              Text('$count تلميذ',
                  style: TextStyle(fontSize: 10, color: selected ? Colors.white70 : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
  final Color primaryColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onCall;

  const _StudentCard({
    required this.student,
    required this.primaryColor,
    required this.onEdit,
    required this.onDelete,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: primaryColor.withValues(alpha: 0.15),
              child: Text(
                student.fullName.isNotEmpty ? student.fullName[0] : '?',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    student.guardianName.isNotEmpty ? 'الوكيل: ${student.guardianName}' : student.gender,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (onCall != null)
              IconButton(icon: Icon(Icons.call, color: primaryColor, size: 20), onPressed: onCall),
            IconButton(icon: Icon(Icons.edit, color: primaryColor, size: 20), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFEF5350)), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
