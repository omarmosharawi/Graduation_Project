"""
Django settings for The RE Platform project.

For more information on this file, see
https://docs.djangoproject.com/en/5.0/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/5.0/ref/settings/
"""

import os
from django.templatetags.static import static
from django.utils.translation import gettext_lazy as _
from config.env import BASE_DIR


# ==============================================================================
# REST FRAMEWORK
# ==============================================================================

REST_FRAMEWORK = {
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_THROTTLE_CLASSES": [
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.UserRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "anon": "100/day",
        "user": "1000/day",
        "otp_request": "1/min",
    },
}


# ==============================================================================
# DRF SPECTACULAR (API DOCS)
# ==============================================================================

SPECTACULAR_SETTINGS = {
    "TITLE": "The RE Platform API",
    "DESCRIPTION": "API documentation for The RE Platform",
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
}


# ==============================================================================
# INSTALLED APPS
# ==============================================================================

DEFAULT_APPS = [
    "unfold",
    "unfold.contrib.filters",
    "unfold.contrib.forms",
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
]

THIRD_PARTY_APPS = [
    "rest_framework",
    "django_filters",
    "corsheaders",
    "django_prometheus",
    "drf_spectacular",
    "drf_spectacular_sidecar",
    "rest_framework_simplejwt",
]

LOCAL_APPS = [
    "apps.Users",
]

INSTALLED_APPS = DEFAULT_APPS + THIRD_PARTY_APPS + LOCAL_APPS


# ==============================================================================
# MIDDLEWARE
# ==============================================================================

BASIC_MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.locale.LocaleMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

MIDDLEWARE = (
    [
        "django_prometheus.middleware.PrometheusBeforeMiddleware",
        "corsheaders.middleware.CorsMiddleware",
    ]
    + BASIC_MIDDLEWARE
    + ["django_prometheus.middleware.PrometheusAfterMiddleware"]
)


# ==============================================================================
# URLS & WSGI
# ==============================================================================

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"


# ==============================================================================
# TEMPLATES
# ==============================================================================

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],          # Add project-level template dirs here if needed
        "APP_DIRS": True,    # Required for Unfold template discovery
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]


# ==============================================================================
# AUTHENTICATION
# ==============================================================================

AUTH_USER_MODEL = "Users.User"

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
        "OPTIONS": {
            "min_length": 8,
        },
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]


# ==============================================================================
# INTERNATIONALIZATION
# ==============================================================================

LANGUAGE_CODE = "en-us"
LANGUAGES = (
    ("en", _("English")),
    ("ar", _("Arabic")),
)

TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True


# ==============================================================================
# STATIC & MEDIA FILES
# ==============================================================================

STATIC_ROOT = os.path.join(BASE_DIR, "staticfiles")
STATIC_URL = "/static/"
STATICFILES_DIRS = [os.path.join(BASE_DIR, "static")]

MEDIA_URL = "/media/"
MEDIA_ROOT = os.path.join(BASE_DIR, "media")


# ==============================================================================
# ADDITIONAL SETTINGS MODULES
# ==============================================================================

from config.settings.celery import *        # noqa
from config.settings.cors import *          # noqa
from config.settings.sessions import *      # noqa
from config.settings.email_sending import * # noqa
from .config_selector import *              # noqa: F403 F401 E402


# ==============================================================================
# UNFOLD ADMIN THEME CONFIGURATION
# ==============================================================================

UNFOLD = {
    "SITE_TITLE": "The RE Admin Dashboard",
    "SITE_HEADER": "The RE Platform",

    "SITE_LOGO": {
        "light": lambda request: static("images/logo.png"),
        "dark": lambda request: static("images/logo.png"),
    },

    "SITE_ICON": {
        "light": lambda request: static("images/icon-light.png"),
        "dark": lambda request: static("images/icon.png"),
    },

    "SITE_FAVICONS": [
        {
            "rel": "icon",
            "sizes": "32x32",
            "type": "image/x-icon",
            "href": lambda request: static("images/favicon.ico"),
        },
    ],

    # Primary color palette — oklch values for the purple/violet brand color
    "COLORS": {
        "primary": {
            "50": "#fcfaf5",   # Lightest gold/cream (used for subtle backgrounds)
            "100": "#f8f3e5",
            "200": "#efe3c5",
            "300": "#e5d0a0",
            "400": "#dbba75",
            "500": "#d4af37",  # Main Logo Gold (Standard Metallic Gold)
            "600": "#b59126",  # Slightly darker for hover states
            "700": "#91701b",
            "800": "#795a1a",
            "900": "#674b19",
            "950": "#3c2a0c",  # Darkest shade (used for deep contrasts)
        },
    },

    # Show the language switcher in the admin sidebar
    "SHOW_LANGUAGES": True,
}


# ==============================================================================
# LOGGING
# ==============================================================================

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "{levelname} {asctime} {module} {process:d} {thread:d} {message}",
            "style": "{",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "verbose",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "INFO",
    },
    "loggers": {
        "django.db.backends": {
            "handlers": ["console"],
            "level": "ERROR",   # Switch to "DEBUG" to log all SQL queries
            "propagate": False,
        },
    },
}