from config.env import env, BASE_DIR
from os.path import join
from .base import *  # noqa

DEBUG = env.bool("DJANGO_DEBUG_LOCAL", default=False)

SECRET_KEY = env("SECRET_KEY")

ALLOWED_HOSTS = env.list("ALLOWED_HOSTS", default=[])

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME':  join(BASE_DIR, 'db.sqlite3'),
    }
}
