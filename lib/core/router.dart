import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/add/add_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/bag/bag_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/classes/classes_screen.dart';
import '../screens/developer/developer_panel_screen.dart';
import '../screens/evaluation/evaluation_screen.dart';
import '../screens/grades/grades_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/lessons/lessons_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/reports/parent_reports_screen.dart';
import '../screens/skills/skills_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/students/students_screen.dart';
import '../screens/subjects/subjects_screen.dart';
import '../screens/subscription/subscription_screen.dart';
import '../screens/timetable/timetable_screen.dart';
import '../widgets/placeholder_screen.dart';
import 'package:flutter/material.dart';

/// Mirrors the NavHost route table in MainActivity.kt.
GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(
          onTimeout: () {
            if (auth.status == AuthStatus.loggedIn) {
              context.go('/home');
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          onLoginSuccess: () => context.go('/home'),
          onNavigateToRegister: () => context.push('/register'),
          onNavigateToForgotPassword: () => context.push('/forgot-password'),
          onNavigateToDeveloperLogin: () => context.push('/developer-login'),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(
          onRegisterSuccess: () => context.go('/home'),
          onNavigateToLogin: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordScreen(
          onSuccessReset: () => context.go('/login'),
          onNavigateBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/developer-login',
        builder: (context, state) => const PlaceholderScreen(title: 'دخول المطور', icon: Icons.admin_panel_settings),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => Consumer<AuthProvider>(
          builder: (context, auth, _) => HomeScreen(
            teacherProfile: auth.teacherProfile,
            unreadNotificationsCount: 0,
            onOpenNotifications: () {},
            onNavigateToClasses: () => context.push('/classes'),
            onNavigateToStudents: () => context.push('/students'),
            onNavigateToSubjects: () => context.push('/subjects'),
            onNavigateToSkills: () => context.push('/skills'),
            onNavigateToEvaluation: () => context.push('/evaluation'),
            onNavigateToCalendar: () => context.push('/calendar'),
            onNavigateToAttendance: () => context.push('/attendance'),
            onNavigateToBag: () => context.push('/bag'),
            onNavigateToTimetable: () => context.push('/timetable'),
            onNavigateToPlanning: () => context.push('/planning'),
            onNavigateToLessons: () => context.push('/lessons'),
            onNavigateToGrades: () => context.push('/grades'),
            onNavigateToDownloads: () => context.push('/downloads'),
            onNavigateToParentReports: () => context.push('/parent-reports'),
            onNavigateToSubscription: () => context.push('/subscription'),
            onProfileClick: () => context.push('/profile'),
          ),
        ),
      ),
      GoRoute(
        path: '/classes',
        builder: (context, state) => ClassesScreen(
          onNavigateToStudents: (classId) => context.push('/students', extra: classId),
        ),
      ),
      GoRoute(
        path: '/students',
        builder: (context, state) => StudentsScreen(
          initialClassId: state.extra as int?,
          onNavigateToClasses: () => context.push('/classes'),
        ),
      ),
      GoRoute(
        path: '/attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/grades',
        builder: (context, state) => const GradesScreen(),
      ),
      GoRoute(
        path: '/subjects',
        builder: (context, state) => SubjectsScreen(
          onOpenSubject: (subject) => context.push('/skills', extra: subject),
        ),
      ),
      GoRoute(
        path: '/skills',
        builder: (context, state) => SkillsScreen(
          initialSubject: state.extra as String?,
          onNavigateToEvaluation: (skillId) => context.push('/evaluation'),
        ),
      ),
      GoRoute(
        path: '/evaluation',
        builder: (context, state) => const EvaluationScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/timetable',
        builder: (context, state) => const TimetableScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => ProfileScreen(
          onLogout: () => context.go('/login'),
          onNavigateToSubscription: () => context.push('/subscription'),
          onNavigateToAdminUsers: () => context.push('/admin-users'),
        ),
      ),
      GoRoute(
        path: '/lessons',
        builder: (context, state) => const LessonsScreen(),
      ),
      GoRoute(
        path: '/bag',
        builder: (context, state) => const BagScreen(),
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) => AddScreen(
          onNavigateToClasses: () => context.push('/classes'),
          onNavigateToStudents: () => context.push('/students'),
          onNavigateToLessons: () => context.push('/lessons'),
          onNavigateToGrades: () => context.push('/grades'),
          onNavigateToAttendance: () => context.push('/attendance'),
          onNavigateToCalendar: () => context.push('/calendar'),
          onNavigateToSkills: () => context.push('/skills'),
          onNavigateToBag: () => context.push('/bag'),
        ),
      ),
      GoRoute(
        path: '/developer-panel',
        builder: (context, state) => DeveloperPanelScreen(
          onLogout: () {
            auth.logout();
            context.go('/login');
          },
        ),
      ),
      GoRoute(
        path: '/admin-users',
        builder: (context, state) => DeveloperPanelScreen(
          onLogout: () {
            auth.logout();
            context.go('/login');
          },
        ),
      ),
      GoRoute(
        path: '/parent-reports',
        builder: (context, state) => const ParentReportsScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      ..._placeholderRoutes,
    ],
  );
}

/// Remaining screens ported as navigable placeholders — swap each builder
/// for the full screen once it's translated from the matching *Screen.kt.
final List<GoRoute> _placeholderRoutes = [
  ('/planning', 'التخطيط', Icons.auto_stories),
  ('/downloads', 'مركز التحميل', Icons.file_download),
].map((r) => GoRoute(
      path: r.$1,
      builder: (context, state) => PlaceholderScreen(title: r.$2, icon: r.$3),
    )).toList();
