from ..models import User
from ..serializers import OutputSerializers
from .. import constant
from django.http import HttpRequest
from random import randint
from django.utils import timezone
from rest_framework.status import (
    HTTP_400_BAD_REQUEST,
    HTTP_200_OK,
    HTTP_404_NOT_FOUND,
    HTTP_403_FORBIDDEN,
    HTTP_401_UNAUTHORIZED,
)
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import login as django_login, logout
from rest_framework_simplejwt.token_blacklist.models import (
    OutstandingToken,
    BlacklistedToken,
)


current_site = constant.CURRENT_SITE


# New Logic

# def generate_otp() -> str:
#     """Generates a 6-digit OTP string."""
#     return str(randint(100000, 999999))
#
#
# def get_tokens_for_user(user):
#     refresh = RefreshToken.for_user(user)
#     return {
#         "refresh": str(refresh),
#         "access": str(refresh.access_token),
#     }
#
#
# def send_otp_to_user_email(user: User) -> dict:
#     otp = generate_otp()
#     user.otp = otp
#     user.otp_created_at = timezone.now()
#     user.save()
#
#     subject = f"Your verification OTP on {current_site}"
#     message = f"Your verification OTP is: {otp}"
#
#     # Recommendation: Move this to a Celery task for performance
#     user.email_user(subject, message)
#
#     return get_tokens_for_user(user)
#
#
# def send_otp_to_user_phone(user: User) -> dict:
#     otp = generate_otp()
#     user.otp = otp
#     user.otp_created_at = timezone.now()
#     user.save()
#
#     # TODO: Add SMS sending logic here (e.g., Twilio)
#
#     return get_tokens_for_user(user)
#
#
# def is_otp_valid(otp_created_at):
#     if otp_created_at:
#         expiration_time = otp_created_at + timezone.timedelta(minutes=5)
#         return timezone.now() <= expiration_time
#     return False
#
#
# def confirm_email_using_otp(request: HttpRequest):
#     user_uuid = request.data.get("user_uuid")
#     otp_input = request.data.get("otp")
#
#     if not user_uuid or not otp_input:
#         return {"detail": "Missing user UUID or OTP."}, HTTP_400_BAD_REQUEST
#
#     try:
#         user = User.objects.get(uuid=user_uuid)
#
#         if user.email_verified:
#             return {"detail": "Email already confirmed."}, HTTP_400_BAD_REQUEST
#
#         if user.otp_attempts >= 3:
#             return {"detail": "Too many failed attempts. Please request a new OTP."}, HTTP_400_BAD_REQUEST
#
#         # Check OTP match and Expiration
#         if str(user.otp) == str(otp_input) and is_otp_valid(user.otp_created_at):
#             user.email_verified = True
#             user.otp_attempts = 0
#             user.otp = None  # Clear OTP after successful use
#             user.save()
#             return {"detail": "Email confirmed successfully."}, HTTP_200_OK
#         else:
#             user.otp_attempts += 1
#             user.save()
#             return {"detail": "Invalid or expired OTP."}, HTTP_400_BAD_REQUEST
#
#     except User.DoesNotExist:
#         return {"detail": "User not found."}, HTTP_404_NOT_FOUND
#
#
# def confirm_phone_using_otp(request: HttpRequest):
#     user_uuid = request.data.get("user_uuid")
#     otp_input = request.data.get("otp")
#
#     if not user_uuid or not otp_input:
#         return {"detail": "Missing user UUID or OTP."}, HTTP_400_BAD_REQUEST
#
#     try:
#         user = User.objects.get(uuid=user_uuid)
#
#         if user.phone_verified:
#             return {"detail": "Phone already confirmed."}, HTTP_400_BAD_REQUEST
#
#         if str(user.otp) == str(otp_input) and is_otp_valid(user.otp_created_at):
#             user.phone_verified = True
#             user.otp = None
#             user.save()
#             return {"detail": "Phone confirmed successfully."}, HTTP_200_OK
#         else:
#             return {"detail": "Invalid or expired OTP."}, HTTP_400_BAD_REQUEST
#
#     except User.DoesNotExist:
#         return {"detail": "User not found."}, HTTP_404_NOT_FOUND
#
#
# def send_reset_otp(request: HttpRequest):
#     email = request.data.get("email")
#     if not email:
#         return {"detail": "Missing email."}, HTTP_400_BAD_REQUEST
#
#     try:
#         user = User.objects.get(email=email)
#         otp = generate_otp()
#         user.otp = otp
#         user.otp_created_at = timezone.now()  # Important to set creation time
#         user.save()
#
#         subject = f"Your reset OTP on {current_site}"
#         message = f"Your reset OTP is: {otp}"
#         user.email_user(subject, message)
#
#         return {"detail": "Reset OTP sent successfully."}, HTTP_200_OK
#     except User.DoesNotExist:
#         return {"detail": "User not found."}, HTTP_404_NOT_FOUND
#
#
# def login_user(request: HttpRequest):
#     email = request.data.get("email")
#     password = request.data.get("password")
#
#     if not email or not password:
#         return {"message": "Email or Password missing"}, HTTP_400_BAD_REQUEST
#
#     # Use Django's authenticate for proper security checks (hashing, active status, etc.)
#     # Note: Requires an Authentication Backend that supports email or a custom one
#     # If standard auth only supports username, we manually fetch first.
#
#     try:
#         user = User.objects.get(email=email)
#     except User.DoesNotExist:
#         return {"message": "Email not found"}, HTTP_401_UNAUTHORIZED
#
#     # Authenticate checks password and is_active automatically if using standard flow
#     # Since we are looking up by email, we manually check:
#     if user.check_password(password):
#         if not user.is_active:
#             return {"message": "Your account has been deactivated"}, HTTP_403_FORBIDDEN
#
#         if not user.email_verified:
#             return {"user_id": user.uuid, "message": "Please activate email"}, HTTP_403_FORBIDDEN
#
#         # Optional: Keep session login if you use session-based auth alongside JWT
#         # django_login(request, user)
#
#         tokens = get_tokens_for_user(user)
#         return {
#             "user": OutputSerializers.LoginUserSerializer(user).data,
#             "tokens": tokens
#         }, HTTP_200_OK
#
#     return {"message": "Invalid credentials"}, HTTP_401_UNAUTHORIZED
#
#
# def logout_user(self, request, *args, **kwargs):
#     if self.request.data.get("all"):
#         for token in OutstandingToken.objects.filter(user=request.user):
#             _, _ = BlacklistedToken.objects.get_or_create(token=token)
#         return {"status": "OK, all tokens blacklisted"}
#
#     refresh_token = self.request.data.get("refresh_token")
#     if refresh_token:
#         try:
#             token = RefreshToken(token=refresh_token)
#             token.blacklist()
#         except Exception:
#             pass  # Token might already be invalid
#
#     logout(request)
#     return {"status": "OK, goodbye"}


# Old Logic

def send_otp_to_user_email(user: User) -> dict:
    # Generate a 4-digit OTP and store it in the user's profile
    otp = randint(100000, 999999)
    user.otp = otp
    user.otp_created_at = timezone.now()
    user.save()

    subject = "Your verification OTP on {0}".format(current_site)
    message = f"Your verification OTP is: {otp}"
    user.email_user(subject, message)

    refresh = RefreshToken.for_user(user)
    token_data = {
        "refresh": str(refresh),
        "access": str(refresh.access_token),
    }

    return token_data


def send_otp_to_user_phone(user: User) -> dict:
    # Generate a 4-digit OTP and store it in the user's profile
    otp = randint(100000, 999999)
    user.otp = otp
    user.otp_created_at = timezone.now()
    user.save()

    # Here add SMS sending logic

    # For now, we will just return the tokens
    refresh = RefreshToken.for_user(user)
    token_data = {
        "refresh": str(refresh),
        "access": str(refresh.access_token),
    }
    return token_data


def is_otp_valid(otp_created_at: timezone.datetime):
    if otp_created_at:
        expiration_time = otp_created_at + timezone.timedelta(minutes=5)
        return timezone.now() <= expiration_time
    else:
        return False


def confirm_email_using_otp(request: HttpRequest):
    user_uuid = request.data.get("user_uuid")
    otp = request.data.get("otp")

    if not user_uuid or not otp:
        return (
            {"detail": "Missing user UUID or OTP."},
            HTTP_400_BAD_REQUEST
        )
    try:
        user = User.objects.get(uuid=user_uuid)
        if user.email_verified:
            return (
                {"detail": "Email already confirmed."},
                HTTP_400_BAD_REQUEST
            )

        if user.otp_attempts >= 3:
            return (
                {"detail": "Too many failed attempts. Please request a new OTP."},
                HTTP_400_BAD_REQUEST,
            )

        if user.otp == int(otp) and is_otp_valid(user.otp_created_at):
            user.email_verified = True
            user.otp_attempts = 0
            user.save()
            return (
                {"detail": "Email confirmed successfully."},
                HTTP_200_OK
            )
        else:
            user.otp_attempts += 1
            user.save()
            return (
                {"detail": "Invalid OTP."},
                HTTP_400_BAD_REQUEST,
            )
    except User.DoesNotExist:
        return (
            {"detail": "User not found."},
            HTTP_404_NOT_FOUND
        )
    except ValueError:
        return (
            {"detail": "Invalid user ID."},
            HTTP_400_BAD_REQUEST
        )


def confirm_phone_using_otp(request: HttpRequest):
    user_uuid = request.data.get("user_uuid")
    otp = request.data.get("otp")
    if not user_uuid or not otp:
        return (
            {"detail": "Missing user UUID or OTP."},
            HTTP_400_BAD_REQUEST
        )
    try:
        user = User.objects.get(uuid=user_uuid)
        if user.phone_verified:
            return (
                {"detail": "Phone already confirmed."},
                HTTP_400_BAD_REQUEST
            )
        if user.otp == int(otp) and is_otp_valid(user.otp_created_at):
            user.phone_verified = True
            user.save()
            return (
                {"detail": "Phone confirmed successfully."},
                HTTP_200_OK
            )
        else:
            return (
                {"detail": "Unable to verify your phone with provided OTP."},
                HTTP_400_BAD_REQUEST,
            )
    except User.DoesNotExist:
        return (
            {"detail": "User not found."},
            HTTP_404_NOT_FOUND
        )
    except ValueError:
        return (
            {"detail": "Invalid user ID."},
            HTTP_400_BAD_REQUEST
        )


def send_reset_otp(request: HttpRequest):
    email = request.data.get("email")
    if not email:
        return (
            {"detail": "Missing email."},
            HTTP_400_BAD_REQUEST
        )
    try:
        user = User.objects.get(email=email)
        otp = randint(100000, 999999)
        user.otp = otp
        user.save()

        subject = "Your reset OTP on {0}".format(current_site)
        message = f"Your reset OTP is: {otp}"
        user.email_user(subject, message)

        return (
            {"detail": "Reset OTP sent successfully."},
            HTTP_200_OK
        )
    except User.DoesNotExist:
        return (
            {"detail": "User not found."},
            HTTP_404_NOT_FOUND
        )


def Login(request: HttpRequest):
    email = request.data.get("email")
    password = request.data.get("password")
    print(email, password)
    if not email or not password:
        return (
            {"message": "Email or Password missing"},
            HTTP_400_BAD_REQUEST
        )
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        user = None

    if user is not None and user.check_password(password):
        if not user.is_active:
            return (
                {"message": "Your account has been deactivated"},
                HTTP_403_FORBIDDEN,
            )

        if not user.email_verified:
            return (
                {"user_id": user.uuid, "message": "Please activate email"},
                HTTP_403_FORBIDDEN,
            )

        refresh = RefreshToken.for_user(user)
        data = {
            "refresh": str(refresh),
            "access": str(refresh.access_token),
        }

        django_login(request, user, backend="django.contrib.auth.backends.ModelBackend")

        return (
            {"user": OutputSerializers.LoginUserSerializer(user).data, "tokens": data},
            HTTP_200_OK,
        )
    # check if email not exist
    elif user is None:
        return (
            {"message": "Email not found"},
            HTTP_401_UNAUTHORIZED
        )

    else:
        return (
            {"message": "Email or Password Error"},
            HTTP_401_UNAUTHORIZED
        )


def Logout(self, request, *args, **kwargs):
    if self.request.data.get("all"):
        token: OutstandingToken
        for token in OutstandingToken.objects.filter(user=request.user):
            _, _ = BlacklistedToken.objects.get_or_create(token=token)
        return {"status": "OK, goodbye, all refresh tokens blacklisted"}

    refresh_token = self.request.data.get("refresh_token")
    token = RefreshToken(token=refresh_token)
    token.blacklist()
    logout(request)

    return {"status": "OK, goodbye"}
