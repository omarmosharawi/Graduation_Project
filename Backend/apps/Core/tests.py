from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework import status
from django.core.files.uploadedfile import SimpleUploadedFile
from datetime import timedelta

from apps.Users.models import User
from .models import Coupon, CouponRedemption, DelegateRequest, RecyclingTransaction


# ==============================================================================
# 1. UNIT TESTS: Testing isolated logic (Fast, no API calls)
# ==============================================================================
class CouponModelUnitTests(TestCase):
    def setUp(self):
        # Arrange: Setup initial data
        self.valid_coupon = Coupon.objects.create(
            code="VALID100", reward_points=100, is_active=True
        )
        self.expired_coupon = Coupon.objects.create(
            code="EXPIRED", reward_points=100, is_active=True,
            valid_to=timezone.now() - timedelta(days=1)
        )
        self.max_uses_coupon = Coupon.objects.create(
            code="MAXED", reward_points=100, is_active=True,
            max_uses=1, current_uses=1
        )

    def test_coupon_is_valid(self):
        # Act
        is_valid, msg = self.valid_coupon.is_valid()
        # Assert
        self.assertTrue(is_valid)
        self.assertEqual(msg, "Valid")

    def test_coupon_is_expired(self):
        is_valid, msg = self.expired_coupon.is_valid()
        self.assertFalse(is_valid)
        self.assertEqual(msg, "This coupon has expired.")

    def test_coupon_reached_max_uses(self):
        is_valid, msg = self.max_uses_coupon.is_valid()
        self.assertFalse(is_valid)
        self.assertEqual(msg, "This coupon has reached its usage limit.")


# ==============================================================================
# 2. INTEGRATION TESTS: Testing APIs and Database interactions
# ==============================================================================
class CouponAPIIntegrationTests(APITestCase):
    def setUp(self):
        # Arrange: Create a user and authenticate them
        self.user = User.objects.create_user(username="testuser", email="test@test.com", password="password123")
        self.client.force_authenticate(user=self.user)

        # Create a valid coupon
        self.coupon = Coupon.objects.create(code="WELCOME500", reward_points=500, is_active=True)
        self.url = '/en/api/v1/core/coupons/redeem/'  # Ensure this matches your urls.py path

    def test_successful_coupon_redemption(self):
        # Act: User hits the API endpoint
        response = self.client.post(self.url, {"code": "WELCOME500"})

        # Assert: Check HTTP Status
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Assert: Check the database changed correctly
        self.user.profile.refresh_from_db()
        self.assertEqual(self.user.profile.current_points, 500)
        self.assertEqual(CouponRedemption.objects.count(), 1)

    def test_prevent_double_dipping(self):
        # Act: User redeems coupon successfully
        self.client.post(self.url, {"code": "WELCOME500"})

        # Act: User tries to redeem the EXACT same coupon again
        response = self.client.post(self.url, {"code": "WELCOME500"})

        # Assert: Blocked!
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("already used", response.data['error'])


# ==============================================================================
# 3. ACCEPTANCE TESTS: End-to-End Business Scenario
# ==============================================================================
class DelegateLogisticsAcceptanceTest(APITestCase):
    def setUp(self):
        # 1. We need a standard User
        self.user = User.objects.create_user(username="homeowner", email="home@test.com", password="pass")

        # 2. We need a Delegate (Driver)
        self.driver = User.objects.create_user(username="driver1", email="driver@test.com", password="pass")

        # 3. The homeowner creates a pickup request in the database
        self.pickup = DelegateRequest.objects.create(
            user=self.user,
            pickup_address="123 Cairo St",
            scheduled_date=timezone.now().date(),
            scheduled_time=timezone.now().time(),
            material_type="PLASTIC",
            status="PENDING"
        )

    def test_full_delegate_pickup_lifecycle(self):
        """
        SCENARIO:
        A driver logs in, accepts the pending pickup, drives to the house,
        weighs the bag (5.5kg), uploads a photo, and the user gets their points.
        """

        # ACTOR: Driver logs into their app
        self.client.force_authenticate(user=self.driver)

        # 1. Driver Accepts the Job
        accept_url = '/en/api/v1/core/delegates/jobs/accept/'
        accept_res = self.client.post(accept_url, {"request_id": self.pickup.id})
        self.assertEqual(accept_res.status_code, status.HTTP_200_OK)

        # Verify database locked it
        self.pickup.refresh_from_db()
        self.assertEqual(self.pickup.status, "ACCEPTED")

        # 2. Driver Completes the Job
        # We simulate a photo upload
        # dummy_image = SimpleUploadedFile(name='test_image.jpg', content=b'', content_type='image/jpeg')

        complete_url = '/en/api/v1/core/delegates/jobs/complete/'
        complete_res = self.client.post(complete_url, {
            "request_id": self.pickup.id,
            "actual_weight_kg": "5.50",
            "material_type": "PLASTIC",
            # "proof_image": dummy_image
        }, format='multipart')

        # Verify API Success
        self.assertEqual(complete_res.status_code, status.HTTP_200_OK)

        # 3. VERIFY FINAL BUSINESS OUTCOMES
        self.pickup.refresh_from_db()
        self.user.profile.refresh_from_db()

        # Did the request status update to COMPLETED?
        self.assertEqual(self.pickup.status, "COMPLETED")

        # Did it save the weight correctly?
        self.assertEqual(float(self.pickup.actual_weight_kg), 5.50)

        # Did the system generate a digital receipt (Transaction)?
        self.assertEqual(RecyclingTransaction.objects.count(), 1)

        # Did the homeowner actually get the correct points? (5.5kg * 10 = 55 points)
        self.assertEqual(self.user.profile.current_points, 55)