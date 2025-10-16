from ..serializers import OutputSerializers


def get_user_info(request):
    user = OutputSerializers.UserInfoSerializer(request.user, many=False)
    return user.data
