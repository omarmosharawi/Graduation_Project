from rest_framework import serializers
from .models import Partner, Reward, Kiosk, RecyclingTransaction, DelegateRequest


class PartnerSerializer(serializers.ModelSerializer):
    """Provides essential partner details for the frontend UI."""

    class Meta:
        model = Partner
        fields = ('id', 'name', 'logo')


class RewardSerializer(serializers.ModelSerializer):
    """Formats the rewards catalog, including nested partner info."""
    partner = PartnerSerializer(read_only=True)

    class Meta:
        model = Reward
        fields = (
            'id',
            'partner',
            'title',
            'description',
            'points_required',
            'stock'
        )


class KioskSerializer(serializers.ModelSerializer):
    """Provides kiosk location data for transaction history."""

    class Meta:
        model = Kiosk
        fields = ('id', 'name', 'location_name', 'latitude', 'longitude', 'is_operational')


class TransactionSerializer(serializers.ModelSerializer):
    """Formats the user's recycling history."""
    kiosk = KioskSerializer(read_only=True)

    # Format the date nicely for the mobile app
    date_formatted = serializers.SerializerMethodField()

    class Meta:
        model = RecyclingTransaction
        fields = (
            'transaction_id', 'kiosk',
            'material_type', 'material_count', 'weight_kg',
            'points_earned', 'created_at', 'date_formatted'
        )

    def get_date_formatted(self, obj):
        return obj.created_at.strftime("%B %d, %Y - %I:%M %p")


class DelegateRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = DelegateRequest
        fields = (
            'id', 'pickup_address', 'latitude', 'longitude',
            'scheduled_date', 'scheduled_time',
            'material_type', 'material_count', 'status',
            'estimated_arrival_time', 'cost_in_points', 'created_at'
        )
        read_only_fields = ('id', 'status', 'estimated_arrival_time', 'cost_in_points', 'created_at')