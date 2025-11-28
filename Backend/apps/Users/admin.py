from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _
from .models import User, Profile


class ProfileInline(admin.StackedInline):
    """
    Allows editing the User Profile (reset tokens, etc.) directly
    inside the User edit page.
    """
    model = Profile
    can_delete = False
    verbose_name_plural = 'Profile'
    fk_name = 'user'


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    # Add the Profile inline to the User admin
    inlines = (ProfileInline,)

    # Columns to show in the list view
    list_display = (
        "username",
        "email",
        "first_name",
        "last_name",
        "is_staff",
        "email_verified",
        "phone_verified",
        "created_at",
    )

    # Filters sidebar
    list_filter = (
        "is_staff",
        "is_superuser",
        "is_active",
        "groups",
        "email_verified",
        "phone_verified",
        "accept_terms",
    )

    # Fields to search by
    search_fields = ("username", "first_name", "last_name", "email", "phone", "uuid")
    ordering = ("-date_joined",)

    # Organized field grouping for the Edit User page
    fieldsets = (
        (None, {"fields": ("username", "password")}),
        (_("Personal info"), {"fields": ("first_name", "last_name", "email", "phone", "profile_picture")}),
        (
            _("Permissions"),
            {
                "fields": (
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                ),
            },
        ),
        (
            _("Verification Details"),
            {
                "fields": ("email_verified", "phone_verified", "accept_terms"),
                "description": "Status of user verification steps."
            }
        ),
        (
            _("OTP & Security"),
            {
                "classes": ("collapse",),
                "fields": ("otp", "otp_created_at", "otp_attempts"),
                "description": "One-Time Password logs and tracking."
            }
        ),
        (
            _("Important dates"),
            {
                "fields": ("last_login", "date_joined", "created_at")
            }
        ),
        (
            _("System Info"),
            {
                "classes": ("collapse",),
                "fields": ("uuid",)
            }
        ),
    )

    # Fields that should not be editable
    readonly_fields = ("uuid", "created_at", "date_joined", "last_login")


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    """
    Separate admin view for Profiles, useful for debugging reset tokens.
    """
    list_display = ("user", "has_reset_token", "reset_password_expire")
    search_fields = ("user__username", "user__email")
    list_select_related = ("user",)

    def has_reset_token(self, obj):
        return bool(obj.reset_password_token)

    has_reset_token.boolean = True
    has_reset_token.short_description = "Reset Token Active"