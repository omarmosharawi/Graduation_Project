from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.admin import GroupAdmin as BaseGroupAdmin
from django.contrib.auth.models import Group
from django.utils.translation import gettext_lazy as _

# --- UNFOLD IMPORTS ---
from unfold.admin import ModelAdmin, StackedInline
from unfold.forms import AdminPasswordChangeForm, UserChangeForm, UserCreationForm

# --- LOCAL IMPORTS ---
from .models import User, Profile


# ==============================================================================
# 1. CUSTOM USER CREATION FORM
# ==============================================================================
class CustomUserCreationForm(UserCreationForm):
    class Meta(UserCreationForm.Meta):
        model = User
        fields = ("username", "email", "first_name", "last_name")


# ==============================================================================
# 2. PROFILE INLINE
# ==============================================================================
class ProfileInline(StackedInline):
    model = Profile
    can_delete = False
    verbose_name_plural = "Profile"
    fk_name = "user"


# ==============================================================================
# 3. CUSTOM USER ADMIN
# ==============================================================================
@admin.register(User)
class UserAdmin(BaseUserAdmin, ModelAdmin):  # BaseUserAdmin MUST be first!

    form = UserChangeForm
    add_form = CustomUserCreationForm
    change_password_form = AdminPasswordChangeForm

    inlines = [ProfileInline]

    list_display = [
        "username", "email", "first_name", "last_name",
        "is_staff", "email_verified", "phone_verified", "created_at"
    ]

    list_filter = ["is_staff", "is_superuser", "is_active", "email_verified"]
    search_fields = ["username", "first_name", "last_name", "email", "phone"]
    ordering = ["-date_joined"]

    # STRIPPED OUT 'classes' ENTIRELY TO BYPASS THE UNFOLD BUG
    fieldsets = (
        (None, {"fields": ("username", "password")}),
        (_("Personal info"), {"fields": ("first_name", "last_name", "email", "phone", "profile_picture")}),
        (_("Permissions"), {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        (_("Verification Details"), {"fields": ("email_verified", "phone_verified", "accept_terms")}),
        (_("OTP & Security"), {"fields": ("otp", "otp_created_at", "otp_attempts")}),
        (_("Important dates"), {"fields": ("last_login", "date_joined", "created_at")}),
        (_("System Info"), {"fields": ("uuid",)}),
    )

    # STRIPPED OUT 'classes' HERE AS WELL
    add_fieldsets = (
        (None, {
            "fields": ("username", "email", "first_name", "last_name", "password1", "password2"),
        }),
    )

    readonly_fields = ["uuid", "created_at", "date_joined", "last_login"]


# ==============================================================================
# 4. PROFILE ADMIN
# ==============================================================================
@admin.register(Profile)
class ProfileAdmin(ModelAdmin):
    list_display = ["user", "has_reset_token", "reset_password_expire"]
    search_fields = ["user__username", "user__email"]
    list_select_related = ["user"]

    def has_reset_token(self, obj):
        return bool(obj.reset_password_token)

    has_reset_token.boolean = True
    has_reset_token.short_description = "Reset Token Active"


# ==============================================================================
# 5. GROUP ADMIN
# ==============================================================================
admin.site.unregister(Group)

@admin.register(Group)
class UnfoldGroupAdmin(BaseGroupAdmin, ModelAdmin):
    pass