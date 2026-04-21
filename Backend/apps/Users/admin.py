from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, Profile


class ProfileInline(admin.StackedInline):
    model = Profile
    can_delete = False
    verbose_name_plural = "Profile"


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    inlines = [ProfileInline]
    # Jazzmin will automatically style all your default UserAdmin fields!


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ["user", "has_reset_token"]

    def has_reset_token(self, obj):
        return bool(obj.reset_password_token)

    has_reset_token.boolean = True