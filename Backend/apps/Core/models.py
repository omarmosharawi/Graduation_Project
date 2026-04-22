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
    name = models.CharField(max_length=255, default="Standard Kiosk", help_text="Specific name or ID of the Kiosk.")
    location_name = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    is_operational = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.name} - {self.location_name}"


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


class CustomNotification(models.Model):
    TARGET_CHOICES = (
        ('ALL', 'All Users'),
        ('SPECIFIC', 'Specific Users'),
    )

    title = models.CharField(max_length=255, help_text="The main heading of the push notification.")
    body = models.TextField(help_text="The main text content of the notification.")
    target = models.CharField(max_length=15, choices=TARGET_CHOICES, default='ALL')
    specific_users = models.ManyToManyField(
        User,
        blank=True,
        help_text="Select users here if 'Specific Users' is chosen above."
    )

    created_at = models.DateTimeField(auto_now_add=True)
    is_sent = models.BooleanField(default=False, help_text="Indicates if the Celery task has processed this.")

    def __str__(self):
        return f"{self.title} - {self.get_target_display()}"


class DelegateRequest(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending (Awaiting Assignment)'),
        ('ASSIGNED', 'Assigned to Delegate'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
    )

    MATERIAL_CHOICES = (
        ('PLASTIC', 'Plastic Bottles/Containers'),
        ('GLASS', 'Glass Bottles/Jars'),
        ('PAPER', 'Paper/Cardboard'),
        ('CANS', 'Aluminum/Metal Cans'),
        ('MIXED', 'Mixed Recyclables'),
    )

    user = models.ForeignKey(User, related_name='delegate_requests', on_delete=models.CASCADE)
    pickup_address = models.TextField(help_text="Full address or descriptive location details.")
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

    scheduled_date = models.DateField()
    scheduled_time = models.TimeField()

    material_type = models.CharField(max_length=20, choices=MATERIAL_CHOICES, default='MIXED')
    material_count = models.PositiveIntegerField(default=1, help_text="Number of bags or boxes.")

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    estimated_arrival_time = models.DateTimeField(null=True, blank=True)
    cost_in_points = models.IntegerField(default=50, help_text="Points deducted for this premium service.")

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Pickup for {self.user.username} on {self.scheduled_date} ({self.material_count}x {self.get_material_type_display()})"