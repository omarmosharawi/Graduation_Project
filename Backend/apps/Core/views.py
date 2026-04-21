from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Reward, RecyclingTransaction
from .serializers import RewardSerializer, TransactionSerializer
from .services import CoreService
from django.core.exceptions import ValidationError

class RewardsCatalogView(generics.ListAPIView):
    """Browse catalog of available rewards."""
    queryset = Reward.objects.filter(is_active=True, stock__gt=0)
    serializer_class = RewardSerializer
    permission_classes = [IsAuthenticated]

class RedeemRewardView(generics.CreateAPIView):
    """Redeem points for a specific reward."""
    permission_classes = [IsAuthenticated]

    def post(self, request, reward_id):
        try:
            redemption = CoreService.redeem_reward(user=request.user, reward_id=reward_id)
            return Response({
                "message": "Reward redeemed successfully!",
                "voucher_code": redemption.redemption_code,
                "remaining_points": request.user.profile.current_points
            }, status=status.HTTP_201_CREATED)
        except Reward.DoesNotExist:
            return Response({"error": "Reward not found."}, status=status.HTTP_404_NOT_FOUND)
        except ValidationError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

class TransactionHistoryView(generics.ListAPIView):
    """View chronological list of recycling transactions."""
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Returns transactions for the logged-in user, newest first
        return RecyclingTransaction.objects.filter(user=self.request.user).order_by('-created_at')