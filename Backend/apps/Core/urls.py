from django.urls import path
from .views import (
    RewardsCatalogView,
    RedeemRewardView,
    TransactionHistoryView,
    LeaderboardView,
    UserBadgesView,
    DelegateRequestListView,
    KioskMapView,
    CommunityImpactView,
    CategoryListView,
    HomeCardListView,
    AvailableJobsView,
    AcceptJobView,
    CompleteJobView
)

app_name = 'core'

urlpatterns = [
    # Rewards & Redemption
    path('categories/', CategoryListView.as_view(), name='category-list'),
    path('rewards/', RewardsCatalogView.as_view(), name='rewards-catalog'),
    path('rewards/<int:reward_id>/redeem/', RedeemRewardView.as_view(), name='redeem-reward'),

    # Recycling & Transactions
    path('transactions/', TransactionHistoryView.as_view(), name='transaction-history'),

    # Gamification
    path('leaderboard/', LeaderboardView.as_view(), name='leaderboard'),
    path('badges/mine/', UserBadgesView.as_view(), name='my-badges'),

    # Delegate Service
    path('delegate-requests/', DelegateRequestListView.as_view(), name='delegate-requests'),
    path('delegates/jobs/available/', AvailableJobsView.as_view(), name='available-jobs'),
    path('delegates/jobs/accept/', AcceptJobView.as_view(), name='accept-job'),
    path('delegates/jobs/complete/', CompleteJobView.as_view(), name='complete-job'),

    # Kiosk
    path('kiosks/map/', KioskMapView.as_view(), name='kiosk-map'),

    # Home Cards
    path('home-cards/', HomeCardListView.as_view(), name='home-cards'),

    # Community Hub
    path('community/impact/', CommunityImpactView.as_view(), name='community-impact'),
]