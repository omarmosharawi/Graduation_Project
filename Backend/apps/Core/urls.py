from django.urls import path
from .views import (
    RewardsCatalogView,
    RedeemRewardView,
    TransactionHistoryView
)

app_name = 'core'

urlpatterns = [
    # Rewards & Redemption
    path('rewards/', RewardsCatalogView.as_view(), name='rewards-catalog'),
    path('rewards/<int:reward_id>/redeem/', RedeemRewardView.as_view(), name='redeem-reward'),

    # Recycling & Transactions
    path('transactions/', TransactionHistoryView.as_view(), name='transaction-history'),
]