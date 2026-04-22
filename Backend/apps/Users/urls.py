from django.urls import path, include
from . import views
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

router = DefaultRouter()
router.register(r"SignUp", views.SignUPViewSet, basename="SignUp")

url_Auth = [
    path("", include(router.urls)),
    path(
        "confirm-email/",
        views.SignUPViewSet.as_view({"post": "confirm_email"}),
        name="confirm-email",
    ),
    path(
        "confirm-phone/",
        views.SignUPViewSet.as_view({"post": "confirm_phone"}),
        name="confirm-phone",
    ),
    path(
        "resend-otp/",
        views.SignUPViewSet.as_view({"post": "send_reset_otp"}),
        name="send-reset-otp",
    ),
    path("Login/", views.LoginView.as_view()),
    path(
        "refresh-Token/",
        TokenRefreshView.as_view(),
        name="token_refresh"
    ),
]

url_Password = [
    path("forgot_password/", views.ForgetPasswordView.as_view(), name="forgot_password"),
    path(
        "reset_password/<str:token>", views.ResetPasswordView.as_view(), name="reset_password"
    ),
]

url_google_auth = [
    path(
        "google-login/", views.GoogleLoginRedirectView.as_view(), name="google_login_redirect"
    ),
    path(
        "google-callback/",
        views.GoogleLoginCallbackView.as_view(),
        name="google_login_callback",
    ),
]

urlpatterns = [
    path("Auth/", include(url_Auth)),
    path("userinfo/", views.UserInfo.as_view(), name="user_info"),
    path("password/", include(url_Password)),
    path("google_auth/", include(url_google_auth)),

    # Add to your urlpatterns
    path("update-fcm-token/", views.UpdateFCMTokenView.as_view(), name="update_fcm_token"),
]
