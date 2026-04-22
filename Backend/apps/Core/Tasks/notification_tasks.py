from celery import shared_task
from firebase_admin import messaging
from apps.Users.models import User, Profile
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


@shared_task
def process_custom_notification(notification_id, title, body, target='ALL', user_ids=None):
    """Processes bulk push notifications from the Django Admin."""
    try:
        # 1. Gather valid FCM tokens
        tokens = []
        if target == 'ALL':
            tokens = list(
                Profile.objects.exclude(fcm_token__isnull=True).exclude(fcm_token__exact='').values_list('fcm_token',
                                                                                                         flat=True))
        elif target == 'SPECIFIC' and user_ids:
            tokens = list(Profile.objects.filter(user__id__in=user_ids).exclude(fcm_token__isnull=True).exclude(
                fcm_token__exact='').values_list('fcm_token', flat=True))

        if not tokens:
            logger.warning(f"No valid FCM tokens found for Notification ID {notification_id}.")
            return "No valid FCM tokens found."

        # 2. Batch tokens (FCM max is 500 per request)
        batch_size = 500
        success_total = 0
        failure_total = 0

        for i in range(0, len(tokens), batch_size):
            batch_tokens = tokens[i:i + batch_size]

            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data={
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                    "type": "admin_broadcast"
                },
                tokens=batch_tokens,
            )

            response = messaging.send_multicast(message)
            success_total += response.success_count
            failure_total += response.failure_count

            # Optional: Handle stale tokens (if failure_count > 0, you can loop through response.responses to find and delete invalid tokens)

        logger.info(f"Notification {notification_id} complete. Success: {success_total}, Failed: {failure_total}")
        return f"Success: {success_total}, Failed: {failure_total}"

    except Exception as e:
        logger.error(f"Failed to process custom notification {notification_id}: {e}")
        return str(e)