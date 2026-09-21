from django.conf import settings
from django.db import models

TEACHER = settings.AUTH_USER_MODEL


class SchoolClass(models.Model):
    teacher = models.ForeignKey(TEACHER, on_delete=models.CASCADE, related_name="classes")
    name = models.CharField(max_length=100)
    grade_level = models.CharField(max_length=100)
    academic_year = models.CharField(max_length=20, default="2026-2027")
    is_archived = models.BooleanField(default=False)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name

    @property
    def student_count(self):
        return self.students.filter(is_archived=False).count()


class Student(models.Model):
    GENDER_CHOICES = [("ذكر", "ذكر"), ("أنثى", "أنثى")]

    teacher = models.ForeignKey(TEACHER, on_delete=models.CASCADE, related_name="students")
    school_class = models.ForeignKey(SchoolClass, on_delete=models.CASCADE, related_name="students")
    full_name = models.CharField(max_length=150)
    student_code = models.CharField(max_length=50, blank=True, default="")
    guardian_name = models.CharField(max_length=150, blank=True, default="")
    guardian_phone = models.CharField(max_length=32, blank=True, default="")
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, default="ذكر")
    avatar = models.ImageField(upload_to="students/", blank=True, null=True)
    is_archived = models.BooleanField(default=False)
    health_notes = models.TextField(blank=True, default="")
    pedagogical_notes = models.TextField(blank=True, default="")
    include_notes_in_ai_analysis = models.BooleanField(default=True)

    class Meta:
        ordering = ["full_name"]

    def __str__(self):
        return self.full_name


class Skill(models.Model):
    PRIORITY_CHOICES = [("عالية", "عالية"), ("عادية", "عادية"), ("دعم", "دعم")]
    STATUS_CHOICES = [("مخطط لها", "مخطط لها"), ("قيد التنفيذ", "قيد التنفيذ"), ("تم الإنجاز", "تم الإنجاز")]

    teacher = models.ForeignKey(TEACHER, on_delete=models.CASCADE, related_name="skills")
    school_class = models.ForeignKey(SchoolClass, on_delete=models.CASCADE, related_name="skills")
    subject = models.CharField(max_length=100)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, default="")
    term = models.CharField(max_length=50, default="الفصل الأول")
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default="عادية")
    order_index = models.IntegerField(default=0)
    domain = models.CharField(max_length=100, default="الحساب والعمليات")
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="مخطط لها")
    created_date = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["order_index"]

    def __str__(self):
        return self.title


class SkillEvaluation(models.Model):
    RATING_CHOICES = [
        ("متقن", "متقن"),
        ("في طور الاكتساب", "في طور الاكتساب"),
        ("غير مكتسب", "غير مكتسب"),
    ]

    teacher = models.ForeignKey(TEACHER, on_delete=models.CASCADE, related_name="skill_evaluations")
    skill = models.ForeignKey(Skill, on_delete=models.CASCADE, related_name="evaluations")
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="skill_evaluations")
    school_class = models.ForeignKey(SchoolClass, on_delete=models.CASCADE, related_name="skill_evaluations")
    date = models.DateField()
    rating = models.CharField(max_length=30, choices=RATING_CHOICES, default="في طور الاكتساب")
    score = models.FloatField(default=0)
    notes = models.TextField(blank=True, default="")

    class Meta:
        ordering = ["-date"]


class AttendanceRecord(models.Model):
    STATUS_CHOICES = [("حاضر", "حاضر"), ("غائب", "غائب"), ("متأخر", "متأخر")]

    teacher = models.ForeignKey(TEACHER, on_delete=models.CASCADE, related_name="attendance_records")
    school_class = models.ForeignKey(SchoolClass, on_delete=models.CASCADE, related_name="attendance_records")
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="attendance_records")
    date = models.DateField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default="حاضر")
    notes = models.CharField(max_length=255, blank=True, default="")

    class Meta:
        ordering = ["-date"]
        unique_together = ("student", "date")


class TimetableSlot(models.Model):
    DAY_CHOICES = [
        ("الاثنين", "الاثنين"), ("الثلاثاء", "الثلاثاء"), ("الأربعاء", "الأربعاء"),
        ("الخميس", "الخميس"), ("الجمعة", "الجمعة"), ("السبت", "السبت"), ("الأحد", "الأحد"),
    ]

    teacher = models.ForeignKey(TEACHER, on_delete=models.CASCADE, related_name="timetable_slots")
    day_of_week = models.CharField(max_length=20, choices=DAY_CHOICES)
    start_time = models.TimeField()
    end_time = models.TimeField()
    school_class = models.ForeignKey(SchoolClass, on_delete=models.CASCADE, related_name="timetable_slots")
    subject = models.CharField(max_length=100)
    lesson_title = models.CharField(max_length=200, blank=True, default="")

    class Meta:
        ordering = ["day_of_week", "start_time"]


class Lesson(models.Model):
    teacher = models.ForeignKey(TEACHER, on_delete=models.CASCADE, related_name="lessons")
    school_class = models.ForeignKey(SchoolClass, on_delete=models.CASCADE, related_name="lessons")
    subject = models.CharField(max_length=100)
    grade_level = models.CharField(max_length=100, blank=True, default="")
    domain = models.CharField(max_length=100, blank=True, default="")
    skill = models.ForeignKey(Skill, on_delete=models.SET_NULL, null=True, blank=True, related_name="lessons")
    skill_title = models.CharField(max_length=200, blank=True, default="")
    title = models.CharField(max_length=200)

    introduction = models.TextField(blank=True, default="")
    presentation = models.TextField(blank=True, default="")
    summary = models.TextField(blank=True, default="")
    application = models.TextField(blank=True, default="")
    integration = models.TextField(blank=True, default="")

    date_created = models.DateTimeField(auto_now_add=True)
    is_ai_generated = models.BooleanField(default=False)
    is_archived = models.BooleanField(default=False)
    added_to_bag = models.BooleanField(default=False)
    is_completed = models.BooleanField(default=False)

    class Meta:
        ordering = ["-date_created"]

    def __str__(self):
        return self.title


class StudentGrade(models.Model):
    TERM_CHOICES = [
        ("الفصل الأول", "الفصل الأول"), ("الفصل الثاني", "الفصل الثاني"),
        ("الفصل الثالث", "الفصل الثالث"), ("الامتحان النهائي", "الامتحان النهائي"),
    ]

    teacher = models.ForeignKey(TEACHER, on_delete=models.CASCADE, related_name="student_grades")
    school_class = models.ForeignKey(SchoolClass, on_delete=models.CASCADE, related_name="student_grades")
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="grades")
    term = models.CharField(max_length=30, choices=TERM_CHOICES, default="الفصل الأول")

    arabic_score = models.FloatField(default=0)
    math_score = models.FloatField(default=0)
    science_score = models.FloatField(default=0)
    islamic_score = models.FloatField(default=0)
    french_score = models.FloatField(default=0)
    history_score = models.FloatField(default=0)
    civic_score = models.FloatField(default=0)
    art_score = models.FloatField(default=0)
    pe_score = models.FloatField(default=0)

    total_score = models.FloatField(default=0)
    average = models.FloatField(default=0)
    rank = models.IntegerField(default=0)
    teacher_notes = models.TextField(blank=True, default="")

    class Meta:
        unique_together = ("student", "term")


class BagDocument(models.Model):
    teacher = models.ForeignKey(TEACHER, on_delete=models.CASCADE, related_name="bag_documents")
    title = models.CharField(max_length=200)
    category = models.CharField(max_length=100, blank=True, default="")
    subject = models.CharField(max_length=100, blank=True, default="")
    grade_level = models.CharField(max_length=100, blank=True, default="")
    file_type = models.CharField(max_length=20, blank=True, default="PDF")
    file = models.FileField(upload_to="bag/", blank=True, null=True)
    file_size = models.CharField(max_length=20, blank=True, default="")
    date_added = models.DateTimeField(auto_now_add=True)
    source_url = models.URLField(blank=True, null=True)
    is_external_source = models.BooleanField(default=False)
    content_preview = models.TextField(blank=True, default="")

    class Meta:
        ordering = ["-date_added"]


class CalendarEvent(models.Model):
    teacher = models.ForeignKey(TEACHER, on_delete=models.CASCADE, related_name="calendar_events")
    title = models.CharField(max_length=200)
    type = models.CharField(max_length=50, default="اجتماع أولياء الأمور")
    date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    time = models.CharField(max_length=50, blank=True, default="")
    location = models.CharField(max_length=150, blank=True, default="المدرسة")
    target_class = models.CharField(max_length=150, blank=True, default="جميع الأقسام")
    description = models.TextField(blank=True, default="")
    is_done = models.BooleanField(default=False)

    class Meta:
        ordering = ["date"]


class MonthlyParentReport(models.Model):
    teacher = models.ForeignKey(TEACHER, on_delete=models.CASCADE, related_name="parent_reports")
    school_class = models.ForeignKey(SchoolClass, on_delete=models.CASCADE, related_name="parent_reports")
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="parent_reports")
    month_year = models.CharField(max_length=30)
    progress_level = models.CharField(max_length=255, blank=True, default="")
    attendance_summary = models.CharField(max_length=255, blank=True, default="")
    evaluation_results = models.CharField(max_length=255, blank=True, default="")
    difficulty_lessons = models.TextField(blank=True, default="")
    teacher_recommendations = models.TextField(blank=True, default="")
    is_auto_sent = models.BooleanField(default=True)
    sent_timestamp = models.DateTimeField(auto_now_add=True)
    dispatch_channel = models.CharField(max_length=100, default="واتساب والمنظومة التربوية")

    class Meta:
        ordering = ["-sent_timestamp"]


class AppNotification(models.Model):
    user = models.ForeignKey(TEACHER, on_delete=models.CASCADE, related_name="notifications")
    title = models.CharField(max_length=150)
    message = models.TextField(blank=True, default="")
    type = models.CharField(max_length=50, default="رسائل النظام")
    timestamp = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    class Meta:
        ordering = ["-timestamp"]


class Subscription(models.Model):
    STATUS_CHOICES = [
        ("ACTIVE", "نشط"), ("PENDING_VERIFICATION", "قيد التحقق"),
        ("TRIAL", "تجريبي"), ("EXPIRED", "منتهي"), ("EXPIRING_SOON", "ينتهي قريباً"),
    ]
    PAYMENT_METHOD_CHOICES = [
        ("BANKILY", "بنكيلي"), ("MASRVI", "مصرفي"), ("SEDAD", "سداد"),
        ("AMANTY", "أمانتي"), ("CASH", "نقداً"),
    ]

    user = models.ForeignKey(TEACHER, on_delete=models.CASCADE, related_name="subscriptions")
    plan_id = models.CharField(max_length=50, default="ANNUAL_TEACHER_2026")
    plan_name = models.CharField(max_length=100, default="العضوية السنوية للمعلم")
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default="PENDING_VERIFICATION")
    price_ouguiya = models.IntegerField(default=6000)
    duration_days = models.IntegerField(default=365)
    activation_date = models.DateField(null=True, blank=True)
    expiry_date = models.DateField(null=True, blank=True)
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHOD_CHOICES, default="BANKILY")
    payment_reference = models.CharField(max_length=100, blank=True, default="")
    payment_proof = models.ImageField(upload_to="payment_proofs/", blank=True, null=True)
    user_note = models.TextField(blank=True, default="")
    verified_by_admin = models.ForeignKey(
        TEACHER, on_delete=models.SET_NULL, null=True, blank=True, related_name="verified_subscriptions"
    )
    admin_notes = models.TextField(blank=True, default="")
    rejection_reason = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class Conversation(models.Model):
    TYPE_CHOICES = [
        ("PUBLIC_ROOM", "غرفة عامة"), ("DIRECT", "محادثة خاصة"),
        ("GROUP", "مجموعة"), ("ADMIN_SUPPORT", "دعم فني"),
    ]

    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default="PUBLIC_ROOM")
    title = models.CharField(max_length=150, default="غرفة المعلمين العامة")
    description = models.TextField(blank=True, default="")
    participants = models.ManyToManyField(TEACHER, related_name="conversations")
    created_by = models.ForeignKey(
        TEACHER, on_delete=models.SET_NULL, null=True, related_name="created_conversations"
    )
    is_archived = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]


class Message(models.Model):
    TYPE_CHOICES = [
        ("TEXT", "نص"), ("IMAGE", "صورة"), ("DOCUMENT", "مستند"),
        ("VOICE", "صوت"), ("VIDEO", "فيديو"), ("SYSTEM", "نظام"),
    ]

    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name="messages")
    sender = models.ForeignKey(TEACHER, on_delete=models.CASCADE, related_name="sent_messages")
    text = models.TextField(blank=True, default="")
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default="TEXT")
    attachment = models.FileField(upload_to="chat/", blank=True, null=True)
    reply_to = models.ForeignKey("self", on_delete=models.SET_NULL, null=True, blank=True, related_name="replies")
    read_by = models.ManyToManyField(TEACHER, related_name="read_messages", blank=True)
    is_edited = models.BooleanField(default=False)
    is_deleted = models.BooleanField(default=False)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["timestamp"]
