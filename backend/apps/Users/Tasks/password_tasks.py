from django.shortcuts import get_object_or_404
from django.utils.crypto import get_random_string
from datetime import datetime, timedelta
from django.http import HttpRequest
from ..models import User
from django.core.mail import send_mail
from django.conf import settings
from django.contrib.auth.hashers import make_password
from rest_framework.status import HTTP_400_BAD_REQUEST, HTTP_200_OK
from .. import constant

current_site = constant.CURRENT_SITE


def get_current_host(request):
    protocol = request.is_secure() and "https" or "http"
    host = request.get_host()
    return "{protocol}://{host}/".format(protocol=protocol, host=host)


def forget_password(request: HttpRequest):
    email = request.data.get("email", None)
    if not email:
        return (
            {"message": "Email missing"},
            HTTP_400_BAD_REQUEST
        )

    user = get_object_or_404(User, email=email)
    token = get_random_string(40)
    expire_date = datetime.now() + timedelta(minutes=10)
    user.profile.reset_password_token = token
    user.profile.reset_password_expire = expire_date
    user.profile.save()

    link = f"{constant.rest_password_url}/{token}".format(token=token)
    body = "Your password reset link is : {link}".format(link=link)
    send_mail(
        f"Paswword reset from {current_site}",
        body,
        f"{settings.EMAIL_HOST_USER}",
        [email],
    )
    return (
        {"details": "Password reset sent to {email}".format(email=email)},
        HTTP_200_OK,
    )


def reset_password(request: HttpRequest, token: str):
    data = request.data
    if "password" not in data or "confirmPassword" not in data:
        return (
            {"error": "Password and confirm password missing"},
            HTTP_400_BAD_REQUEST,
        )
    try:
        user = User.objects.get(profile__reset_password_token=token)
    except User.DoesNotExist:
        return (
            {"error": "Invalid token"},
            HTTP_400_BAD_REQUEST
        )

    if user.profile.reset_password_expire.replace(tzinfo=None) < datetime.now():
        return (
            {"error": "Token is expired"},
            HTTP_400_BAD_REQUEST
        )

    if data["password"] != data["confirmPassword"]:
        return (
            {"error": "Password are not same"},
            HTTP_400_BAD_REQUEST
        )

    user.password = make_password(data["password"])
    user.profile.reset_password_token = ""
    user.profile.reset_password_expire = None
    user.profile.save()
    user.save()

    return (
        {"details": "Password reset done "},
        HTTP_200_OK
    )
