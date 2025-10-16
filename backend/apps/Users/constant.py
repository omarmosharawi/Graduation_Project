from config.env import env
CURRENT_SITE = ""
rest_password_url = env('REST_PASSWORD_URL')


def create_otp_template(user_name: str, OTP: str, user_email: str):
    otp_template = f"""
    
    """
    return otp_template


def create_password_reset_template(
    user_name: str, reset_link: str, operating_system: str, browser_name: str
):
    reset_template = f"""
    
    """
    return reset_template
