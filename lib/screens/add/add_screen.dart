import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Mirrors ui/screens/add/AddScreen.kt — a grid of shortcuts into the
/// screens where each entity is actually created.
class AddScreen extends StatelessWidget {
  final VoidCallback onNavigateToClasses;
  final VoidCallback onNavigateToStudents;
  final VoidCallback onNavigateToLessons;
  final VoidCallback onNavigateToGrades;
  final VoidCallback onNavigateToAttendance;
  final VoidCallback onNavigateToCalendar;
  final VoidCallback onNavigateToSkills;
  final VoidCallback onNavigateToBag;

  const AddScreen({
    super.key,
    required this.onNavigateToClasses,
    required this.onNavigateToStudents,
    required this.onNavigateToLessons,
    required this.onNavigateToGrades,
    required this.onNavigateToAttendance,
    required this.onNavigateToCalendar,
    required this.onNavigateToSkills,
    required this.onNavigateToBag,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      (title: 'إضافة قسم دراسي', subtitle: 'إنشاء فصل جديد وتحديد مستواه', icon: Icons.school, color: AppColors.primaryBlue, onTap: onNavigateToClasses),
      (title: 'تسجيل تلميذ جديد', subtitle: 'إضافة طالب لبيانات القسم', icon: Icons.person_add, color: const Color(0xFF2E7D32), onTap: onNavigateToStudents),
      (title: 'تحضير درس جديد', subtitle: 'صياغة الأهداف والوسائل', icon: Icons.menu_book, color: const Color(0xFFE65100), onTap: onNavigateToLessons),
      (title: 'رصد النتائج', subtitle: 'إدخال درجات ونتائج التلاميذ', icon: Icons.assessment, color: const Color(0xFF7C3AED), onTap: onNavigateToGrades),
      (title: 'تسجيل النداء', subtitle: 'تسجيل الحضور والغياب اليومي', icon: Icons.how_to_reg, color: const Color(0xFFD97706), onTap: onNavigateToAttendance),
      (title: 'إضافة حدث بالتقويم', subtitle: 'اختبار، عطلة، أو اجتماع', icon: Icons.calendar_month, color: const Color(0xFF0D9488), onTap: onNavigateToCalendar),
      (title: 'إضافة مهارة/كفاية', subtitle: 'تسجيل مهارة جديدة لمادة', icon: Icons.lightbulb, color: const Color(0xFFCA8A04), onTap: onNavigateToSkills),
      (title: 'إضافة مستند للحقيبة', subtitle: 'حفظ ملف أو رابط تعليمي', icon: Icons.work_outline, color: const Color(0xFFBE123C), onTap: onNavigateToBag),
    ];

    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(title: const Text('مركز الإضافة السريعة')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
        children: actions
            .map((a) => Card(
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: a.onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(color: a.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: Icon(a.icon, color: a.color, size: 22),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              const SizedBox(height: 2),
                              Text(a.subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
