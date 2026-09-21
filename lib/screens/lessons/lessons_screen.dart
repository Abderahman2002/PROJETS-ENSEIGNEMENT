import 'package:flutter/material.dart';
import '../../core/mauritania_data.dart';
import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_colors.dart';

/// Mirrors ui/screens/lessons/LessonsScreen.kt's lesson-notebook core —
/// manual lesson entry (5-part plan: introduction, presentation, summary,
/// application, integration), completion/bag toggles, and delete. The
/// Gemini AI lesson generator, annual-plan scheduler, and exam generator
/// from the original screen are not yet wired to the new backend.
class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final _repo = AppRepository.instance;
  bool _loading = true;
  String? _error;
  List<SchoolClass> _classes = [];
  List<Lesson> _lessons = [];
  int _filterIndex = 0; // 0: all, 1: bag, 2: completed

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
      final lessons = await _repo.getLessons();
      setState(() {
        _classes = classes;
        _lessons = lessons;
      });
    } catch (_) {
      setState(() => _error = 'تعذر تحميل الدروس. تحقق من اتصال الخادم.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Lesson> get _filtered {
    switch (_filterIndex) {
      case 1:
        return _lessons.where((l) => l.addedToBag).toList();
      case 2:
        return _lessons.where((l) => l.isCompleted).toList();
      default:
        return _lessons;
    }
  }

  Future<void> _showLessonDialog({Lesson? existing}) async {
    if (_classes.isEmpty) {
      _showError('يرجى إضافة قسم أولاً');
      return;
    }
    int classId = existing?.schoolClass ?? _classes.first.id;
    String subject = existing?.subject.isNotEmpty == true ? existing!.subject : MauritaniaData.standardSubjects.first;
    final titleController = TextEditingController(text: existing?.title ?? '');
    final domainController = TextEditingController(text: existing?.domain ?? '');
    final introController = TextEditingController(text: existing?.introduction ?? '');
    final presentationController = TextEditingController(text: existing?.presentation ?? '');
    final applicationController = TextEditingController(text: existing?.application ?? '');
    final summaryController = TextEditingController(text: existing?.summary ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'إضافة درس جديد' : 'تعديل الدرس'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('القسم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<int>(
                    initialValue: classId,
                    items: _classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (v) => setDialogState(() => classId = v ?? classId),
                  ),
                  const SizedBox(height: 10),
                  const Text('المادة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    initialValue: subject,
                    items: MauritaniaData.standardSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setDialogState(() => subject = v ?? subject),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان الدرس')),
                  const SizedBox(height: 8),
                  TextField(controller: domainController, decoration: const InputDecoration(labelText: 'المجال')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: introController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: '1. التقديم والوضعيات التمهيدية'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: presentationController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: '2. العرض (خلاصة الدرس والقاعدة)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: applicationController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: '3. التطبيق (تمرين تطبيقي)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: summaryController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: '4. التقييم والإدماج النهائي'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ الدرس')),
          ],
        ),
      ),
    );

    if (saved == true && titleController.text.trim().isNotEmpty) {
      final cls = _classes.where((c) => c.id == classId).firstOrNull;
      final lesson = Lesson(
        id: existing?.id ?? 0,
        schoolClass: classId,
        subject: subject,
        gradeLevel: cls?.gradeLevel ?? '',
        domain: domainController.text.trim(),
        title: titleController.text.trim(),
        introduction: introController.text.trim(),
        presentation: presentationController.text.trim(),
        application: applicationController.text.trim(),
        summary: summaryController.text.trim(),
        isCompleted: existing?.isCompleted ?? false,
        addedToBag: existing?.addedToBag ?? false,
      );
      try {
        if (existing == null) {
          await _repo.createLesson(lesson);
        } else {
          await _repo.updateLesson(existing.id, lesson);
        }
        _load();
      } catch (_) {
        _showError('تعذر حفظ الدرس');
      }
    }
  }

  Future<void> _toggleCompleted(Lesson lesson) async {
    try {
      await _repo.updateLesson(lesson.id, Lesson(
        id: lesson.id,
        schoolClass: lesson.schoolClass,
        subject: lesson.subject,
        gradeLevel: lesson.gradeLevel,
        domain: lesson.domain,
        title: lesson.title,
        introduction: lesson.introduction,
        presentation: lesson.presentation,
        summary: lesson.summary,
        application: lesson.application,
        isCompleted: !lesson.isCompleted,
        addedToBag: lesson.addedToBag,
      ));
      _load();
    } catch (_) {}
  }

  Future<void> _toggleBag(Lesson lesson) async {
    try {
      await _repo.updateLesson(lesson.id, Lesson(
        id: lesson.id,
        schoolClass: lesson.schoolClass,
        subject: lesson.subject,
        gradeLevel: lesson.gradeLevel,
        domain: lesson.domain,
        title: lesson.title,
        introduction: lesson.introduction,
        presentation: lesson.presentation,
        summary: lesson.summary,
        application: lesson.application,
        isCompleted: lesson.isCompleted,
        addedToBag: !lesson.addedToBag,
      ));
      _load();
    } catch (_) {}
  }

  Future<void> _confirmDelete(Lesson lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الدرس', style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
        content: Text('هل تريد حذف درس «${lesson.title}»؟'),
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
        await _repo.deleteLesson(lesson.id);
        _load();
      } catch (_) {
        _showError('تعذر حذف الدرس');
      }
    }
  }

  void _showLessonDetail(Lesson lesson) {
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
                Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.primaryBlue)),
                Text('${lesson.subject} • ${lesson.domain}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const Divider(height: 20),
                if (lesson.introduction.isNotEmpty) _Section('1. التقديم', lesson.introduction, const Color(0xFFEFF6FF)),
                if (lesson.presentation.isNotEmpty) _Section('2. العرض', lesson.presentation, const Color(0xFFECFDF5)),
                if (lesson.application.isNotEmpty) _Section('3. التطبيق', lesson.application, const Color(0xFFFFFBEB)),
                if (lesson.summary.isNotEmpty) _Section('4. التقييم والإدماج', lesson.summary, const Color(0xFFF8FAFC)),
                const SizedBox(height: 12),
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

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(title: const Text('مفكرة الدروس')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLessonDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة درس'),
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
                        child: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 0, label: Text('الكل', style: TextStyle(fontSize: 12))),
                            ButtonSegment(value: 1, label: Text('الحقيبة', style: TextStyle(fontSize: 12))),
                            ButtonSegment(value: 2, label: Text('منجزة', style: TextStyle(fontSize: 12))),
                          ],
                          selected: {_filterIndex},
                          onSelectionChanged: (s) => setState(() => _filterIndex = s.first),
                        ),
                      ),
                      Expanded(
                        child: _filtered.isEmpty
                            ? const Center(child: Text('لا توجد دروس في هذا التصنيف'))
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final lesson = _filtered[i];
                                  return Card(
                                    margin: EdgeInsets.zero,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _showLessonDetail(lesson),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(lesson.title,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                ),
                                                if (lesson.isCompleted)
                                                  const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
                                              ],
                                            ),
                                            Text('${lesson.subject} • ${lesson.domain}',
                                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () => _toggleCompleted(lesson),
                                                  icon: Icon(lesson.isCompleted ? Icons.replay : Icons.check, size: 15),
                                                  label: Text(lesson.isCompleted ? 'إلغاء الإنجاز' : 'تعليم كمنجز',
                                                      style: const TextStyle(fontSize: 11)),
                                                ),
                                                TextButton.icon(
                                                  onPressed: () => _toggleBag(lesson),
                                                  icon: Icon(lesson.addedToBag ? Icons.bookmark : Icons.bookmark_border, size: 15),
                                                  label: Text(lesson.addedToBag ? 'في الحقيبة' : 'إضافة للحقيبة',
                                                      style: const TextStyle(fontSize: 11)),
                                                ),
                                                const Spacer(),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF5350)),
                                                  onPressed: () => _confirmDelete(lesson),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
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

class _Section extends StatelessWidget {
  final String title;
  final String content;
  final Color bg;

  const _Section(this.title, this.content, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }
}
