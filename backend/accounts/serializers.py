from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import AdminAction

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id", "phone", "full_name", "national_id", "financial_index", "email",
            "school_name", "wilaya", "moughataa", "avatar", "role",
            "account_status", "suspension_reason", "subscription_status",
            "trial_start_date", "trial_end_date", "subscription_start_date",
            "subscription_end_date", "color_theme", "app_lock_enabled",
            "is_active", "created_at", "last_active_at",
        ]
        read_only_fields = [
            "id", "role", "account_status", "subscription_status", "trial_start_date",
            "trial_end_date", "subscription_start_date", "subscription_end_date",
            "is_active", "created_at", "last_active_at",
        ]


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])

    class Meta:
        model = User
        fields = [
            "phone", "password", "full_name", "national_id", "financial_index",
            "school_name", "wilaya", "moughataa",
        ]

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class PhoneTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Allows login with either phone number OR financial index, matching the app's login field."""

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["role"] = user.role
        token["full_name"] = user.full_name
        return token

    def validate(self, attrs):
        identifier = attrs.get(self.username_field)
        if identifier and not User.objects.filter(phone=identifier).exists():
            alt = User.objects.filter(financial_index=identifier).first()
            if alt:
                attrs[self.username_field] = alt.phone
        return super().validate(attrs)


class AdminUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id", "phone", "full_name", "national_id", "financial_index", "email",
            "school_name", "wilaya", "moughataa", "role", "account_status",
            "suspension_reason", "subscription_status", "trial_start_date", "trial_end_date",
            "subscription_start_date", "subscription_end_date", "is_active", "created_at",
            "last_active_at",
        ]
        read_only_fields = fields


class AdminActionSerializer(serializers.ModelSerializer):
    teacher_name = serializers.CharField(source="teacher.full_name", read_only=True)
    admin_name = serializers.CharField(source="admin.full_name", read_only=True)

    class Meta:
        model = AdminAction
        fields = [
            "id", "teacher", "teacher_name", "admin", "admin_name", "action_type",
            "old_value", "new_value", "note", "duration_days", "timestamp",
        ]
        read_only_fields = fields


class AdminExtendSubscriptionSerializer(serializers.Serializer):
    duration_days = serializers.IntegerField(min_value=1, default=365)
    note = serializers.CharField(required=False, allow_blank=True, default="")


class AdminDisableAccountSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True, default="")


class ForgotPasswordRequestSerializer(serializers.Serializer):
    phone = serializers.CharField()


class ForgotPasswordConfirmSerializer(serializers.Serializer):
    phone = serializers.CharField()
    code = serializers.CharField()
    new_password = serializers.CharField(validators=[validate_password])
