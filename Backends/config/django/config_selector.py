import socket


def get_host_name() -> str:
    return socket.gethostname()


current_host = get_host_name()


if current_host == 'test machine name':
    from .test import *  # noqa: F403 F401
elif current_host == 'production_server_name':
    from .production import *  # noqa: F403 F401
else:
    from .local import *  # noqa: F403 F401 # Default to local if unsure
