from django.db import transaction
from django.core.exceptions import ValidationError
from django.utils.crypto import get_random_string
from apps.Users.models import Profile
from django.db.models import Sum
from django.utils import timezone
from datetime import timedelta
from .models import RecyclingTransaction, RewardRedemption, Reward, Kiosk, UserBadge, Badge


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

        # 4. Get badges immediately after recycling
        GamificationService.check_and_award_badges(user)

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


class GamificationService:

    @staticmethod
    def get_all_time_leaderboard(limit=50):
        """Returns top users ordered by lifetime Total Points."""
        return Profile.objects.select_related('user').order_by('-total_points')[:limit]

    @staticmethod
    def get_weekly_leaderboard(limit=50):
        """Aggregates points earned only within the last 7 days."""
        one_week_ago = timezone.now() - timedelta(days=7)

        weekly_leaders = RecyclingTransaction.objects.filter(
            created_at__gte=one_week_ago
        ).values(
            'user__username', 'user__profile__rank'
        ).annotate(
            weekly_points=Sum('points_earned')
        ).order_by('-weekly_points')[:limit]

        return weekly_leaders

    @staticmethod
    def check_and_award_badges(user):
        """Evaluates user stats and awards missing badges."""
        profile = user.profile

        # Calculate aggregate stats from transaction history
        stats = RecyclingTransaction.objects.filter(user=user).aggregate(
            total_weight=Sum('weight_kg')
        )
        total_weight = stats['total_weight'] or 0
        total_trx = RecyclingTransaction.objects.filter(user=user).count()

        # Fetch badges the user DOES NOT have yet
        earned_badge_ids = UserBadge.objects.filter(user=user).values_list('badge_id', flat=True)
        available_badges = Badge.objects.exclude(id__in=earned_badge_ids)

        new_badges = []
        for badge in available_badges:
            earned = False
            if badge.metric == 'points' and profile.total_points >= badge.threshold:
                earned = True
            elif badge.metric == 'weight' and total_weight >= badge.threshold:
                earned = True
            elif badge.metric == 'transactions' and total_trx >= badge.threshold:
                earned = True

            if earned:
                UserBadge.objects.create(user=user, badge=badge)
                new_badges.append(badge)

                # TODO: Trigger Firebase Cloud Messaging (FCM) here
                # e.g., send_fcm_push(user, "Achievement Unlocked!", f"You earned the {badge.name} badge.")

        return new_badges