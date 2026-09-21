import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_colors.dart';

/// Mirrors ui/screens/attendance/AttendanceScreen.kt — daily roll call plus
/// a monthly attendance analysis tab. PDF/Excel export from the original
/// screen is not yet wired to the new backend.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _repo = AppRepository.instance;
  final _dateFormat = DateFormat('yyyy-MM-dd');

  bool _isMonthlyTab = false;
  bool _loading = true;
  String? _error;

  List<SchoolClass> _classes = [];
  int? _selectedClassId;
  List<Student> _students = [];
  DateTime _selectedDate = DateTime.now();
  List<AttendanceRecord> _dayRecords = [];
  List<AttendanceRecord> _monthRecords = [];

  @override
  void initState() {
    super.initState();
    _loadClassesAndStudents();
  }

  Future<void> _loadClassesAndStudents() async {
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
      await _loadAttendance();
    } catch (_) {
      setState(() => _error = 'تعذر تحميل البيانات. تحقق من اتصال الخادم.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Student> get _classStudents =>
      _students.where((s) => s.schoolClass == _selectedClassId).toList();

  Future<void> _loadAttendance() async {
    if (_selectedClassId == null) return;
    final dayRecords = await _repo.getAttendanceForClass(_selectedClassId!, date: _dateFormat.format(_selectedDate));
    final monthRecords = await _repo.getAttendanceForClass(_selectedClassId!);
    if (!mounted) return;
    setState(() {
      _dayRecords = dayRecords;
      _monthRecords = monthRecords;
    });
  }

  Map<int, AttendanceRecord> get _dayMap => {for (final r in _dayRecords) r.student: r};

  Future<void> _setStatus(Student student, String status) async {
    final existing = _dayMap[student.id];
    try {
      await _repo.upsertAttendance(
        classId: _selectedClassId!,
        studentId: student.id,
        date: _dateFormat.format(_selectedDate),
        status: status,
        existing: existing,
      );
      _loadAttendance();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ الحالة')));
    }
  }

  Future<void> _markAllPresent() async {
    for (final student in _classStudents) {
      final existing = _dayMap[student.id];
      if (existing?.status != 'حاضر') {
        await _repo.upsertAttendance(
          classId: _selectedClassId!,
          studentId: student.id,
          date: _dateFormat.format(_selectedDate),
          status: 'حاضر',
          existing: existing,
        );
      }
    }
    _loadAttendance();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadAttendance();
    }
  }

  Future<void> _callGuardian(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.isNotEmpty ? phone : '36123456');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(title: const Text('سجل النداء والمواظبة المدرسية')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadClassesAndStudents, child: const Text('إعادة المحاولة')),
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
                                items: _classes
                                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() => _selectedClassId = v);
                                  _loadAttendance();
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _TabButton(
                                      label: 'النداء اليومي',
                                      icon: Icons.fact_check,
                                      selected: !_isMonthlyTab,
                                      primaryColor: primary,
                                      onTap: () => setState(() => _isMonthlyTab = false),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _TabButton(
                                      label: 'تحليل شهري',
                                      icon: Icons.analytics,
                                      selected: _isMonthlyTab,
                                      primaryColor: primary,
                                      onTap: () => setState(() => _isMonthlyTab = true),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _isMonthlyTab ? _buildMonthly(primary) : _buildDaily(primary),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildDaily(Color primary) {
    final dayMap = _dayMap;
    final present = dayMap.values.where((r) => r.status == 'حاضر').length;
    final absent = dayMap.values.where((r) => r.status == 'غائب').length;
    final late = dayMap.values.where((r) => r.status == 'متأخر').length;
    final rate = _classStudents.isNotEmpty ? (present * 100 ~/ _classStudents.length) : 100;

    return RefreshIndicator(
      onRefresh: _loadAttendance,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('تاريخ النداء والحضور', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      TextButton(
                        onPressed: _pickDate,
                        child: Text(_dateFormat.format(_selectedDate),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primary)),
                      ),
                    ],
                  ),
                  if (_classStudents.isNotEmpty)
                    FilledButton.tonalIcon(
                      onPressed: _markAllPresent,
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('حضور الجميع', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatBox(label: 'حاضر', value: '$present', color: AppColors.attendancePresent),
              const SizedBox(width: 8),
              _StatBox(label: 'غائب', value: '$absent', color: AppColors.attendanceAbsent),
              const SizedBox(width: 8),
              _StatBox(label: 'متأخر', value: '$late', color: AppColors.attendanceLate),
              const SizedBox(width: 8),
              _StatBox(label: 'نسبة الحضور', value: '$rate%', color: primary),
            ],
          ),
          const SizedBox(height: 12),
          if (_classStudents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('لا يوجد تلاميذ مسجلون في هذا القسم بعد.')),
            )
          else
            ..._classStudents.map((student) {
              final status = dayMap[student.id]?.status ?? 'حاضر';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: _statusColor(status).withValues(alpha: 0.15),
                        child: Text(student.fullName.isNotEmpty ? student.fullName[0] : '?',
                            style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            Text('ولي الأمر: ${student.guardianPhone.isNotEmpty ? student.guardianPhone : "غير مسجل"}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      _StatusToggle(current: status, onSelected: (s) => _setStatus(student, s)),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMonthly(Color primary) {
    final present = _monthRecords.where((r) => r.status == 'حاضر').length;
    final absent = _monthRecords.where((r) => r.status == 'غائب').length;
    final late = _monthRecords.where((r) => r.status == 'متأخر').length;
    final total = present + absent + late;
    final avgRate = total > 0 ? ((present + late * 0.5) / total * 100) : 100.0;
    final daysCount = _monthRecords.map((r) => r.date).toSet().length;

    final summaries = _classStudents.map((s) {
      final recs = _monthRecords.where((r) => r.student == s.id).toList();
      final p = recs.where((r) => r.status == 'حاضر').length;
      final a = recs.where((r) => r.status == 'غائب').length;
      final l = recs.where((r) => r.status == 'متأخر').length;
      final t = p + a + l;
      final rate = t > 0 ? ((p + l * 0.5) / t * 100) : 100.0;
      return (student: s, present: p, absent: a, late: l, rate: rate);
    }).toList();

    final honorRoll = summaries.where((s) => s.absent == 0 && s.late == 0).take(4).toList();
    final followUp = summaries.where((s) => s.absent > 0 || s.late > 1).take(5).toList();

    return RefreshIndicator(
      onRefresh: _loadAttendance,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مؤشرات المواظبة (كل السجل)', style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatBox(label: 'معدل المواظبة', value: '${avgRate.toStringAsFixed(1)}%', color: const Color(0xFF059669)),
                      const SizedBox(width: 8),
                      _StatBox(label: 'أيام مسجلة', value: '$daysCount', color: primary),
                      const SizedBox(width: 8),
                      _StatBox(label: 'غيابات', value: '$absent', color: const Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      _StatBox(label: 'تأخيرات', value: '$late', color: const Color(0xFFF59E0B)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFF0FDF4),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.workspace_premium, color: Color(0xFF16A34A), size: 20),
                    SizedBox(width: 8),
                    Text('لوحة شرف المواظبة (حضور كامل دون غياب)',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  if (honorRoll.isEmpty)
                    const Text('لا توجد بيانات كافية بعد.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: honorRoll
                          .map((s) => Chip(
                                avatar: const Text('⭐'),
                                label: Text(s.student.fullName, style: const TextStyle(fontSize: 11)),
                                backgroundColor: Colors.white,
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFFFFBEB),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.warning_amber, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 8),
                    Text('تلاميذ يحتاجون متابعة غياب',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309), fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  if (followUp.isEmpty)
                    const Text('جميع التلاميذ في وضعية مواظبة مستقرة.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E)))
                  else
                    ...followUp.map((s) => Card(
                          margin: const EdgeInsets.only(top: 6),
                          child: ListTile(
                            dense: true,
                            title: Text(s.student.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            subtitle: Text('غياب: ${s.absent} | تأخير: ${s.late} | النسبة: ${s.rate.toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                            trailing: IconButton(
                              icon: const Icon(Icons.call, size: 20),
                              onPressed: () => _callGuardian(s.student.guardianPhone),
                            ),
                          ),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('جدول ملخص مواظبة تلاميذ القسم (${summaries.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  ...summaries.asMap().entries.map((entry) {
                    final s = entry.value;
                    return Container(
                      color: entry.key.isEven ? const Color(0xFFF8FAFC) : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(s.student.fullName,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          ),
                          Text('ح: ${s.present}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF059669))),
                          const SizedBox(width: 6),
                          Text('غ: ${s.absent}', style: const TextStyle(fontSize: 10.5, color: Color(0xFFDC2626))),
                          const SizedBox(width: 6),
                          Text('${s.rate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'حاضر':
        return AppColors.attendancePresent;
      case 'غائب':
        return AppColors.attendanceAbsent;
      default:
        return AppColors.attendanceLate;
    }
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color primaryColor;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primaryColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: selected ? Colors.white : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
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
            Text(label, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.bold)),
            Text(value, style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final String current;
  final ValueChanged<String> onSelected;

  const _StatusToggle({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('حاضر', AppColors.attendancePresent),
      ('غائب', AppColors.attendanceAbsent),
      ('متأخر', AppColors.attendanceLate),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((opt) {
        final selected = current == opt.$1;
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelected(opt.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? opt.$2 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(opt.$1,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: selected ? Colors.white : const Color(0xFF64748B))),
            ),
          ),
        );
      }).toList(),
    );
  }
}
