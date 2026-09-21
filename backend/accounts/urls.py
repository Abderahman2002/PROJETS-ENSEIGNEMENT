from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from django.urls import include, path

from .views import (
    AdminActionListView,
    AdminUserViewSet,
    ForgotPasswordConfirmView,
    ForgotPasswordRequestView,
    MeView,
    PhoneTokenObtainPairView,
    RegisterView,
)

admin_router = DefaultRouter()
admin_router.register("users", AdminUserViewSet, basename="admin-user")

urlpatterns = [
    path("register/", RegisterView.as_view(), name="auth-register"),
    path("login/", PhoneTokenObtainPairView.as_view(), name="auth-login"),
    path("refresh/", TokenRefreshView.as_view(), name="auth-refresh"),
    path("me/", MeView.as_view(), name="auth-me"),
    path("forgot-password/request/", ForgotPasswordRequestView.as_view(), name="auth-forgot-request"),
    path("forgot-password/confirm/", ForgotPasswordConfirmView.as_view(), name="auth-forgot-confirm"),
    path("admin/actions/", AdminActionListView.as_view(), name="auth-admin-actions"),
    path("admin/", include(admin_router.urls)),
]
