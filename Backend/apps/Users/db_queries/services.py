from ..models import User
from django.http import HttpRequest
from django.contrib.auth.hashers import make_password
from ..serializers import OutputSerializers


def Create_user(validated_data: dict, unique_username: str) -> User:
    user = User.objects.create_user(
        username=unique_username,
        email=validated_data["email"],
        password=validated_data["password"],
        first_name=validated_data["first_name"],
        last_name=validated_data["last_name"],
        accept_terms=validated_data["accept_terms"],
    )

    return user


def create_user_for_google_login(user_info: dict) -> User:
    user = User.objects.create(
        email=user_info.get("email"),
        username=user_info.get("email"),
        first_name=user_info.get("given_name"),
        last_name=user_info.get("family_name"),
        email_verified=True,
    )
    return user


def update_user_info(request: HttpRequest) -> dict:
    user = request.user
    data = request.data

    user.first_name = data.get(
        "first_name", user.first_name
    )  # get it from request or take the old one
    user.last_name = data.get("last_name", user.last_name)

    user.username = data.get("username", user.username)

    if "password" in data and data["password"] != "":
        user.password = make_password(data["password"])

    # Check if 'profile_picture' is present in the request data
    if "profile_picture" in request.data:
        user.profile_picture = request.data["profile_picture"]

    user.save()
    serializer = OutputSerializers.UserInfoSerializer(user, many=False)
    return serializer.data
