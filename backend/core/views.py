from django.db.models import Q
from rest_framework import viewsets
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import IsAuthenticated

from . import models, serializers


class TeacherScopedViewSet(viewsets.ModelViewSet):
    """Base viewset that scopes every queryset/create to request.user as `teacher`."""

    permission_classes = [IsAuthenticated]
    owner_field = "teacher"

    def get_queryset(self):
        qs = self.queryset.model.objects.all()
        return qs.filter(**{self.owner_field: self.request.user})

    def perform_create(self, serializer):
        serializer.save(**{self.owner_field: self.request.user})


class SchoolClassViewSet(TeacherScopedViewSet):
    queryset = models.SchoolClass.objects.all()
    serializer_class = serializers.SchoolClassSerializer
    filterset_fields = ["is_archived"]


class StudentViewSet(TeacherScopedViewSet):
    queryset = models.Student.objects.all()
    serializer_class = serializers.StudentSerializer
    filterset_fields = ["school_class", "is_archived"]


class SkillViewSet(TeacherScopedViewSet):
    queryset = models.Skill.objects.all()
    serializer_class = serializers.SkillSerializer
    filterset_fields = ["school_class", "term", "status"]


class SkillEvaluationViewSet(TeacherScopedViewSet):
    queryset = models.SkillEvaluation.objects.all()
    serializer_class = serializers.SkillEvaluationSerializer
    filterset_fields = ["skill", "student", "school_class"]


class AttendanceRecordViewSet(TeacherScopedViewSet):
    queryset = models.AttendanceRecord.objects.all()
    serializer_class = serializers.AttendanceRecordSerializer
    filterset_fields = ["school_class", "student", "date"]


class TimetableSlotViewSet(TeacherScopedViewSet):
    queryset = models.TimetableSlot.objects.all()
    serializer_class = serializers.TimetableSlotSerializer
    filterset_fields = ["school_class", "day_of_week"]


class LessonViewSet(TeacherScopedViewSet):
    queryset = models.Lesson.objects.all()
    serializer_class = serializers.LessonSerializer
    filterset_fields = ["school_class", "subject", "is_archived", "added_to_bag"]


class StudentGradeViewSet(TeacherScopedViewSet):
    queryset = models.StudentGrade.objects.all()
    serializer_class = serializers.StudentGradeSerializer
    filterset_fields = ["school_class", "student", "term"]


class BagDocumentViewSet(TeacherScopedViewSet):
    queryset = models.BagDocument.objects.all()
    serializer_class = serializers.BagDocumentSerializer
    filterset_fields = ["category", "subject"]


class CalendarEventViewSet(TeacherScopedViewSet):
    queryset = models.CalendarEvent.objects.all()
    serializer_class = serializers.CalendarEventSerializer
    filterset_fields = ["type", "is_done"]


class MonthlyParentReportViewSet(TeacherScopedViewSet):
    queryset = models.MonthlyParentReport.objects.all()
    serializer_class = serializers.MonthlyParentReportSerializer
    filterset_fields = ["school_class", "student"]


class AppNotificationViewSet(TeacherScopedViewSet):
    queryset = models.AppNotification.objects.all()
    serializer_class = serializers.AppNotificationSerializer
    owner_field = "user"
    filterset_fields = ["is_read"]


class SubscriptionViewSet(TeacherScopedViewSet):
    queryset = models.Subscription.objects.all()
    serializer_class = serializers.SubscriptionSerializer
    owner_field = "user"


class ConversationViewSet(viewsets.ModelViewSet):
    """PUBLIC_ROOM conversations are visible to every authenticated teacher;
    DIRECT/GROUP/ADMIN_SUPPORT conversations stay scoped to their participants."""

    permission_classes = [IsAuthenticated]
    serializer_class = serializers.ConversationSerializer

    def get_queryset(self):
        return models.Conversation.objects.filter(
            Q(participants=self.request.user) | Q(type="PUBLIC_ROOM")
        ).distinct()

    def perform_create(self, serializer):
        conversation = serializer.save(created_by=self.request.user)
        conversation.participants.add(self.request.user)


class MessageViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = serializers.MessageSerializer

    def get_queryset(self):
        qs = models.Message.objects.filter(
            Q(conversation__participants=self.request.user) | Q(conversation__type="PUBLIC_ROOM")
        ).distinct()
        conversation_id = self.request.query_params.get("conversation")
        if conversation_id:
            qs = qs.filter(conversation_id=conversation_id)
        return qs

    def perform_create(self, serializer):
        conversation = serializer.validated_data["conversation"]
        is_member = conversation.participants.filter(pk=self.request.user.pk).exists()
        if not is_member and conversation.type != "PUBLIC_ROOM":
            raise PermissionDenied("لست عضواً في هذه المحادثة")
        serializer.save(sender=self.request.user)
