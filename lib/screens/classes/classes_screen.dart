import 'package:flutter/material.dart';
import '../../core/mauritania_data.dart';
import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bottom_bar.dart';
import '../../widgets/app_main_bottom_bar.dart';

/// Mirrors ui/screens/classes/ClassesScreen.kt — list, add, edit, delete
/// classes, with a grade-level filter. PDF/Excel roster export from the
/// original screen is not yet wired to the new backend.
class ClassesScreen extends StatefulWidget {
  final void Function(int? classId) onNavigateToStudents;

  const ClassesScreen({super.key, required this.onNavigateToStudents});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _repo = AppRepository.instance;
  List<SchoolClass> _classes = [];
  bool _loading = true;
  String? _error;
  String _gradeFilter = 'ALL';

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
      setState(() => _classes = classes);
    } catch (_) {
      setState(() => _error = 'تعذر تحميل الأقسام. تحقق من اتصال الخادم.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _distinctGrades => _classes.map((c) => c.gradeLevel).toSet().toList();

  List<SchoolClass> get _displayClasses =>
      _gradeFilter == 'ALL' ? _classes : _classes.where((c) => c.gradeLevel == _gradeFilter).toList();

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    String grade = MauritaniaData.schoolLevels.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('إضافة قسم جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('المستوى الدراسي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: grade,
                items: MauritaniaData.schoolLevels
                    .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                    .toList(),
                onChanged: (v) => setDialogState(() => grade = v ?? grade),
              ),
              const SizedBox(height: 12),
              const Text('اسم أو رمز القسم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'مثال: القسم 3 أ'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حفظ القسم'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      try {
        await _repo.createClass(name: nameController.text.trim(), gradeLevel: grade);
        _load();
      } catch (_) {
        _showError('تعذر إضافة القسم');
      }
    }
  }

  Future<void> _showEditDialog(SchoolClass cls) async {
    final nameController = TextEditingController(text: cls.name);
    String grade = cls.gradeLevel;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تعديل بيانات القسم'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('المستوى الدراسي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: grade,
                items: MauritaniaData.schoolLevels
                    .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                    .toList(),
                onChanged: (v) => setDialogState(() => grade = v ?? grade),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameController),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ التعديل')),
          ],
        ),
      ),
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      try {
        await _repo.updateClass(cls.id, name: nameController.text.trim(), gradeLevel: grade);
        _load();
      } catch (_) {
        _showError('تعذر تعديل القسم');
      }
    }
  }

  Future<void> _confirmDelete(SchoolClass cls) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('تأكيد حذف القسم', style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من حذف هذا القسم؟ سيتم حذف البيانات المرتبطة به.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف القسم'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repo.deleteClass(cls.id);
        _load();
      } catch (_) {
        _showError('تعذر حذف القسم');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final totalStudents = _classes.fold<int>(0, (sum, c) => sum + c.studentCount);

    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(title: const Text('إدارة الأقسام والتلاميذ')),
      bottomNavigationBar: const AppMainBottomBar(current: BottomTab.sections),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('إضافة قسم'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('مجموع الأقسام: ${_classes.length}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text('إجمالي التلاميذ المسجلين: $totalStudents تلميذ',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_distinctGrades.length > 1)
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _FilterChipButton(
                                label: 'الكل (${_classes.length})',
                                selected: _gradeFilter == 'ALL',
                                onTap: () => setState(() => _gradeFilter = 'ALL'),
                              ),
                              ..._distinctGrades.map((grade) {
                                final count = _classes.where((c) => c.gradeLevel == grade).length;
                                return _FilterChipButton(
                                  label: '$grade ($count)',
                                  selected: _gradeFilter == grade,
                                  onTap: () => setState(() => _gradeFilter = grade),
                                );
                              }),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text('بطاقات الأقسام (${_displayClasses.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 10),
                      if (_displayClasses.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              const Icon(Icons.groups, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 10),
                              const Text('لا توجد أقسام مطابقة للفلتر المحدد',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('اضغط على زر «إضافة قسم» لإضافة قسم جديد.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      else
                        ..._displayClasses.map((cls) => _ClassCard(
                              schoolClass: cls,
                              primaryColor: primary,
                              onTap: () => widget.onNavigateToStudents(cls.id),
                              onEdit: () => _showEditDialog(cls),
                              onDelete: () => _confirmDelete(cls),
                            )),
                      const SizedBox(height: 80),
                    ],
                  ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: primary,
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final SchoolClass schoolClass;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClassCard({
    required this.schoolClass,
    required this.primaryColor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 23,
                        backgroundColor: primaryColor.withValues(alpha: 0.15),
                        child: Icon(Icons.groups, color: primaryColor),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(schoolClass.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(schoolClass.gradeLevel,
                                style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(icon: Icon(Icons.edit, color: primaryColor, size: 20), onPressed: onEdit),
                      IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFEF5350)), onPressed: onDelete),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${schoolClass.studentCount} تلميذ',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor.withValues(alpha: 0.12),
                    foregroundColor: primaryColor,
                    elevation: 0,
                    minimumSize: const Size(0, 36),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 14),
                  label: const Text('عرض التلاميذ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}
