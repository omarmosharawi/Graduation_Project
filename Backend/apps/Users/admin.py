from django.contrib import admin
from django.utils.html import format_html
from django.utils.translation import gettext_lazy as _
from django.contrib.auth.models import Group
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User

try:
    from .models import Profile
except ImportError:
    pass


# ==========================================
# CUSTOM FILTER FOR GOOGLE AUTH
# ==========================================
class AuthMethodFilter(admin.SimpleListFilter):
    title = _('Login Method')
    parameter_name = 'auth_method'

    def lookups(self, request, model_admin):
        return (
            ('google', _('Google (Firebase)')),
            ('standard', _('Standard (Email/Password)')),
        )

    def queryset(self, request, queryset):
        # Users who sign up with Google have their password set to unusable (starts with '!')
        if self.value() == 'google':
            return queryset.filter(password__startswith='!')
        if self.value() == 'standard':
            return queryset.exclude(password__startswith='!')
        return queryset


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
    # readonly_fields += ('current_points', 'total_points', 'rank')

    # Explicitly list ALL fields so nothing is hidden
    fields = ('rank', 'current_points', 'total_points', 'invite_code', 'referred_by', 'reset_password_token',
              'reset_password_expire')

    # Creates a search bar for the 'referred_by' field instead of a long dropdown
    autocomplete_fields = ['referred_by']


# Register Profile separately so you can filter specifically by Gamification Ranks
@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'rank', 'current_points', 'total_points', 'invite_code', 'referred_by')
    list_filter = ('rank', 'referred_by')
    search_fields = ('user__username', 'user__email', 'user__phone', 'invite_code')
    readonly_fields = ('invite_code', 'reset_password_token', 'reset_password_expire')
    # list_editable = ('current_points', 'total_points')
    ordering = ('-total_points',)

    autocomplete_fields = ['referred_by']

    def referred_by_username(self, obj):
        if obj.referred_by:
            return obj.referred_by.user.username
        return "-"

    referred_by_username.short_description = "Referred By"
    referred_by_username.admin_order_field = 'referred_by__user__username'

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(User)
class CustomUserAdmin(admin.ModelAdmin):
    inlines = (ProfileInline,)

    # What shows up on the main list table
    list_display = ('uuid', 'username', 'email', 'phone', 'first_name', 'last_name', 'is_active', 'email_verified', 'phone_verified', 'login_method')

    # Filters on the right sidebar
    list_filter = ('is_active', AuthMethodFilter, 'is_staff', 'email_verified', 'phone_verified')

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

    # DEFINE THE UI FOR THE LOGIN METHOD COLUMN
    def login_method(self, obj):
        """Displays a clean UI badge indicating if the user uses Google or Password."""
        if not obj.has_usable_password():
            return format_html(
                '<span style="color: white; background-color: #DB4437; padding: 3px 8px; border-radius: 4px; font-weight: bold;">Google</span>')
        return format_html(
            '<span style="color: white; background-color: #4CAF50; padding: 3px 8px; border-radius: 4px; font-weight: bold;">Standard</span>')

    login_method.short_description = "Auth Method"

    def save_formset(self, request, form, formset, change):
        instances = formset.save(commit=False)
        for instance in instances:
            # If the inline being saved is the Profile...
            if isinstance(instance, Profile):
                try:
                    # Check if the background signal already created it
                    existing_profile = Profile.objects.get(user=form.instance)
                    # The Magic Trick: Give the inline form the existing database ID.
                    # This forces Django to UPDATE the row instead of creating a duplicate!
                    instance.id = existing_profile.id
                except Profile.DoesNotExist:
                    pass

            instance.save()

        formset.save_m2m()


# Optional: Unregister the default Group model if you aren't using Django's built-in permission groups
admin.site.unregister(Group)
