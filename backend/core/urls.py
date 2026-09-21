from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("classes", views.SchoolClassViewSet, basename="class")
router.register("students", views.StudentViewSet, basename="student")
router.register("skills", views.SkillViewSet, basename="skill")
router.register("skill-evaluations", views.SkillEvaluationViewSet, basename="skill-evaluation")
router.register("attendance", views.AttendanceRecordViewSet, basename="attendance")
router.register("timetable", views.TimetableSlotViewSet, basename="timetable")
router.register("lessons", views.LessonViewSet, basename="lesson")
router.register("grades", views.StudentGradeViewSet, basename="grade")
router.register("bag-documents", views.BagDocumentViewSet, basename="bag-document")
router.register("calendar-events", views.CalendarEventViewSet, basename="calendar-event")
router.register("parent-reports", views.MonthlyParentReportViewSet, basename="parent-report")
router.register("notifications", views.AppNotificationViewSet, basename="notification")
router.register("subscriptions", views.SubscriptionViewSet, basename="subscription")
router.register("conversations", views.ConversationViewSet, basename="conversation")
router.register("messages", views.MessageViewSet, basename="message")

urlpatterns = router.urls
