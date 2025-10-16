from rest_framework.serializers import ( # noqa
    ModelSerializer,
    CharField,
    BooleanField,
    ImageField,
    ValidationError,
    EmailField
)
from ..models import User


class LoginUserSerializer(ModelSerializer):
    profile_picture = ImageField(required=False)

    class Meta:
        model = User
        fields = (
            "uuid",
            "username",
            "first_name",
            "last_name",
            "email",
            "phone",
            "profile_picture",
            "is_staff",
            "is_superuser",
        )


class UserInfoSerializer(ModelSerializer):
    class Meta:
        model = User
        fields = (
            "uuid",
            "username",
            "first_name",
            "last_name",
            "email",
            "phone",
            "profile_picture",
            "is_staff",
            "is_superuser",
        )
