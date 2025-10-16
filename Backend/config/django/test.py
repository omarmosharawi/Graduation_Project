import os

# This is extremely "eye-poking",
# but we need it, if we want to ignore the debug toolbar in tests
# This is needed because of the way we setup Django Debug Toolbar.
# Since we import base settings, the entire setup will be done, before we have any chance to change.
# A different way of approaching this would be to have a separate set of env variables for tests.
os.environ.setdefault("DEBUG_TOOLBAR_ENABLED", "False")

from .base import *  # noqa

DEBUG = False
PASSWORD_HASHERS = ["django.contrib.auth.hashers.MD5PasswordHasher"]

CELERY_BROKER_BACKEND = "memory"
CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_EAGER_PROPAGATES = True

CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
    }
}

DATABASES = {
    "default": {
        "ENGINE": os.environ.get("SQL_ENGINE", "django.db.backends.postgresql"),
        "NAME": os.environ.get("SQL_DATABASE_NAME", "mydatabase"),  # Set a default database name
        "USER": os.environ.get("SQL_USER", "user"),
        "PASSWORD": os.environ.get("SQL_PASSWORD", "password"),
        "HOST": os.environ.get("SQL_HOST", "localhost"),
        "PORT": os.environ.get("SQL_PORT", "5432"),
    }
}
