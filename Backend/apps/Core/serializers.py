from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers
from .models import Partner, Reward, Kiosk, RecyclingTransaction, DelegateRequest, PartnerCategory, HomeCard


class PartnerCategorySerializer(serializers.ModelSerializer):
    """Provides partner category for the frontend UI."""

    class Meta:
        model = PartnerCategory
        fields = ('id', 'name', 'icon')


class PartnerSerializer(serializers.ModelSerializer):
    """Provides essential partner details for the frontend UI."""
    category = PartnerCategorySerializer(read_only=True)

    class Meta:
        model = Partner
        fields = ('id', 'name', 'category', 'description', 'logo', 'is_active')


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
        fields = (
            'id', 'name', 'address', 'latitude', 'longitude',
            'current_capacity', 'max_capacity', 'plastic_count',
            'metal_count', 'opening_hours', 'status', 'last_updated'
        )


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

    @extend_schema_field(serializers.CharField)
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


# Serializer for a Delegate accepting a job
class AcceptJobInputSerializer(serializers.Serializer):
    request_id = serializers.IntegerField(help_text="The ID of the DelegateRequest to accept.")

# Serializer for a Delegate finishing a job and awarding points
class CompleteJobInputSerializer(serializers.Serializer):
    request_id = serializers.IntegerField()
    actual_weight_kg = serializers.DecimalField(max_digits=6, decimal_places=2, help_text="Exact weight measured by the delegate.")
    material_type = serializers.ChoiceField(choices=['PLASTIC', 'GLASS', 'CANS', 'PAPER', 'MIXED'])
    proof_image = serializers.ImageField(required=False, help_text="Optional photo of the collected materials.")


class HomeCardSerializer(serializers.ModelSerializer):
    class Meta:
        model = HomeCard
        fields = (
            'id', 'title', 'description', 'image',
            'reference_url', 'coupon_code', 'card_type',
            'priority', 'is_active', 'created_at'
        )