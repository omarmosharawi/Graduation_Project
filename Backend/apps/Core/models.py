from django.db import models
from django.contrib.auth import get_user_model
import uuid

User = get_user_model()


class PartnerCategory(models.Model):
    """Partner businesses categories."""
    name = models.CharField(max_length=100, unique=True, help_text="e.g., Coffee, Healthcare, Beauty")
    icon = models.ImageField(upload_to="categories/icons/", blank=True, null=True, help_text="Small icon for the mobile app UI.")

    class Meta:
        verbose_name_plural = "Partner Categories"

    def __str__(self):
        return self.name


class Partner(models.Model):
    """Partner businesses offering discounts."""
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    logo = models.ImageField(upload_to="partners/logos/", blank=True, null=True)
    is_active = models.BooleanField(default=True)
    category = models.ForeignKey(PartnerCategory, on_delete=models.SET_NULL, null=True, related_name='partners',
                                 help_text="Industry or type of partner.")

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
    STATUS_CHOICES = (
        ('online', 'Online / Active'),
        ('offline', 'Offline'),
        ('maintenance', 'Under Maintenance'),
        ('full', 'Full Capacity'),
    )

    name = models.CharField(max_length=255, unique=True, help_text="Specific unique name or ID of the Kiosk.")
    address = models.CharField(max_length=255, default='Unknown', help_text="Full address")

    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)

    # Capacity & Hardware Tracking
    current_capacity = models.PositiveIntegerField(default=0)
    max_capacity = models.PositiveIntegerField(default=100)
    plastic_count = models.PositiveIntegerField(default=0)
    metal_count = models.PositiveIntegerField(default=0)

    # Operational Details
    opening_hours = models.CharField(max_length=100, default="9:00 AM - 9:00 PM")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='offline')
    last_updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} - {self.get_status_display()} ({self.current_capacity}/{self.max_capacity})"


class RecyclingTransaction(models.Model):
    """Records every time a user recycles at a kiosk."""
    MATERIAL_CHOICES = (
        ('PLASTIC', 'Plastic Bottles/Containers'),
        ('GLASS', 'Glass Bottles/Jars'),
        ('PAPER', 'Paper/Cardboard'),
        ('CANS', 'Aluminum/Metal Cans'),
        ('MIXED', 'Mixed Recyclables'),
    )
    transaction_id = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    user = models.ForeignKey(User, related_name="transactions", on_delete=models.CASCADE)
    kiosk = models.ForeignKey(Kiosk, on_delete=models.SET_NULL, null=True)
    material_type = models.CharField(max_length=20, choices=MATERIAL_CHOICES, default='MIXED')
    material_count = models.PositiveIntegerField(default=1, help_text="Number of items recycled.")
    weight_kg = models.DecimalField(max_digits=6, decimal_places=2)
    points_earned = models.PositiveIntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.material_count} x {self.get_material_type_display()} ({self.points_earned} pts)"


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


class HomeCard(models.Model):
    CARD_TYPES = (
        ('ANNOUNCEMENT', 'Announcement'),
        ('DEAL', 'Hot Deal'),
        ('OFFER', 'New Offer'),
    )

    title = models.CharField(max_length=255)
    description = models.TextField()
    image = models.ImageField(upload_to="home_cards/", help_text="High-quality image for the mobile banner.")

    # Actions
    reference_url = models.URLField(blank=True, null=True, help_text="External link or deep link to an offer.")
    coupon_code = models.CharField(max_length=50, blank=True, null=True,
                                   help_text="Code users can copy for bonus points.")

    # Display Rules
    card_type = models.CharField(max_length=20, choices=CARD_TYPES, default='ANNOUNCEMENT')
    priority = models.PositiveIntegerField(default=1,
                                           help_text="Lower number = shows up first (e.g., 1 is top priority).")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['priority', '-created_at']  # Automatically sorts by priority first

    def __str__(self):
        return f"{self.get_card_type_display()} - {self.title}"


# A "Dummy" Model purely to attach our Admin Dashboard to
class CommunityImpact(RecyclingTransaction):
    class Meta:
        # managed = False # Django won't try to create a database table for this
        proxy = True  # This is the magic keyword
        verbose_name = 'Community Impact Dashboard'
        verbose_name_plural = 'Community Impact Dashboard'