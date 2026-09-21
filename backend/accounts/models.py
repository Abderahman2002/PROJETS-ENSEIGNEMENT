import uuid

from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.contrib.auth.models import PermissionsMixin
from django.db import models
from django.utils import timezone


class UserRole(models.TextChoices):
    TEACHER = "TEACHER", "معلم"
    ADMIN = "ADMIN", "مدير النظام"
    SUPERVISOR = "SUPERVISOR", "مفتش تربوي"
    SUPPORT = "SUPPORT", "الدعم الفني"


class AccountStatus(models.TextChoices):
    PENDING = "pending", "قيد المراجعة"
    ACTIVE = "active", "نشط"
    SUSPENDED = "suspended", "موقوف"
    DISABLED = "disabled", "معطل"
    DELETED = "deleted", "محذوف"


class SubscriptionStatus(models.TextChoices):
    TRIAL = "TRIAL", "تجريبي"
    ACTIVE = "ACTIVE", "نشط"
    EXPIRING_SOON = "EXPIRING_SOON", "ينتهي قريباً"
    EXPIRED = "EXPIRED", "منتهي"
    PENDING_VERIFICATION = "PENDING_VERIFICATION", "قيد التحقق"


class UserManager(BaseUserManager):
    use_in_migrations = True

    def _create_user(self, phone, password, **extra_fields):
        if not phone:
            raise ValueError("رقم الهاتف مطلوب")
        user = self.model(phone=phone, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, phone, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", False)
        extra_fields.setdefault("is_superuser", False)
        return self._create_user(phone, password, **extra_fields)

    def create_superuser(self, phone, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("role", UserRole.ADMIN)
        extra_fields.setdefault("account_status", AccountStatus.ACTIVE)
        return self._create_user(phone, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    """Mirrors the Kotlin TeacherProfile / FirestoreUser models, merged into one."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone = models.CharField(max_length=32, unique=True)
    full_name = models.CharField(max_length=150, blank=True, default="")
    national_id = models.CharField(max_length=64, blank=True, default="")
    financial_index = models.CharField(max_length=64, blank=True, default="")
    email = models.EmailField(blank=True, null=True)

    school_name = models.CharField(max_length=150, blank=True, default="")
    wilaya = models.CharField(max_length=100, blank=True, default="")
    moughataa = models.CharField(max_length=100, blank=True, default="")
    avatar = models.ImageField(upload_to="avatars/", blank=True, null=True)

    role = models.CharField(max_length=16, choices=UserRole.choices, default=UserRole.TEACHER)
    account_status = models.CharField(max_length=16, choices=AccountStatus.choices, default=AccountStatus.PENDING)
    suspension_reason = models.CharField(max_length=255, blank=True, default="")

    subscription_status = models.CharField(
        max_length=24, choices=SubscriptionStatus.choices, default=SubscriptionStatus.TRIAL
    )
    trial_start_date = models.DateField(default=timezone.now)
    trial_end_date = models.DateField(null=True, blank=True)
    subscription_start_date = models.DateField(null=True, blank=True)
    subscription_end_date = models.DateField(null=True, blank=True)

    app_pin = models.CharField(max_length=8, blank=True, default="")
    app_lock_enabled = models.BooleanField(default=False)
    color_theme = models.CharField(max_length=20, default="blue")

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_verified = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_active_at = models.DateTimeField(default=timezone.now)

    objects = UserManager()

    USERNAME_FIELD = "phone"
    REQUIRED_FIELDS = []

    def __str__(self):
        return f"{self.full_name or self.phone}"

    @property
    def is_admin(self):
        return self.role == UserRole.ADMIN

    def is_account_active(self):
        return self.account_status == AccountStatus.ACTIVE

    def is_account_suspended(self):
        return self.account_status in (AccountStatus.SUSPENDED, AccountStatus.DELETED, AccountStatus.DISABLED)


class AdminAction(models.Model):
    """Audit log of admin actions performed on teacher accounts/subscriptions."""

    ACTION_ACTIVATE_SUB = "ACTIVATE_SUB"
    ACTION_DEACTIVATE_SUB = "DEACTIVATE_SUB"
    ACTION_EXTEND_SUB = "EXTEND_SUB"
    ACTION_END_SUB = "END_SUB"
    ACTION_DISABLE_ACCOUNT = "DISABLE_ACCOUNT"
    ACTION_ACTIVATE_ACCOUNT = "ACTIVATE_ACCOUNT"
    ACTION_UPDATE_ROLE = "UPDATE_ROLE"

    ACTION_CHOICES = [
        (ACTION_ACTIVATE_SUB, "تفعيل الاشتراك"),
        (ACTION_DEACTIVATE_SUB, "إلغاء تفعيل الاشتراك"),
        (ACTION_EXTEND_SUB, "تمديد الاشتراك"),
        (ACTION_END_SUB, "إنهاء الاشتراك"),
        (ACTION_DISABLE_ACCOUNT, "تعطيل الحساب"),
        (ACTION_ACTIVATE_ACCOUNT, "تفعيل الحساب"),
        (ACTION_UPDATE_ROLE, "تحديث الصلاحية"),
    ]

    id = models.BigAutoField(primary_key=True)
    teacher = models.ForeignKey(User, on_delete=models.CASCADE, related_name="admin_actions_received")
    admin = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name="admin_actions_performed")
    action_type = models.CharField(max_length=32, choices=ACTION_CHOICES)
    old_value = models.CharField(max_length=255, blank=True, default="")
    new_value = models.CharField(max_length=255, blank=True, default="")
    note = models.TextField(blank=True, default="")
    duration_days = models.IntegerField(null=True, blank=True)
    payment_reference = models.CharField(max_length=100, blank=True, default="")
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-timestamp"]


class PasswordResetCode(models.Model):
    """Simple phone-based reset code, to be delivered via SMS gateway in production."""

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="reset_codes")
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    used = models.BooleanField(default=False)

    def is_valid(self):
        return not self.used and (timezone.now() - self.created_at).total_seconds() < 15 * 60
