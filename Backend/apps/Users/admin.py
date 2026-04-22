from django.contrib import admin
from django.contrib.auth.models import Group
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User

try:
    from .models import Profile
except ImportError:
    pass


class ProfileInline(admin.StackedInline):
    """
    Embeds the Profile fields directly inside the User admin page
    so you don't have to click back and forth.
    """
    model = Profile
    can_delete = False
    verbose_name_plural = 'User Profile Data'
    fk_name = 'user'

    # Protect gamification and referral integrity by making them read-only
    readonly_fields = ('invite_code', 'reset_password_token', 'reset_password_expire')

    # If you don't want admins manually changing points/ranks, uncomment the line below:
    readonly_fields += ('current_points', 'total_points', 'rank')


@admin.register(User)
class CustomUserAdmin(admin.ModelAdmin):
    inlines = (ProfileInline,)

    # What shows up on the main list table
    list_display = ('uuid', 'username', 'email', 'phone', 'first_name', 'last_name', 'is_active', 'email_verified', 'phone_verified')

    # Filters on the right sidebar
    list_filter = ('is_active', 'is_staff', 'email_verified', 'phone_verified')

    # Search bar targets
    search_fields = ('username', 'email', 'phone', 'first_name', 'last_name', 'uuid')

    # Prevent manual editing of sensitive automated fields
    readonly_fields = ('uuid', 'last_login', 'otp', 'otp_created_at', 'otp_attempts')

    # Categorize fields into clean sections in the detail view
    fieldsets = (
        ('Personal Info', {
            'fields': ('uuid', 'first_name', 'last_name', 'username', 'email', 'phone', 'profile_picture')
        }),
        ('Permissions & Status', {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')
        }),
        ('Verification & Security', {
            'fields': ('email_verified', 'phone_verified', 'password', 'otp', 'otp_created_at', 'otp_attempts')
        }),
        ('Important Dates', {
            'fields': ('last_login',)
        }),
    )


# Register Profile separately so you can filter specifically by Gamification Ranks
@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'rank', 'current_points', 'total_points', 'invite_code')
    list_filter = ('rank',)
    search_fields = ('user__username', 'user__email', 'user__phone', 'invite_code')
    readonly_fields = ('invite_code', 'reset_password_token', 'reset_password_expire')

    # Add editables so you can adjust points directly from the list view if needed
    list_editable = ('current_points', 'total_points')
    ordering = ('-total_points',)

# Optional: Unregister the default Group model if you aren't using Django's built-in permission groups
admin.site.unregister(Group)