from celery import shared_task
from firebase_admin import messaging
from apps.Users.models import User
import logging

logger = logging.getLogger(__name__)


@shared_task
def send_achievement_push_notification(user_id, badge_name):
    """Sends an FCM push notification when a user earns a badge."""
    try:
        user = User.objects.get(id=user_id)
        token = user.profile.fcm_token

        if not token:
            logger.warning(f"Cannot send push: No FCM token for user {user.username}")
            return "No token"

        # Construct the push notification payload
        message = messaging.Message(
            notification=messaging.Notification(
                title="Achievement Unlocked! 🏆",
                body=f"Congratulations! You just earned the '{badge_name}' badge.",
            ),
            data={
                "click_action": "FLUTTER_NOTIFICATION_CLICK",  # Standard for mobile handling
                "type": "badge_earned",
                "badge_name": badge_name
            },
            token=token,
        )

        # Fire it off to Google's servers
        response = messaging.send(message)
        logger.info(f"Successfully sent notification to {user.username}: {response}")
        return response

    except Exception as e:
        logger.error(f"Failed to send FCM notification: {e}")
        return str(e)