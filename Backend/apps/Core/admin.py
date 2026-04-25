from django.contrib import admin
from django.contrib import messages
from django.utils.html import format_html
from django.utils.safestring import mark_safe
from django.db.models import Sum
from apps.Users.models import User
from .models import (
    Partner, Reward, Kiosk, RecyclingTransaction,
    RewardRedemption, Badge, UserBadge,
    CustomNotification, DelegateRequest, CommunityImpact,
    PartnerCategory, HomeCard, Coupon, CouponRedemption
)
from .Tasks.notification_tasks import process_custom_notification


# ==========================================
# PARTNERS & REWARDS & COUPON
# ==========================================

class RewardInline(admin.TabularInline):
    """Allows viewing and editing Rewards directly inside the Partner's page."""
    model = Reward
    extra = 1
    fields = ('title', 'description', 'points_required', 'stock', 'is_active')


@admin.register(PartnerCategory)
class PartnerCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'display_icon')
    search_fields = ('name',)

    def display_icon(self, obj):
        if obj.icon:
            return format_html('<img src="{}" width="30" height="30" style="border-radius: 4px;" />', obj.icon.url)
        return "-"
    display_icon.short_description = 'Icon'


@admin.register(Partner)
class PartnerAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'category', 'display_logo', 'is_active')
    search_fields = ('name', 'description')
    list_filter = ('category', 'is_active')
    list_editable = ('is_active',)
    ordering = ('id',)
    inlines = [RewardInline]

    fieldsets = (
        ('Partner Details', {
            'fields': ('name', 'category', 'description', 'logo', 'is_active')
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


@admin.register(Coupon)
class CouponAdmin(admin.ModelAdmin):
    list_display = ('code', 'reward_points', 'current_uses', 'max_uses', 'is_active', 'is_first_time_only', 'valid_to')
    list_filter = ('is_active', 'is_first_time_only', 'valid_from', 'valid_to')
    search_fields = ('code', 'description')
    list_editable = ('is_active',)

    fieldsets = (
        ('Coupon Details', {
            'fields': ('code', 'description', 'reward_points')
        }),
        ('Rules & Limits', {
            'fields': ('is_active', 'is_first_time_only', 'max_uses', 'current_uses')
        }),
        ('Schedule (Optional)', {
            'fields': ('valid_from', 'valid_to'),
            'description': "Leave blank if the coupon does not expire."
        }),
    )


@admin.register(CouponRedemption)
class CouponRedemptionAdmin(admin.ModelAdmin):
    list_display = ('user', 'coupon', 'redeemed_at')
    list_filter = ('coupon', 'redeemed_at')
    search_fields = ('user__username', 'coupon__code')
    readonly_fields = ('user', 'coupon', 'redeemed_at')

    def has_add_permission(self, request):
        # Admins shouldn't manually add, users do it via the API
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


# ==========================================
# KIOSKS & TRANSACTIONS
# ==========================================

@admin.register(Kiosk)
class KioskAdmin(admin.ModelAdmin):
    list_display = ('name', 'address', 'opening_hours', 'status', 'current_capacity', 'max_capacity', 'last_updated')
    search_fields = ('name', 'address')
    list_filter = ('status',)

    # Allow admins to quickly toggle status or fix capacity from the list view
    list_editable = ('status', 'current_capacity')
    readonly_fields = ('last_updated',)

    fieldsets = (
        ('Location & Info', {
            'fields': ('name', 'address', 'opening_hours')
        }),
        ('Live Hardware Status', {
            'fields': ('status', 'last_updated')
        }),
        ('Inventory Metrics', {
            'fields': ('current_capacity', 'max_capacity', 'plastic_count', 'metal_count')
        }),
        ('Map Coordinates', {
            'fields': ('latitude', 'longitude')
        }),
    )


@admin.register(RecyclingTransaction)
class RecyclingTransactionAdmin(admin.ModelAdmin):
    list_display = ('transaction_id', 'user', 'kiosk', 'material_type', 'material_count', 'weight_kg', 'points_earned',
                    'created_at')
    search_fields = ('user__username', 'user__email', 'user__phone', 'kiosk__name', 'kiosk__location_name', 'transaction_id')
    list_filter = ('created_at', 'kiosk', 'material_type')
    readonly_fields = ('transaction_id', 'created_at', 'user', 'kiosk', 'material_type', 'material_count', 'weight_kg',
                       'points_earned')
    ordering = ('-created_at',)

    fieldsets = (
        ('Ledger Record', {
            'fields': ('transaction_id', 'created_at')
        }),
        ('Transaction Details', {
            'fields': ('user', 'kiosk', 'material_type', 'material_count', 'weight_kg', 'points_earned')
        }),
    )

    def has_add_permission(self, request):
        # Admins shouldn't manually add, users do it via the API
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


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

    def has_add_permission(self, request):
        # Admins shouldn't manually add, users do it via the API
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


# ==========================================
# GAMIFICATION & NOTIFICATIONS
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

    def has_add_permission(self, request):
        # Admins shouldn't manually add, users do it via the API
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
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
# DELEGATE REQUESTS (ON-DEMAND)
# ==========================================

@admin.register(DelegateRequest)
class DelegateRequestAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'scheduled_date', 'scheduled_time', 'material_type', 'material_count', 'status',
                    'cost_in_points', 'actual_weight_kg', 'display_proof')
    list_filter = ('status', 'scheduled_date', 'material_type')
    search_fields = ('user__username', 'pickup_address', 'user__email', 'user__phone')
    list_editable = ('status',)
    readonly_fields = ('cost_in_points', 'created_at', 'user', 'display_proof')
    actions = ['mark_as_assigned', 'mark_as_completed', 'mark_as_cancelled']

    fieldsets = (
        ('Request Info', {
            'fields': ('user', 'cost_in_points')
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
        ('Driver Completion Data', {
            'fields': ('actual_weight_kg', 'proof_image', 'display_proof'),
            'description': "Data submitted automatically by the driver via the Delegate App."
        }),
        ('System Logs', {
            'fields': ('created_at',),
            'classes': ('collapse',)  # Hides this section by default to keep the UI clean
        }),
    )

    def has_add_permission(self, request):
        # Admins shouldn't manually add, users do it via the API
        return False

    # Beautiful, clickable image preview for the operations team
    def display_proof(self, obj):
        if obj.proof_image:
            # Renders a small thumbnail that admins can click to open the full-resolution image
            return format_html(
                '<a href="{}" target="_blank">'
                '<img src="{}" width="80" height="80" style="border-radius: 6px; object-fit: cover; box-shadow: 0 2px 4px rgba(0,0,0,0.1);" />'
                '</a>',
                obj.proof_image.url, obj.proof_image.url
            )
        return format_html('<span style="color: gray;"><i>No proof uploaded</i></span>')

    display_proof.short_description = "Proof of Pickup"

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

# ==========================================
# Home Card
# ==========================================

@admin.register(HomeCard)
class HomeCardAdmin(admin.ModelAdmin):
    list_display = ('title', 'card_type', 'priority', 'is_active', 'display_image')
    list_filter = ('card_type', 'is_active')
    search_fields = ('title', 'description', 'coupon_code')
    list_editable = ('priority', 'is_active')  # Allows quick sorting directly from the list table

    fieldsets = (
        ('Card Content', {
            'fields': ('title', 'description', 'image', 'card_type')
        }),
        ('Interactions & Actions', {
            'fields': ('reference_url', 'coupon_code')
        }),
        ('Display Rules', {
            'fields': ('priority', 'is_active')
        }),
    )

    def display_image(self, obj):
        if obj.image:
            return format_html('<img src="{}" height="50" style="border-radius: 6px;" />', obj.image.url)
        return "-"

    display_image.short_description = 'Banner Preview'


# ==========================================
# THE COMMUNITY IMPACT DASHBOARD
# ==========================================

@admin.register(CommunityImpact)
class CommunityImpactAdmin(admin.ModelAdmin):
    """
    A custom admin dashboard using a proxy model. It calculates the live platform
    stats and displays them using a clean HTML layout.
    """

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def get_queryset(self, request):
        # Return an empty queryset so no rows are queried or displayed
        return super().get_queryset(request).none()

    def changelist_view(self, request, extra_context=None):
        # 1. Base Global Stats
        total_weight_stats = RecyclingTransaction.objects.aggregate(total_kg=Sum('weight_kg'))
        total_kg = total_weight_stats['total_kg'] or 0
        co2_saved = float(total_kg) * 1.5

        total_users = User.objects.count()
        total_redemptions = RewardRedemption.objects.count()
        total_pickups = DelegateRequest.objects.filter(status='COMPLETED').count()

        # 2. Material Breakdown
        materials = RecyclingTransaction.objects.values('material_type').annotate(
            total_weight=Sum('weight_kg')
        ).order_by('-total_weight')

        materials_html = "".join(
            [f"<li><b>{m['material_type']}</b>: {m['total_weight'] or 0} KG</li>" for m in materials])
        if not materials_html:
            materials_html = "<li>No materials recycled yet.</li>"

        # 3. Top Kiosks
        top_kiosks = RecyclingTransaction.objects.filter(kiosk__isnull=False).values(
            'kiosk__name'
        ).annotate(
            total_contributed=Sum('weight_kg')
        ).order_by('-total_contributed')[:3]

        kiosks_html = "".join(
            [f"<li><b>{k['kiosk__name']}</b>: {k['total_contributed'] or 0} KG</li>" for k in top_kiosks])
        if not kiosks_html:
            kiosks_html = "<li>No kiosk data yet.</li>"

        # 4. Inject the HTML into the Django UI securely using Flexbox for a 3-column layout
        dashboard_html = f"""
        <div style="font-size: 15px; padding: 15px; line-height: 1.6; background-color: var(--body-bg); color: var(--body-fg); border-radius: 8px;">
            <h2 style="margin-top: 0; border-bottom: 1px solid var(--border-color); padding-bottom: 10px;">🌍 LIVE PLATFORM IMPACT</h2>
            <div style="display: flex; gap: 40px; flex-wrap: wrap; margin-top: 15px;">
                <div style="flex: 1; min-width: 200px;">
                    <h3 style="margin-bottom: 10px;">📈 Global Stats</h3>
                    • Active Recyclers: <b>{total_users}</b><br>
                    • Total Weight: <b>{total_kg} KG</b><br>
                    • Estimated CO2 Saved: <b>{co2_saved} KG</b><br>
                    • Rewards Claimed: <b>{total_redemptions}</b><br>
                    • Delegate Pickups: <b>{total_pickups}</b>
                </div>
                <div style="flex: 1; min-width: 200px;">
                    <h3 style="margin-bottom: 10px;">♻️ Material Breakdown</h3>
                    <ul style="margin: 0; padding-left: 20px;">
                        {materials_html}
                    </ul>
                </div>
                <div style="flex: 1; min-width: 200px;">
                    <h3 style="margin-bottom: 10px;">📍 Top 3 Kiosks</h3>
                    <ul style="margin: 0; padding-left: 20px;">
                        {kiosks_html}
                    </ul>
                </div>
            </div>
        </div>
        """

        messages.info(request, mark_safe(dashboard_html))

        return super().changelist_view(request, extra_context=extra_context)