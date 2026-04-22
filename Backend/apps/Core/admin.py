from django.contrib import admin
from .models import Partner, Reward, Kiosk, RecyclingTransaction, RewardRedemption, Badge, UserBadge


@admin.register(Partner)
class PartnerAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'is_active')
    search_fields = ('name', 'description')
    list_filter = ('is_active',)
    list_editable = ('is_active',)
    ordering = ('id',)


@admin.register(Reward)
class RewardAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'partner', 'points_required', 'stock', 'is_active')
    search_fields = ('title', 'partner__name')
    list_filter = ('is_active', 'partner')
    list_editable = ('stock', 'is_active')
    ordering = ('-id',)


@admin.register(Kiosk)
class KioskAdmin(admin.ModelAdmin):
    list_display = ('id', 'location_name', 'latitude', 'longitude', 'is_operational')
    search_fields = ('location_name',)
    list_filter = ('is_operational',)
    list_editable = ('is_operational',)
    ordering = ('id',)


@admin.register(RecyclingTransaction)
class RecyclingTransactionAdmin(admin.ModelAdmin):
    # This acts as your transaction ledger
    list_display = ('user', 'kiosk', 'weight_kg', 'points_earned', 'created_at')
    search_fields = ('user__username', 'user__email', 'user__phone', 'kiosk__location_name', 'transaction_id')
    list_filter = ('created_at', 'kiosk')
    readonly_fields = ('transaction_id', 'created_at')
    ordering = ('-created_at',)

    # Prevent manual editing of ledger records from the admin to maintain integrity
    def has_change_permission(self, request, obj=None):
        return False


@admin.register(RewardRedemption)
class RewardRedemptionAdmin(admin.ModelAdmin):
    list_display = ('redemption_code', 'user', 'reward', 'is_used_at_partner', 'redeemed_at')
    search_fields = ('redemption_code', 'user__username', 'user__email', 'reward__title')
    list_filter = ('is_used_at_partner', 'redeemed_at')
    readonly_fields = ('redemption_code', 'redeemed_at')
    ordering = ('-redeemed_at',)


@admin.register(Badge)
class BadgeAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'metric', 'threshold')
    search_fields = ('name', 'description')
    list_filter = ('metric',)
    list_editable = ('metric', 'threshold')
    ordering = ('metric', 'threshold')


@admin.register(UserBadge)
class UserBadgeAdmin(admin.ModelAdmin):
    list_display = ('user', 'badge', 'earned_at')
    search_fields = ('user__username', 'user__email', 'badge__name')
    list_filter = ('badge', 'earned_at')
    readonly_fields = ('earned_at',)
    ordering = ('-earned_at',)

    # Optional: Prevent manual editing of earned badges to maintain integrity
    def has_change_permission(self, request, obj=None):
        return False