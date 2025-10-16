import re
from django.core.exceptions import ValidationError as DjangoValidationError
from django.contrib.auth.password_validation import validate_password
from random import randint
from ..models import User


def validate_email(value, User: User):
    if User.objects.filter(email=value).exists():
        raise DjangoValidationError("Email is already registered.")
    return value


def validate_password_strength(value):
    """
        Validates that the password contains at least one lowercase letter, one
        uppercase letter, one digit, and one special character.
    """
    if not re.search(r'[a-z]', value):
        raise DjangoValidationError("The password must contain at least one lowercase letter.")

    if not re.search(r'[A-Z]', value):
        raise DjangoValidationError("The password must contain at least one capital letter.")

    if not re.search(r'\d', value):
        raise DjangoValidationError("The password must contain at least one number.")

    if not re.search(r'[@$!%*?&#]', value):
        raise DjangoValidationError("The password must contain at least one special character (e.g. @, $, !, %).")

    # if not re.search(r"\d", value) or not re.search("[A-Z]", value):
    #     raise DjangoValidationError(
    #         "Password should contain at least 1 number and 1 uppercase letter."
    #     )

    validate_password(value)
    return value


def generate_unique_username(first_name, last_name, User: User):
    base_username = re.sub(r"\s+", "_", f"{first_name}_{last_name}").lower()
    while True:
        random_number = randint(1000000, 9999999)
        unique_username = f"{base_username}_{random_number}"
        try:
            User.objects.get(username=unique_username)
        except User.DoesNotExist:
            return unique_username
