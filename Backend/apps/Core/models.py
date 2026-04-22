from django.db import models
from django.contrib.auth import get_user_model
import uuid

User = get_user_model()


class Partner(models.Model):
    """Partner businesses offering discounts."""
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    logo = models.ImageField(upload_to="partners/logos/", blank=True, null=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.name


class Reward(models.Model):
    """Specific discounts offered by partners."""
    partner = models.ForeignKey(Partner, related_name="rewards", on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    description = models.TextField()
    points_required = models.PositiveIntegerField()
    stock = models.PositiveIntegerField(default=100)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.title} - {self.points_required} pts"


class Kiosk(models.Model):
    """Smart Kiosk locations for the interactive map."""
    location_name = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    is_operational = models.BooleanField(default=True)

    def __str__(self):
        return self.location_name


class RecyclingTransaction(models.Model):
    """Records every time a user recycles at a kiosk."""
    transaction_id = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    user = models.ForeignKey(User, related_name="transactions", on_delete=models.CASCADE)
    kiosk = models.ForeignKey(Kiosk, on_delete=models.SET_NULL, null=True)
    weight_kg = models.DecimalField(max_digits=6, decimal_places=2)
    points_earned = models.PositiveIntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.points_earned} pts"


class RewardRedemption(models.Model):
    """Records when a user spends points on a reward."""
    redemption_code = models.CharField(max_length=12, unique=True)
    user = models.ForeignKey(User, related_name="redemptions", on_delete=models.CASCADE)
    reward = models.ForeignKey(Reward, on_delete=models.PROTECT)
    redeemed_at = models.DateTimeField(auto_now_add=True)
    is_used_at_partner = models.BooleanField(default=False)


class Badge(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    icon = models.ImageField(upload_to="badges/icons/", blank=True, null=True)
    metric = models.CharField(max_length=20, choices=[
        ('transactions', 'Number of Kiosk Visits'),
        ('weight', 'Total Weight (KG)'),
        ('points', 'Total Points Earned')
    ])
    threshold = models.IntegerField(help_text="Value required to unlock this badge")

    def __str__(self):
        return self.name


class UserBadge(models.Model):
    user = models.ForeignKey(User, related_name="user_badges", on_delete=models.CASCADE)
    badge = models.ForeignKey(Badge, on_delete=models.CASCADE)
    earned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'badge')

    def __str__(self):
        return f"{self.user.username} - {self.badge.name}"