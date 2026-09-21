import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_colors.dart';

/// Mirrors ui/screens/timetable/TimetableScreen.kt — weekly slot CRUD
/// grouped by day. Excel export and lesson-reminder scheduling from the
/// original screen are not yet wired to the new backend.
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _repo = AppRepository.instance;
  bool _loading = true;
  String? _error;
  List<SchoolClass> _classes = [];
  List<TimetableSlot> _slots = [];

  static const _days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

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
      final slots = await _repo.getTimetableSlots();
      setState(() {
        _classes = classes;
        _slots = slots;
      });
    } catch (_) {
      setState(() => _error = 'تعذر تحميل الجدول. تحقق من اتصال الخادم.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<TimetableSlot> _slotsForDay(String day) {
    final list = _slots.where((s) => s.dayOfWeek == day).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  Future<void> _showSlotDialog({TimetableSlot? existing}) async {
    if (_classes.isEmpty) {
      _showError('يرجى إضافة قسم أولاً');
      return;
    }
    String day = existing?.dayOfWeek ?? _days.first;
    int classId = existing?.schoolClass ?? _classes.first.id;
    final subjectController = TextEditingController(text: existing?.subject ?? '');
    final lessonController = TextEditingController(text: existing?.lessonTitle ?? '');
    TimeOfDay start = existing != null
        ? TimeOfDay(hour: int.parse(existing.startTime.split(':')[0]), minute: int.parse(existing.startTime.split(':')[1]))
        : const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay end = existing != null
        ? TimeOfDay(hour: int.parse(existing.endTime.split(':')[0]), minute: int.parse(existing.endTime.split(':')[1]))
        : const TimeOfDay(hour: 9, minute: 0);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'إضافة حصة' : 'تعديل الحصة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اليوم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  initialValue: day,
                  items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setDialogState(() => day = v ?? day),
                ),
                const SizedBox(height: 10),
                const Text('القسم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                DropdownButtonFormField<int>(
                  initialValue: classId,
                  items: _classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setDialogState(() => classId = v ?? classId),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('من: ${start.format(context)}', style: const TextStyle(fontSize: 12)),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: start);
                          if (picked != null) setDialogState(() => start = picked);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('إلى: ${end.format(context)}', style: const TextStyle(fontSize: 12)),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: end);
                          if (picked != null) setDialogState(() => end = picked);
                        },
                      ),
                    ),
                  ],
                ),
                TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'المادة')),
                const SizedBox(height: 8),
                TextField(controller: lessonController, decoration: const InputDecoration(labelText: 'عنوان الدرس (اختياري)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );

    if (saved == true && subjectController.text.trim().isNotEmpty) {
      String fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      final slot = TimetableSlot(
        id: existing?.id ?? 0,
        dayOfWeek: day,
        startTime: fmt(start),
        endTime: fmt(end),
        schoolClass: classId,
        subject: subjectController.text.trim(),
        lessonTitle: lessonController.text.trim(),
      );
      try {
        if (existing == null) {
          await _repo.createTimetableSlot(slot);
        } else {
          await _repo.updateTimetableSlot(existing.id, slot);
        }
        _load();
      } catch (_) {
        _showError('تعذر حفظ الحصة');
      }
    }
  }

  Future<void> _confirmDelete(TimetableSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحصة', style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
        content: Text('هل تريد حذف حصة «${slot.subject}» يوم ${slot.dayOfWeek}؟'),
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
        await _repo.deleteTimetableSlot(slot.id);
        _load();
      } catch (_) {
        _showError('تعذر حذف الحصة');
      }
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  String _className(int classId) => _classes.where((c) => c.id == classId).firstOrNull?.name ?? '';

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(title: const Text('الجدول الأسبوعي للحصص')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSlotDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة حصة'),
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
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('${_slots.length} حصة مبرمجة في الأسبوع',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      ..._days.map((day) {
                        final slots = _slotsForDay(day);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(day, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primary)),
                              const SizedBox(height: 8),
                              if (slots.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  child: Text('لا توجد حصص مبرمجة', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                )
                              else
                                ...slots.map((slot) => Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: primary.withValues(alpha: 0.12),
                                          child: Text(slot.startTime.split(':')[0], style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                        title: Text(slot.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                        subtitle: Text(
                                          '${slot.startTime} - ${slot.endTime} • ${_className(slot.schoolClass)}${slot.lessonTitle.isNotEmpty ? ' • ${slot.lessonTitle}' : ''}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                                icon: Icon(Icons.edit, size: 18, color: primary),
                                                onPressed: () => _showSlotDialog(existing: slot)),
                                            IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF5350)),
                                                onPressed: () => _confirmDelete(slot)),
                                          ],
                                        ),
                                      ),
                                    )),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
