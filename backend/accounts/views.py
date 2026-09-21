import random
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import generics, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import AdminAction, PasswordResetCode, UserRole, AccountStatus, SubscriptionStatus
from .serializers import (
    AdminActionSerializer,
    AdminDisableAccountSerializer,
    AdminExtendSubscriptionSerializer,
    AdminUserSerializer,
    ForgotPasswordConfirmSerializer,
    ForgotPasswordRequestSerializer,
    PhoneTokenObtainPairSerializer,
    RegisterSerializer,
    UserSerializer,
)

User = get_user_model()


class IsAdminRole(permissions.BasePermission):
    """Grants access to users with role=ADMIN (mirrors the Kotlin app's
    isAuthorizedAdmin check in DeveloperPanelScreen.kt)."""

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == UserRole.ADMIN)


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]


class PhoneTokenObtainPairView(TokenObtainPairView):
    serializer_class = PhoneTokenObtainPairSerializer


class MeView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class ForgotPasswordRequestView(APIView):
    """Generates a 6-digit reset code. In production, send it via SMS; for now it is returned in the response."""

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = ForgotPasswordRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = get_object_or_404(User, phone=serializer.validated_data["phone"])
        code = f"{random.randint(0, 999999):06d}"
        PasswordResetCode.objects.create(user=user, code=code)
        return Response({"detail": "تم إرسال رمز التحقق", "dev_code": code}, status=status.HTTP_200_OK)


class ForgotPasswordConfirmView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = ForgotPasswordConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        user = get_object_or_404(User, phone=data["phone"])
        reset = (
            PasswordResetCode.objects.filter(user=user, code=data["code"], used=False)
            .order_by("-created_at")
            .first()
        )
        if not reset or not reset.is_valid():
            return Response({"detail": "رمز التحقق غير صالح أو منتهي"}, status=status.HTTP_400_BAD_REQUEST)
        user.set_password(data["new_password"])
        user.save()
        reset.used = True
        reset.save()
        return Response({"detail": "تم تغيير كلمة المرور بنجاح"})


class AdminUserViewSet(viewsets.ReadOnlyModelViewSet):
    """Admin-only teacher directory + subscription/account management actions.
    Mirrors DeveloperPanelScreen.kt's operations on FirestoreUser records."""

    queryset = User.objects.all().order_by("-created_at")
    serializer_class = AdminUserSerializer
    permission_classes = [IsAdminRole]
    filterset_fields = ["role", "account_status", "subscription_status"]

    def get_queryset(self):
        qs = super().get_queryset()
        search = self.request.query_params.get("search")
        if search:
            qs = qs.filter(full_name__icontains=search) | qs.filter(phone__icontains=search)
        return qs

    def _log(self, teacher, action_type, old_value="", new_value="", note="", duration_days=None):
        AdminAction.objects.create(
            teacher=teacher,
            admin=self.request.user,
            action_type=action_type,
            old_value=str(old_value),
            new_value=str(new_value),
            note=note,
            duration_days=duration_days,
        )

    @action(detail=True, methods=["post"], url_path="activate-subscription")
    def activate_subscription(self, request, pk=None):
        teacher = self.get_object()
        serializer = AdminExtendSubscriptionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        days = serializer.validated_data["duration_days"]
        old_status = teacher.subscription_status
        today = timezone.now().date()
        teacher.subscription_status = SubscriptionStatus.ACTIVE
        teacher.subscription_start_date = today
        teacher.subscription_end_date = today + timedelta(days=days)
        teacher.save()
        self._log(teacher, AdminAction.ACTION_ACTIVATE_SUB, old_status, SubscriptionStatus.ACTIVE,
                   serializer.validated_data.get("note", ""), days)
        return Response(AdminUserSerializer(teacher).data)

    @action(detail=True, methods=["post"], url_path="extend-subscription")
    def extend_subscription(self, request, pk=None):
        teacher = self.get_object()
        serializer = AdminExtendSubscriptionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        days = serializer.validated_data["duration_days"]
        base = teacher.subscription_end_date if teacher.subscription_end_date and teacher.subscription_end_date > timezone.now().date() else timezone.now().date()
        old_end = teacher.subscription_end_date
        teacher.subscription_end_date = base + timedelta(days=days)
        teacher.subscription_status = SubscriptionStatus.ACTIVE
        teacher.save()
        self._log(teacher, AdminAction.ACTION_EXTEND_SUB, old_end, teacher.subscription_end_date,
                   serializer.validated_data.get("note", ""), days)
        return Response(AdminUserSerializer(teacher).data)

    @action(detail=True, methods=["post"], url_path="deactivate-subscription")
    def deactivate_subscription(self, request, pk=None):
        teacher = self.get_object()
        old_status = teacher.subscription_status
        teacher.subscription_status = SubscriptionStatus.EXPIRED
        teacher.save()
        self._log(teacher, AdminAction.ACTION_DEACTIVATE_SUB, old_status, SubscriptionStatus.EXPIRED)
        return Response(AdminUserSerializer(teacher).data)

    @action(detail=True, methods=["post"], url_path="end-subscription")
    def end_subscription(self, request, pk=None):
        teacher = self.get_object()
        old_end = teacher.subscription_end_date
        teacher.subscription_end_date = timezone.now().date()
        teacher.subscription_status = SubscriptionStatus.EXPIRED
        teacher.save()
        self._log(teacher, AdminAction.ACTION_END_SUB, old_end, teacher.subscription_end_date)
        return Response(AdminUserSerializer(teacher).data)

    @action(detail=True, methods=["post"], url_path="disable-account")
    def disable_account(self, request, pk=None):
        teacher = self.get_object()
        serializer = AdminDisableAccountSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        old_status = teacher.account_status
        teacher.account_status = AccountStatus.DISABLED
        teacher.is_active = False
        teacher.suspension_reason = serializer.validated_data.get("reason", "")
        teacher.save()
        self._log(teacher, AdminAction.ACTION_DISABLE_ACCOUNT, old_status, AccountStatus.DISABLED,
                   serializer.validated_data.get("reason", ""))
        return Response(AdminUserSerializer(teacher).data)

    @action(detail=True, methods=["post"], url_path="activate-account")
    def activate_account(self, request, pk=None):
        teacher = self.get_object()
        old_status = teacher.account_status
        teacher.account_status = AccountStatus.ACTIVE
        teacher.is_active = True
        teacher.suspension_reason = ""
        teacher.save()
        self._log(teacher, AdminAction.ACTION_ACTIVATE_ACCOUNT, old_status, AccountStatus.ACTIVE)
        return Response(AdminUserSerializer(teacher).data)


class AdminActionListView(generics.ListAPIView):
    """Admin-only audit log, mirrors the developer panel's "سجل الإجراءات" view."""

    serializer_class = AdminActionSerializer
    permission_classes = [IsAdminRole]

    def get_queryset(self):
        return AdminAction.objects.select_related("teacher", "admin").all()
