from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.admin import GroupAdmin as BaseGroupAdmin
from django.contrib.auth.models import Group, User as AuthUser
from django.utils.translation import gettext_lazy as _

# --- UNFOLD IMPORTS ---
from unfold.admin import ModelAdmin, StackedInline
from unfold.forms import AdminPasswordChangeForm, UserChangeForm, UserCreationForm

# --- LOCAL IMPORTS ---
from .models import User, Profile


# ==============================================================================
# 1. CUSTOM USER & PROFILE ADMIN
# ==============================================================================

class ProfileInline(StackedInline):
    """
    Allows editing the User Profile directly inside the User edit page.
    """
    model = Profile
    can_delete = False
    verbose_name_plural = 'Profile'
    fk_name = 'user'


# IMPORTANT: ModelAdmin MUST come before BaseUserAdmin!
@admin.register(User)
class UserAdmin(ModelAdmin, BaseUserAdmin):
    # Unfold Forms
    form = UserChangeForm
    add_form = UserCreationForm
    change_password_form = AdminPasswordChangeForm

    inlines = (ProfileInline,)

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

    list_filter = (
        "is_staff",
        "is_superuser",
        "is_active",
        "groups",
        "email_verified",
        "phone_verified",
        "accept_terms",
    )

    search_fields = ("username", "first_name", "last_name", "email", "phone", "uuid")
    ordering = ("-date_joined",)

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
                "classes": ["collapse"],
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
                "classes": ["collapse"],
                "fields": ("uuid",)
            }
        ),
    )

    add_fieldsets = (
        (None, {
            "classes": ["wide"],
            "fields": ("username", "email", "password", "first_name", "last_name"),
        }),
    )

    readonly_fields = ("uuid", "created_at", "date_joined", "last_login")


@admin.register(Profile)
class ProfileAdmin(ModelAdmin):
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


# ==============================================================================
# 2. DEFAULT AUTH MODELS UNREGISTER & UNFOLD RE-REGISTER
# ==============================================================================

# Unregister default Group and re-register with Unfold
admin.site.unregister(Group)


# IMPORTANT: ModelAdmin MUST come before BaseGroupAdmin
@admin.register(Group)
class UnfoldGroupAdmin(ModelAdmin, BaseGroupAdmin):
    pass


# Unregister default AuthUser and re-register with Unfold (Safe wrapped)
try:
    admin.site.unregister(AuthUser)

    # IMPORTANT: ModelAdmin MUST come before BaseUserAdmin
    @admin.register(AuthUser)
    class UnfoldAuthUserAdmin(ModelAdmin, BaseUserAdmin):
        form = UserChangeForm
        add_form = UserCreationForm
        change_password_form = AdminPasswordChangeForm
except admin.sites.NotRegistered:
    # If AuthUser is already unregistered (e.g. by settings.AUTH_USER_MODEL)
    pass