import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_colors.dart';

/// Mirrors ui/screens/calendar/CalendarScreen.kt — event CRUD with type
/// filters (اختبار / عطلة رسمية / اجتماع أولياء الأمور). Ported as a
/// chronological list rather than the original interactive month grid, to
/// keep the port scoped; the grid can be added later.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _repo = AppRepository.instance;
  final _dateFormat = DateFormat('yyyy-MM-dd');
  bool _loading = true;
  String? _error;
  List<CalendarEvent> _events = [];
  String _typeFilter = 'الكل';

  static const _types = ['اختبار', 'عطلة رسمية', 'اجتماع أولياء الأمور'];

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
      final events = await _repo.getCalendarEvents();
      setState(() => _events = events);
    } catch (_) {
      setState(() => _error = 'تعذر تحميل الأحداث. تحقق من اتصال الخادم.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CalendarEvent> get _filtered {
    final list = _typeFilter == 'الكل' ? _events : _events.where((e) => e.type == _typeFilter).toList();
    return [...list]..sort((a, b) => a.date.compareTo(b.date));
  }

  _EventVisual _visualFor(String type) {
    if (type.contains('اختبار') || type.contains('امتحان')) {
      return const _EventVisual(Color(0xFFDC2626), Color(0xFFFEF2F2), '📝');
    }
    if (type.contains('عطلة') || type.contains('عيد')) {
      return const _EventVisual(Color(0xFF16A34A), Color(0xFFF0FDF4), '🌴');
    }
    return const _EventVisual(Color(0xFF2563EB), Color(0xFFEFF6FF), '👥');
  }

  Future<void> _showEventDialog({CalendarEvent? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final locationController = TextEditingController(text: existing?.location ?? 'المدرسة');
    final descriptionController = TextEditingController(text: existing?.description ?? '');
    String type = existing?.type ?? _types.first;
    DateTime date = existing != null && existing.date.isNotEmpty
        ? DateTime.tryParse(existing.date) ?? DateTime.now()
        : DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'إضافة حدث جديد' : 'تعديل الحدث'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('نوع الحدث', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDialogState(() => type = v ?? type),
                ),
                const SizedBox(height: 10),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان الحدث')),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('التاريخ: ${_dateFormat.format(date)}'),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDialogState(() => date = picked);
                  },
                ),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'المكان')),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'وصف (اختياري)'),
                  maxLines: 2,
                ),
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

    if (saved == true && titleController.text.trim().isNotEmpty) {
      final event = CalendarEvent(
        id: existing?.id ?? 0,
        title: titleController.text.trim(),
        type: type,
        date: _dateFormat.format(date),
        location: locationController.text.trim(),
        description: descriptionController.text.trim(),
      );
      try {
        if (existing == null) {
          await _repo.createCalendarEvent(event);
        } else {
          await _repo.updateCalendarEvent(existing.id, event);
        }
        _load();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ الحدث')));
      }
    }
  }

  Future<void> _confirmDelete(CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحدث', style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف «${event.title}»؟'),
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
        await _repo.deleteCalendarEvent(event.id);
        _load();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حذف الحدث')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(title: const Text('التقويم والفعاليات المدرسية')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEventDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة حدث'),
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
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          children: ['الكل', ..._types]
                              .map((t) => Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: ChoiceChip(
                                      label: Text('$t (${t == 'الكل' ? _events.length : _events.where((e) => e.type == t).length})',
                                          style: const TextStyle(fontSize: 12)),
                                      selected: _typeFilter == t,
                                      onSelected: (_) => setState(() => _typeFilter = t),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      Expanded(
                        child: _filtered.isEmpty
                            ? const Center(child: Text('لا توجد أحداث مطابقة'))
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final event = _filtered[i];
                                  final visual = _visualFor(event.type);
                                  return Card(
                                    margin: EdgeInsets.zero,
                                    color: visual.bg,
                                    child: ListTile(
                                      leading: Text(visual.emoji, style: const TextStyle(fontSize: 22)),
                                      title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      subtitle: Text('${event.date} • ${event.location}',
                                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit, size: 18, color: visual.color),
                                            onPressed: () => _showEventDialog(existing: event),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF5350)),
                                            onPressed: () => _confirmDelete(event),
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

class _EventVisual {
  final Color color;
  final Color bg;
  final String emoji;
  const _EventVisual(this.color, this.bg, this.emoji);
}
