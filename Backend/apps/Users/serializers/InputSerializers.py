from rest_framework.serializers import (
    ModelSerializer,
    CharField,
    BooleanField,
    ImageField,
    ValidationError,
    EmailField,
)
from ..models import User
from ..Tasks import serializers_tasks
from ..db_queries import services
from rest_framework import serializers


class SignUpSerializer(ModelSerializer):
    profile_picture = ImageField(required=False)
    confirm_password = CharField(write_only=True, required=True)
    accept_terms = BooleanField(write_only=True, required=True)
    first_name = CharField(required=True)
    last_name = CharField(required=True)
    email = EmailField(required=True)
    phone = CharField(required=True)

    class Meta:
        model = User
        fields = [
            "uuid",
            "first_name",
            "last_name",
            "username",
            "email",
            "phone",
            "password",
            "confirm_password",
            "email_verified",
            "phone_verified",
            "profile_picture",
            "accept_terms",
        ]
        extra_kwargs = {
            "password": {"write_only": True},
            "username": {"read_only": True},
            "last_name": {"required": True},
            "first_name": {"required": True},
            "email": {"required": True},
            "phone": {"required": True},
        }

    def validate_email(self, value: str):
        return serializers_tasks.validate_email(value, User)

    def validate_password(self, value: str):
        return serializers_tasks.validate_password_strength(value)

    def validate(self, data: dict):
        if data.get("password") != data.get("confirm_password"):
            raise ValidationError("Passwords do not match.")
        if not data.get("accept_terms"):
            raise ValidationError("Terms and conditions must be accepted.")
        return data

    def create(self, validated_data: dict):
        first_name = validated_data["first_name"]
        last_name = validated_data["last_name"]
        unique_username = serializers_tasks.generate_unique_username(first_name, last_name, User)
        created_user = services.Create_user(validated_data, unique_username)
        return created_user


class GoogleAuthSerializer(serializers.Serializer):
    id_token = serializers.CharField(required=True, help_text="The Firebase ID token received from the mobile app.")