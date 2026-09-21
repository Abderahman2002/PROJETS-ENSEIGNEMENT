from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import AdminAction, PasswordResetCode, User


class UserAdmin(BaseUserAdmin):
    ordering = ["-created_at"]
    list_display = ["phone", "full_name", "role", "account_status", "subscription_status", "is_active"]
    list_filter = ["role", "account_status", "subscription_status"]
    search_fields = ["phone", "full_name", "national_id", "financial_index"]
    fieldsets = None
    add_fieldsets = None
    filter_horizontal = ()


admin.site.register(User, UserAdmin)
admin.site.register(AdminAction)
admin.site.register(PasswordResetCode)
