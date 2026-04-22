from rest_framework.status import HTTP_200_OK, HTTP_400_BAD_REQUEST, HTTP_201_CREATED, HTTP_404_NOT_FOUND
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework import viewsets, status, generics
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import action
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import redirect
from django.utils import timezone
from .models import User, Profile
from .serializers import InputSerializers
from .permissions import IsAdminOrPostOnly
from .Tasks import Auth_tasks, password_tasks, google_auth_tasks
from .db_queries import selectors, services
from firebase_admin import auth as firebase_auth
from django.utils.crypto import get_random_string
from .serializers.InputSerializers import GoogleAuthSerializer


# New Logic

class SignUPViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = InputSerializers.SignUpSerializer
    permission_classes = [IsAdminOrPostOnly]
    lookup_field = "uuid"

    def create(self, request):
        serializer = self.serializer_class(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            token_data = Auth_tasks.send_otp_to_user_email(user)
            # Optional: Send SMS if phone is provided
            # Auth_tasks.send_otp_to_user_phone(user)
            return Response(
                {"user": serializer.data, "tokens": token_data}, status=HTTP_201_CREATED
            )
        return Response(serializer.errors, status=HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=["post"])
    def confirm_email(self, request):
        response_data, response_status = Auth_tasks.confirm_email_using_otp(request)
        return Response(response_data, status=response_status)

    @action(detail=False, methods=["post"])
    def confirm_phone(self, request):
        response_data, response_status = Auth_tasks.confirm_phone_using_otp(request)
        return Response(response_data, status=response_status)

    @action(detail=False, methods=["post"])
    def send_reset_otp(self, request):
        email = request.data.get("email")
        if not email:
            return Response({"detail": "Missing email."}, status=HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(email=email)
            # Rate limiting logic
            if user.otp_created_at:
                time_since_last_otp = timezone.now() - user.otp_created_at
                if time_since_last_otp.total_seconds() < 60:
                    remaining = int(60 - time_since_last_otp.total_seconds())
                    return Response(
                        {"detail": f"Please wait {remaining} seconds before requesting a new OTP."},
                        status=HTTP_400_BAD_REQUEST,
                    )

            # Reset attempts on new request
            user.otp_attempts = 0
            user.save()

            response_data, response_status = Auth_tasks.send_reset_otp(request)
            return Response(response_data, status=response_status)
        except User.DoesNotExist:
            return Response({"detail": "User not found."}, status=HTTP_404_NOT_FOUND)


class LoginView(TokenObtainPairView):
    def post(self, request, *args, **kwargs):
        # Renamed function call
        response_data, response_status = Auth_tasks.login_user(request)
        return Response(response_data, response_status)


# Old Logic

# class SignUPViewSet(viewsets.ModelViewSet):
#     queryset = User.objects.all()
#     serializer_class = InputSerializers.SignUpSerializer
#     permission_classes = [IsAdminOrPostOnly]
#     lookup_field = "uuid"
#
#     def create(self, request):
#         serializer = self.serializer_class(data=request.data)
#         if serializer.is_valid():
#             user = serializer.save()
#             token_data = Auth_tasks.send_otp_to_user_email(user)
#             Auth_tasks.send_otp_to_user_phone(user)
#             return Response(
#                 {"user": serializer.data, "tokens": token_data}, status=HTTP_201_CREATED
#             )
#         return Response(serializer.errors, status=HTTP_400_BAD_REQUEST)
#
#     @action(detail=False, methods=["post"])
#     def confirm_email(self, request):
#         Response_data, Response_status = Auth_tasks.confirm_email_using_otp(request)
#         return Response(Response_data, status=Response_status)
#
#     @action(detail=False, methods=["post"])
#     def confirm_phone(self, request):
#         Response_data, Response_status = Auth_tasks.confirm_phone_using_otp(request)
#         return Response(Response_data, status=Response_status)
#
#     @action(detail=False, methods=["post"])
#     def send_reset_otp(self, request):
#         email = request.data.get("email")
#         if not email:
#             return Response({"detail": "Missing email."}, status=HTTP_400_BAD_REQUEST)
#
#         try:
#             user = User.objects.get(email=email)
#
#             if user.otp_created_at:
#                 time_since_last_otp = timezone.now() - user.otp_created_at
#                 if time_since_last_otp.total_seconds() < 60:
#                     remaining_time = int(60 - time_since_last_otp.total_seconds())
#                     return Response(
#                         {"detail": f"Please wait {remaining_time} seconds before requesting a new OTP."},
#                         status=HTTP_400_BAD_REQUEST,
#                     )
#
#             user.otp_attempts = 0
#             user.save()
#
#             Response_data, Response_status = Auth_tasks.send_reset_otp(request)
#             return Response(Response_data, status=Response_status)
#         except User.DoesNotExist:
#             return Response({"detail": "User not found."}, status=HTTP_404_NOT_FOUND)
#
#         # Response_data, Response_status = Auth_tasks.send_reset_otp(request)
#         # return Response(Response_data, status=Response_status)
#
#
# class LoginView(TokenObtainPairView):
#     def post(self, request, *args, **kwargs):
#         Response_data, Response_status = Auth_tasks.Login(request)
#         return Response(Response_data, Response_status)


class UserInfo(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)

    def get(self, request):
        Response_data = selectors.get_user_info(request)
        return Response(
            {"status": "success", "data": Response_data}, status=HTTP_200_OK
        )

    def put(self, request):
        Response_data = services.update_user_info(request)
        return Response(Response_data, HTTP_200_OK)


class ForgetPasswordView(APIView):
    def post(self, request):
        Response_data, Response_status = password_tasks.forget_password(request)
        return Response(Response_data, status=Response_status)


class ResetPasswordView(APIView):
    def post(self, request, token):
        Response_data, Response_status = password_tasks.reset_password(request, token)
        return Response(Response_data, status=Response_status)


class PublicApi(APIView):
    authentication_classes = ()
    permission_classes = ()


class GoogleLoginRedirectView(PublicApi):
    def get(self, request, *args, **kwargs):
        google_login_flow = google_auth_tasks.GoogleRawLoginFlowService()

        authorization_url, state = google_login_flow.get_authorization_url()

        request.session["google_oauth2_state"] = state

        # redirect to authorization_url
        return redirect(authorization_url)


class GoogleLoginCallbackView(PublicApi):
    def get(self, request, *args, **kwargs):
        Response_data, Response_status = google_auth_tasks.google_login(request)
        return Response(Response_data, status=Response_status)


class APILogoutView(APIView):
    permission_classes = (IsAuthenticated,)

    def post(self, request, *args, **kwargs):
        response_data = Auth_tasks.logout_user(self, request, *args, **kwargs)
        return Response(response_data, status=HTTP_200_OK)


class UpdateFCMTokenView(APIView):
    """Allows the mobile app to register the device for push notifications."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        token = request.data.get('fcm_token')
        if not token:
            return Response({"error": "fcm_token is required"}, status=HTTP_400_BAD_REQUEST)

        profile = request.user.profile
        profile.fcm_token = token
        profile.save(update_fields=['fcm_token'])

        return Response({"status": "Device registered for notifications"}, status=HTTP_200_OK)


class ApplyReferralCodeView(APIView):
    """System where users invite friends for bonus points."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        invite_code = request.data.get('invite_code')
        profile = request.user.profile

        if profile.referred_by:
            return Response({"error": "You have already used a referral code."}, status=status.HTTP_400_BAD_REQUEST)

        if profile.invite_code == invite_code:
            return Response({"error": "You cannot use your own code."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            referrer_profile = Profile.objects.get(invite_code=invite_code)

            # Link them
            profile.referred_by = referrer_profile

            # Grant Bonus Points (e.g., 100 points each)
            profile.current_points += 100
            profile.total_points += 100
            profile.save(update_fields=['referred_by', 'current_points', 'total_points'])

            referrer_profile.current_points += 100
            referrer_profile.total_points += 100
            referrer_profile.save(update_fields=['current_points', 'total_points'])

            return Response({"message": "Referral successful! 100 bonus points added."}, status=status.HTTP_200_OK)

        except Profile.DoesNotExist:
            return Response({"error": "Invalid referral code."}, status=status.HTTP_404_NOT_FOUND)


class FirebaseGoogleAuthView(generics.GenericAPIView):
    """
    Handles both Login and Registration via Google Firebase.
    Mobile app sends the Firebase ID token. Backend verifies it and issues SimpleJWTs.
    """
    permission_classes = (AllowAny,)
    serializer_class = GoogleAuthSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        id_token = serializer.validated_data['id_token']

        try:
            # 1. Verify the token with Google/Firebase servers
            decoded_token = firebase_auth.verify_id_token(id_token)

            # 2. Extract user data from the verified token
            email = decoded_token.get('email')
            name = decoded_token.get('name', '')
            picture = decoded_token.get('picture', '')

            if not email:
                return Response({"error": "Google account must have an email address associated."},
                                status=status.HTTP_400_BAD_REQUEST)

            # Split name into first and last
            name_parts = name.split(' ', 1)
            first_name = name_parts[0] if len(name_parts) > 0 else ''
            last_name = name_parts[1] if len(name_parts) > 1 else ''

            # 3. Check if user already exists
            user = User.objects.filter(email=email).first()

            if not user:
                # REGISTER FLOW: Create a new user instantly
                # Generate a safe, unique username from the email
                base_username = email.split('@')[0]
                username = base_username
                while User.objects.filter(username=username).exists():
                    username = f"{base_username}{get_random_string(4)}"

                user = User.objects.create(
                    username=username,
                    email=email,
                    first_name=first_name,
                    last_name=last_name,
                    email_verified=True,  # Pre-verified by Google!
                )
                # Users logging in with Google shouldn't use a standard password
                user.set_unusable_password()
                user.save()

                # If you have a signal that creates the Profile automatically, great.
                # If not, ensure the Profile is created here:
                # Profile.objects.get_or_create(user=user)

                message = "Registration successful via Google."
                status_code = status.HTTP_201_CREATED
            else:
                # LOGIN FLOW: User exists, just log them in
                message = "Login successful via Google."
                status_code = status.HTTP_200_OK

            # 4. Generate Django SimpleJWT Tokens
            refresh = RefreshToken.for_user(user)

            return Response({
                "message": message,
                "tokens": {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                },
                "user": {
                    "id": user.id,
                    "email": user.email,
                    "username": user.username,
                    "first_name": user.first_name,
                    "last_name": user.last_name,
                    "rank": user.profile.rank,  # Assuming Profile relationship
                    "current_points": user.profile.current_points
                }
            }, status=status_code)

        except firebase_auth.InvalidIdTokenError:
            return Response({"error": "Invalid Google Firebase ID token."}, status=status.HTTP_401_UNAUTHORIZED)
        except firebase_auth.ExpiredIdTokenError:
            return Response({"error": "Google Firebase ID token has expired."}, status=status.HTTP_401_UNAUTHORIZED)
        except Exception as e:
            return Response({"error": f"Authentication failed: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)