import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bottom_bar.dart';
import '../../widgets/app_main_bottom_bar.dart';
import '../../widgets/module_card.dart';

/// Mirrors ui/screens/home/HomeScreen.kt — the module dashboard grid.
class HomeScreen extends StatelessWidget {
  final TeacherProfile? teacherProfile;
  final int unreadNotificationsCount;
  final VoidCallback onOpenNotifications;
  final VoidCallback onNavigateToClasses;
  final VoidCallback onNavigateToStudents;
  final VoidCallback onNavigateToSubjects;
  final VoidCallback onNavigateToSkills;
  final VoidCallback onNavigateToEvaluation;
  final VoidCallback onNavigateToCalendar;
  final VoidCallback onNavigateToAttendance;
  final VoidCallback onNavigateToBag;
  final VoidCallback onNavigateToTimetable;
  final VoidCallback onNavigateToPlanning;
  final VoidCallback onNavigateToLessons;
  final VoidCallback onNavigateToGrades;
  final VoidCallback onNavigateToDownloads;
  final VoidCallback onNavigateToParentReports;
  final VoidCallback onNavigateToSubscription;
  final VoidCallback onProfileClick;

  const HomeScreen({
    super.key,
    required this.teacherProfile,
    required this.unreadNotificationsCount,
    required this.onOpenNotifications,
    required this.onNavigateToClasses,
    required this.onNavigateToStudents,
    required this.onNavigateToSubjects,
    required this.onNavigateToSkills,
    required this.onNavigateToEvaluation,
    required this.onNavigateToCalendar,
    required this.onNavigateToAttendance,
    required this.onNavigateToBag,
    required this.onNavigateToTimetable,
    required this.onNavigateToPlanning,
    required this.onNavigateToLessons,
    required this.onNavigateToGrades,
    required this.onNavigateToDownloads,
    required this.onNavigateToParentReports,
    required this.onNavigateToSubscription,
    required this.onProfileClick,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      bottomNavigationBar: const AppMainBottomBar(current: BottomTab.home),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              teacherProfile: teacherProfile,
              unreadCount: unreadNotificationsCount,
              onNotificationClick: onOpenNotifications,
              onProfileClick: onProfileClick,
              onSubscriptionClick: onNavigateToSubscription,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  Card(
                    color: primary,
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_center_focus, color: Colors.white, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('وضع التركيز على القسم',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                SizedBox(height: 2),
                                Text('ابدأ جلستك الآن للتحضير والمتابعة المباشرة',
                                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const _SectionTitle('متابعات القسم'),
                  Row(children: [
                    ModuleCard(title: 'الأقسام', icon: Icons.groups, onTap: onNavigateToClasses),
                    const SizedBox(width: 10),
                    ModuleCard(title: 'التلاميذ', icon: Icons.person, onTap: onNavigateToStudents),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    ModuleCard(title: 'المواد', icon: Icons.class_, onTap: onNavigateToSubjects),
                    const SizedBox(width: 10),
                    ModuleCard(title: 'المهارات', icon: Icons.lightbulb, onTap: onNavigateToSkills),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    ModuleCard(title: 'تقييم التلاميذ', icon: Icons.fact_check, onTap: onNavigateToEvaluation),
                    const SizedBox(width: 10),
                    ModuleCard(title: 'النداء', icon: Icons.how_to_reg, onTap: onNavigateToAttendance),
                  ]),
                  const SizedBox(height: 18),
                  const _SectionTitle('أخرى'),
                  Row(children: [
                    ModuleCard(title: 'الحقيبة', icon: Icons.work_outline, onTap: onNavigateToBag),
                    const SizedBox(width: 10),
                    ModuleCard(title: 'الجدول', icon: Icons.calendar_today, onTap: onNavigateToTimetable),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    ModuleCard(title: 'التخطيط', icon: Icons.auto_stories, onTap: onNavigateToPlanning),
                    const SizedBox(width: 10),
                    ModuleCard(title: 'الدروس', icon: Icons.menu_book, onTap: onNavigateToLessons),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    ModuleCard(title: 'النتائج', icon: Icons.assessment, onTap: onNavigateToGrades),
                    const SizedBox(width: 10),
                    ModuleCard(title: 'التحميل', icon: Icons.file_download, onTap: onNavigateToDownloads),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    ModuleCard(title: 'تقارير أولياء الأمور', icon: Icons.send_time_extension, onTap: onNavigateToParentReports),
                    const SizedBox(width: 10),
                    ModuleCard(title: 'التقويم والأحداث', icon: Icons.calendar_month, onTap: onNavigateToCalendar),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary)),
    );
  }
}

class _Header extends StatelessWidget {
  final TeacherProfile? teacherProfile;
  final int unreadCount;
  final VoidCallback onNotificationClick;
  final VoidCallback onProfileClick;
  final VoidCallback onSubscriptionClick;

  const _Header({
    required this.teacherProfile,
    required this.unreadCount,
    required this.onNotificationClick,
    required this.onProfileClick,
    required this.onSubscriptionClick,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      color: primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfileClick,
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacherProfile?.fullName.isNotEmpty == true ? teacherProfile!.fullName : 'مرحباً بك',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  teacherProfile?.schoolName ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSubscriptionClick,
            icon: const Icon(Icons.workspace_premium, color: Colors.white),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: onNotificationClick,
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
