from django.db import transaction
from django.core.exceptions import ValidationError
from django.utils.crypto import get_random_string
from apps.Users.models import Profile
from .models import RecyclingTransaction, RewardRedemption, Reward, Kiosk


class CoreService:

    @staticmethod
    @transaction.atomic
    def process_recycling(user, kiosk_id, weight_kg):
        """Calculates points, records transaction, and updates user profile safely."""
        # 1 KG = 10 Points (Configurable multiplier)
        points_earned = int(float(weight_kg) * 10)

        kiosk = Kiosk.objects.get(id=kiosk_id)

        # 1. Create Transaction
        trx = RecyclingTransaction.objects.create(
            user=user,
            kiosk=kiosk,
            weight_kg=weight_kg,
            points_earned=points_earned
        )

        # 2. Update Dual-Point Profile
        profile = user.profile
        profile.current_points += points_earned
        profile.total_points += points_earned
        profile.save(update_fields=['current_points', 'total_points'])

        # 3. Check for Rank Upgrades
        profile.check_and_update_rank()

        return trx

    @staticmethod
    @transaction.atomic
    def redeem_reward(user, reward_id):
        """Handles point deduction and voucher generation securely."""
        profile = user.profile
        # Select for update locks the row to prevent race conditions (double spending)
        reward = Reward.objects.select_for_update().get(id=reward_id, is_active=True)

        if profile.current_points < reward.points_required:
            raise ValidationError("Insufficient points for this reward.")

        if reward.stock <= 0:
            raise ValidationError("This reward is out of stock.")

        # Deduct Points & Stock
        profile.current_points -= reward.points_required
        profile.save(update_fields=['current_points'])

        reward.stock -= 1
        reward.save(update_fields=['stock'])

        # Generate unique 8-character alphanumeric voucher code
        voucher_code = get_random_string(8).upper()

        redemption = RewardRedemption.objects.create(
            user=user,
            reward=reward,
            redemption_code=voucher_code
        )

        return redemption