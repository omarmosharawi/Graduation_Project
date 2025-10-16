import requests
from django.conf import settings
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from urllib.parse import urlencode
from rest_framework_simplejwt.tokens import RefreshToken
from oauthlib.common import UNICODE_ASCII_CHARACTER_SET
from random import SystemRandom
from rest_framework.status import HTTP_200_OK, HTTP_400_BAD_REQUEST
from ..models import User
from django.core.files.uploadedfile import SimpleUploadedFile
from ..db_queries import services
import datetime


class GoogleRawLoginFlowService:
    GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
    GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
    GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v3/userinfo"

    def __init__(self):
        self.client_id = settings.GOOGLE_OAUTH2_CLIENT_ID
        self.client_secret = settings.GOOGLE_OAUTH2_CLIENT_SECRET

    @staticmethod
    def _generate_state_session_token(length=30, chars=UNICODE_ASCII_CHARACTER_SET):
        # implemented official SDK
        rand = SystemRandom()
        state = "".join(rand.choice(chars) for _ in range(length))
        return state

    def get_authorization_url(self):
        redirect_uri = settings.GOOGLE_OAUTH2_REDIRECT_URI
        scopes = "email profile"
        state = self._generate_state_session_token()

        params = {
            "response_type": "code",
            "client_id": self.client_id,
            "redirect_uri": redirect_uri,
            "scope": scopes,
            "state": state,
        }
        query_params = urlencode(params)
        authorization_url = f"{self.GOOGLE_AUTH_URL}?{query_params}"

        return authorization_url, state

    def get_access_token(self, code, redirect_uri):
        params = {
            "code": code,
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "redirect_uri": redirect_uri,
            "grant_type": "authorization_code",
        }
        response = requests.post(self.GOOGLE_TOKEN_URL, data=params)
        return response.json()

    def get_user_info(self, access_token):
        headers = {"Authorization": f"Bearer {access_token}"}
        response = requests.get(self.GOOGLE_USERINFO_URL, headers=headers)
        return response.json()

    def get_access_and_refresh_tokens(self, user):
        serializer = TokenObtainPairSerializer()
        token_data = serializer.get_token(user)
        access_token = token_data.access_token
        refresh_token = RefreshToken.for_user(user)
        return access_token, refresh_token


def google_login(request):
    service = GoogleRawLoginFlowService()
    code = request.GET.get("code")
    state = request.GET.get("state")
    session_state = request.session.get("google_oauth2_state")

    if code is None or state is None:
        return (
            {"error": "Code and state are required."},
            HTTP_400_BAD_REQUEST
        )
    if state != session_state:
        return (
            {"error": "Invalid state parameter."},
            HTTP_400_BAD_REQUEST
        )

    redirect_uri = settings.GOOGLE_OAUTH2_REDIRECT_URI
    credentials = service.get_access_token(code, redirect_uri)

    if "access_token" not in credentials:
        return (
            {"error": "Access token not found in ."},
            HTTP_400_BAD_REQUEST
        )

    access_token = credentials["access_token"]
    user_info = service.get_user_info(access_token)

    email = user_info.get("email")
    if not email:
        return (
            {"error": "Email not found in user info."},
            HTTP_400_BAD_REQUEST
        )
    # if not found user crete new user
    users_with_email = User.objects.filter(email=email)

    if not users_with_email.exists():
        profile_picture_url = user_info.get("picture")
        if profile_picture_url:
            response = requests.get(profile_picture_url)
            if response.status_code == 200:
                # upload image from google
                profile_picture = SimpleUploadedFile(
                    name="profile_picture.jpg",
                    content=response.content,
                    content_type="image/jpeg",
                )
                user = User.objects.create(
                    email=user_info.get("email"),
                    username=user_info.get("email"),
                    first_name=user_info.get("given_name"),
                    last_name=user_info.get("family_name"),
                    email_verified=True,
                    profile_picture=profile_picture,
                )
                access_token, refresh_token = service.get_access_and_refresh_tokens(
                    user
                )
                response_data = {
                    "message": "User created successfully.",
                    "access_token": str(access_token),
                    "refresh_token": str(refresh_token),
                }

        else:
            user = services.create_user_for_google_login(user_info)
            access_token, refresh_token = service.get_access_and_refresh_tokens(user)
            response_data = {
                "message": "User created successfully.",
                "access_token": str(access_token),
                "refresh_token": str(refresh_token),
            }

    user = users_with_email.first()
    access_token, refresh_token = service.get_access_and_refresh_tokens(user)
    response_data = {
        "access_token": str(access_token),
        "refresh_token": str(refresh_token),
    }

    user.last_login = datetime.now()
    user.save()

    return response_data, HTTP_200_OK
