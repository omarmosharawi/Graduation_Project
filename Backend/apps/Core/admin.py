from django.contrib import admin
from django.contrib import messages
from django.utils.html import format_html
from .models import (
    Partner, Reward, Kiosk, RecyclingTransaction,
    RewardRedemption, Badge, UserBadge,
    CustomNotification, DelegateRequest
)
from .Tasks.notification_tasks import process_custom_notification


# ==========================================
# 1. PARTNERS & REWARDS
# ==========================================

class RewardInline(admin.TabularInline):
    """Allows viewing and editing Rewards directly inside the Partner's page."""
    model = Reward
    extra = 1
    fields = ('title', 'description', 'points_required', 'stock', 'is_active')


@admin.register(Partner)
class PartnerAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'display_logo', 'is_active')
    search_fields = ('name', 'description')
    list_filter = ('is_active',)
    list_editable = ('is_active',)
    ordering = ('id',)
    inlines = [RewardInline]

    fieldsets = (
        ('Partner Details', {
            'fields': ('name', 'description', 'logo', 'is_active')
        }),
    )

    def display_logo(self, obj):
        """Renders the partner logo directly in the admin list view."""
        if obj.logo:
            return format_html('<img src="{}" width="40" height="40" style="border-radius: 4px;" />', obj.logo.url)
        return "-"

    display_logo.short_description = 'Logo'


@admin.register(Reward)
class RewardAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'partner', 'points_required', 'stock', 'is_active')
    search_fields = ('title', 'description', 'partner__name')
    list_filter = ('is_active', 'partner')
    list_editable = ('stock', 'is_active')
    ordering = ('-id',)

    fieldsets = (
        ('Reward Info', {
            'fields': ('partner', 'title', 'description')
        }),
        ('Inventory & Rules', {
            'fields': ('points_required', 'stock', 'is_active')
        }),
    )


# ==========================================
# 2. KIOSKS & TRANSACTIONS
# ==========================================

@admin.register(Kiosk)
class KioskAdmin(admin.ModelAdmin):
    list_display = ('id', 'location_name', 'latitude', 'longitude', 'is_operational')
    search_fields = ('location_name',)
    list_filter = ('is_operational',)
    list_editable = ('is_operational',)
    ordering = ('id',)

    fieldsets = (
        ('Kiosk Details', {
            'fields': ('location_name', 'is_operational')
        }),
        ('Map Coordinates', {
            'fields': ('latitude', 'longitude')
        }),
    )


@admin.register(RecyclingTransaction)
class RecyclingTransactionAdmin(admin.ModelAdmin):
    list_display = ('transaction_id', 'user', 'kiosk', 'weight_kg', 'points_earned', 'created_at')
    search_fields = ('user__username', 'user__email', 'user__phone', 'kiosk__location_name', 'transaction_id')
    list_filter = ('created_at', 'kiosk')
    readonly_fields = ('transaction_id', 'created_at', 'user', 'kiosk', 'weight_kg', 'points_earned')
    ordering = ('-created_at',)

    fieldsets = (
        ('Ledger Record', {
            'fields': ('transaction_id', 'created_at')
        }),
        ('Transaction Details', {
            'fields': ('user', 'kiosk', 'weight_kg', 'points_earned')
        }),
    )

    def has_change_permission(self, request, obj=None):
        return False  # Strict ledger integrity


@admin.register(RewardRedemption)
class RewardRedemptionAdmin(admin.ModelAdmin):
    list_display = ('redemption_code', 'user', 'reward', 'is_used_at_partner', 'redeemed_at')
    search_fields = ('redemption_code', 'user__username', 'user__email', 'reward__title')
    list_filter = ('is_used_at_partner', 'redeemed_at')
    readonly_fields = ('redemption_code', 'redeemed_at', 'user', 'reward')
    list_editable = ('is_used_at_partner',)
    ordering = ('-redeemed_at',)

    fieldsets = (
        ('Voucher Info', {
            'fields': ('redemption_code', 'redeemed_at')
        }),
        ('Redemption Details', {
            'fields': ('user', 'reward', 'is_used_at_partner')
        }),
    )


# ==========================================
# 3. GAMIFICATION & NOTIFICATIONS
# ==========================================

@admin.register(Badge)
class BadgeAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'metric', 'threshold', 'display_icon')
    search_fields = ('name', 'description')
    list_filter = ('metric',)
    list_editable = ('metric', 'threshold')
    ordering = ('metric', 'threshold')

    fieldsets = (
        ('Badge Info', {
            'fields': ('name', 'description', 'icon')
        }),
        ('Unlock Criteria', {
            'fields': ('metric', 'threshold')
        }),
    )

    def display_icon(self, obj):
        if obj.icon:
            return format_html('<img src="{}" width="30" height="30" style="border-radius: 4px;" />', obj.icon.url)
        return "-"

    display_icon.short_description = 'Icon'


@admin.register(UserBadge)
class UserBadgeAdmin(admin.ModelAdmin):
    list_display = ('user', 'badge', 'earned_at')
    search_fields = ('user__username', 'user__email', 'badge__name')
    list_filter = ('badge', 'earned_at')
    readonly_fields = ('user', 'badge', 'earned_at')
    ordering = ('-earned_at',)

    def has_change_permission(self, request, obj=None):
        return False


@admin.register(CustomNotification)
class CustomNotificationAdmin(admin.ModelAdmin):
    list_display = ('title', 'target', 'created_at', 'is_sent')
    list_filter = ('target', 'is_sent', 'created_at')
    search_fields = ('title', 'body')
    readonly_fields = ('created_at', 'is_sent')
    filter_horizontal = ('specific_users',)

    fieldsets = (
        ('Message Content', {
            'fields': ('title', 'body')
        }),
        ('Targeting', {
            'fields': ('target', 'specific_users')
        }),
        ('System Status', {
            'fields': ('is_sent', 'created_at')
        }),
    )

    def save_related(self, request, form, formsets, change):
        super().save_related(request, form, formsets, change)
        obj = form.instance
        if not obj.is_sent:
            user_ids = list(obj.specific_users.values_list('id', flat=True)) if obj.target == 'SPECIFIC' else []
            process_custom_notification.delay(
                notification_id=obj.id, title=obj.title, body=obj.body,
                target=obj.target, user_ids=user_ids
            )
            obj.is_sent = True
            obj.save(update_fields=['is_sent'])


# ==========================================
# 4. DELEGATE REQUESTS (ON-DEMAND)
# ==========================================

@admin.register(DelegateRequest)
class DelegateRequestAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'scheduled_date', 'scheduled_time', 'material_type', 'material_count', 'status',
                    'cost_in_points')
    list_filter = ('status', 'scheduled_date', 'material_type')
    search_fields = ('user__username', 'pickup_address', 'user__email')
    list_editable = ('status',)
    readonly_fields = ('cost_in_points', 'created_at', 'user')
    actions = ['mark_as_assigned', 'mark_as_completed', 'mark_as_cancelled']

    fieldsets = (
        ('Request Info', {
            'fields': ('user', 'cost_in_points', 'created_at')
        }),
        ('Pickup Details', {
            'fields': ('pickup_address', 'latitude', 'longitude', 'scheduled_date', 'scheduled_time',
                       'estimated_arrival_time')
        }),
        ('Material Load', {
            'fields': ('material_type', 'material_count')
        }),
        ('Status', {
            'fields': ('status',)
        }),
    )

    @admin.action(description='Mark selected requests as ASSIGNED')
    def mark_as_assigned(self, request, queryset):
        updated = queryset.update(status='ASSIGNED')
        self.message_user(request, f"{updated} requests marked as Assigned.", messages.SUCCESS)

    @admin.action(description='Mark selected requests as COMPLETED')
    def mark_as_completed(self, request, queryset):
        updated = queryset.update(status='COMPLETED')
        self.message_user(request, f"{updated} requests marked as Completed.", messages.SUCCESS)

    @admin.action(description='Mark selected requests as CANCELLED')
    def mark_as_cancelled(self, request, queryset):
        # Note: If cancelled, you might want logic to refund points to the user.
        updated = queryset.update(status='CANCELLED')
        self.message_user(request, f"{updated} requests marked as Cancelled.", messages.WARNING)