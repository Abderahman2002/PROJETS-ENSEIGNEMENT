from rest_framework import serializers

from . import models


class SchoolClassSerializer(serializers.ModelSerializer):
    student_count = serializers.ReadOnlyField()

    class Meta:
        model = models.SchoolClass
        fields = ["id", "name", "grade_level", "academic_year", "is_archived", "student_count"]


class StudentSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Student
        fields = [
            "id", "school_class", "full_name", "student_code", "guardian_name", "guardian_phone",
            "gender", "avatar", "is_archived", "health_notes", "pedagogical_notes",
            "include_notes_in_ai_analysis",
        ]


class SkillSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Skill
        fields = [
            "id", "school_class", "subject", "title", "description", "term", "priority",
            "order_index", "domain", "start_date", "end_date", "status", "created_date",
        ]


class SkillEvaluationSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.SkillEvaluation
        fields = ["id", "skill", "student", "school_class", "date", "rating", "score", "notes"]


class AttendanceRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.AttendanceRecord
        fields = ["id", "school_class", "student", "date", "status", "notes"]


class TimetableSlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.TimetableSlot
        fields = ["id", "day_of_week", "start_time", "end_time", "school_class", "subject", "lesson_title"]


class LessonSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Lesson
        fields = [
            "id", "school_class", "subject", "grade_level", "domain", "skill", "skill_title", "title",
            "introduction", "presentation", "summary", "application", "integration", "date_created",
            "is_ai_generated", "is_archived", "added_to_bag", "is_completed",
        ]


class StudentGradeSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.StudentGrade
        fields = [
            "id", "school_class", "student", "term", "arabic_score", "math_score", "science_score",
            "islamic_score", "french_score", "history_score", "civic_score", "art_score", "pe_score",
            "total_score", "average", "rank", "teacher_notes",
        ]


class BagDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.BagDocument
        fields = [
            "id", "title", "category", "subject", "grade_level", "file_type", "file", "file_size",
            "date_added", "source_url", "is_external_source", "content_preview",
        ]


class CalendarEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.CalendarEvent
        fields = [
            "id", "title", "type", "date", "end_date", "time", "location", "target_class",
            "description", "is_done",
        ]


class MonthlyParentReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.MonthlyParentReport
        fields = [
            "id", "school_class", "student", "month_year", "progress_level", "attendance_summary",
            "evaluation_results", "difficulty_lessons", "teacher_recommendations", "is_auto_sent",
            "sent_timestamp", "dispatch_channel",
        ]


class AppNotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.AppNotification
        fields = ["id", "title", "message", "type", "timestamp", "is_read"]


class SubscriptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Subscription
        fields = [
            "id", "plan_id", "plan_name", "status", "price_ouguiya", "duration_days",
            "activation_date", "expiry_date", "payment_method", "payment_reference",
            "payment_proof", "user_note", "admin_notes", "rejection_reason", "created_at",
        ]
        read_only_fields = ["status", "activation_date", "expiry_date", "admin_notes", "rejection_reason"]


class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.CharField(source="sender.full_name", read_only=True)

    class Meta:
        model = models.Message
        fields = [
            "id", "conversation", "sender", "sender_name", "text", "type", "attachment",
            "reply_to", "is_edited", "is_deleted", "timestamp",
        ]
        read_only_fields = ["sender"]


class ConversationSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.Conversation
        fields = ["id", "type", "title", "description", "participants", "is_archived", "created_at", "updated_at"]
