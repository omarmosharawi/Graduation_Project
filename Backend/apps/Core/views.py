from rest_framework.views import APIView
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.pagination import PageNumberPagination
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework import serializers
from drf_spectacular.utils import extend_schema, OpenApiResponse, inline_serializer
from .models import Reward, RecyclingTransaction, Kiosk, RewardRedemption, PartnerCategory, HomeCard, DelegateRequest
from apps.Users.models import User
from .serializers import RewardSerializer, TransactionSerializer, DelegateRequestSerializer, KioskSerializer, PartnerCategorySerializer, HomeCardSerializer, AcceptJobInputSerializer, CompleteJobInputSerializer
from .services import CoreService, GamificationService, DelegateService, DelegateRequest
from django.core.exceptions import ValidationError
from django.db.models import Sum, Count
from django.db import transaction
from django.utils import timezone


class RewardsCatalogView(generics.ListAPIView):
    """Browse catalog of available rewards."""
    queryset = Reward.objects.filter(is_active=True, stock__gt=0)
    serializer_class = RewardSerializer
    permission_classes = [IsAuthenticated]


class RedeemRewardInputSerializer(serializers.Serializer):
    reward_id = serializers.IntegerField()

class RedeemRewardView(generics.CreateAPIView):
    """Redeem points for a specific reward."""
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Redeem a Reward using Points",
        request=RedeemRewardInputSerializer,
        responses={200: OpenApiResponse(description="Reward claimed successfully.")}
    )
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


class RewardListView(generics.ListAPIView):
    """Fetches all active rewards, with an optional category filter."""
    serializer_class = RewardSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Start with all active rewards that are in stock
        queryset = Reward.objects.filter(is_active=True, stock__gt=0).order_by('-id')

        # Check if the mobile app passed a category filter in the URL
        category_name = self.request.query_params.get('category', None)
        if category_name:
            # Filter rewards where the Partner's category matches the requested name
            queryset = queryset.filter(partner__category__name__iexact=category_name)

        return queryset


class CategoryListView(generics.ListAPIView):
    """Fetches all partner categories to build the mobile app filter UI."""
    queryset = PartnerCategory.objects.all().order_by('name')
    serializer_class = PartnerCategorySerializer
    permission_classes = [IsAuthenticated]


class TransactionHistoryView(generics.ListAPIView):
    """View chronological list of recycling transactions."""
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Returns transactions for the logged-in user, newest first
        return RecyclingTransaction.objects.filter(user=self.request.user).order_by('-created_at')


class LeaderboardView(APIView):
    """Handles both Weekly and All-Time leaderboard requests."""
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Get Top 10 Recyclers Leaderboard",
        responses={200: OpenApiResponse(description="List of top users ordered by points.")}
    )
    def get(self, request):
        timeframe = request.query_params.get('timeframe', 'all_time')

        if timeframe == 'weekly':
            leaders = GamificationService.get_weekly_leaderboard()
            return Response({
                "timeframe": "weekly",
                "leaderboard": list(leaders)
            }, status=200)

        else:
            leaders = GamificationService.get_all_time_leaderboard()
            data = [
                {
                    "username": profile.user.username,
                    "total_points": profile.total_points,
                    "rank": profile.rank
                } for profile in leaders
            ]
            return Response({
                "timeframe": "all_time",
                "leaderboard": data
            }, status=200)


class UserBadgesView(APIView):
    """Returns the list of badges earned by the authenticated user."""
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Get Current User's Earned Badges",
        responses={200: OpenApiResponse(description="List of unlocked badges.")}
    )
    def get(self, request):
        user_badges = request.user.user_badges.select_related('badge').order_by('-earned_at')
        data = [
            {
                "name": ub.badge.name,
                "description": ub.badge.description,
                "metric": ub.badge.metric,
                "icon_url": request.build_absolute_uri(ub.badge.icon.url) if ub.badge.icon else None,
                "earned_at": ub.earned_at
            } for ub in user_badges
        ]
        return Response({"badges": data}, status=200)


class DelegateRequestListView(generics.ListCreateAPIView):
    """User can list their pickup requests and create new ones."""
    permission_classes = [IsAuthenticated]
    serializer_class = DelegateRequestSerializer

    def get_queryset(self):
        return DelegateRequest.objects.filter(user=self.request.user).order_by('-created_at')

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            pickup = DelegateService.create_pickup_request(
                user=request.user,
                data=serializer.validated_data
            )
            return Response({
                "message": f"Delegate requested successfully. Estimated cost: {pickup.cost_in_points} points.",
                "data": self.get_serializer(pickup).data,
                "remaining_points": request.user.profile.current_points
            }, status=status.HTTP_201_CREATED)

        except ValidationError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class AvailableJobsView(generics.ListAPIView):
    """Fetches all PENDING pickup requests for delegates to see."""
    serializer_class = DelegateRequestSerializer
    permission_classes = [IsAuthenticated]  # In a real app, you'd check if user is a Delegate

    def get_queryset(self):
        return DelegateRequest.objects.filter(status='PENDING').order_by('scheduled_date')


class AcceptJobView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Delegate: Accept a Pickup Job",
        request=AcceptJobInputSerializer,
        responses={200: OpenApiResponse(description="Delegation accepted successfully.")}
    )
    def post(self, request):
        serializer = AcceptJobInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        req_id = serializer.validated_data['request_id']

        try:
            job = DelegateRequest.objects.get(id=req_id, status='PENDING')
            job.status = 'ACCEPTED'
            # Assuming you have a 'delegate' field, you would link it here:
            job.delegate = request.user
            job.save()
            return Response({"message": "Delegation accepted successfully!"}, status=status.HTTP_200_OK)
        except DelegateRequest.DoesNotExist:
            return Response({"error": "Delegation not found or already taken."}, status=status.HTTP_404_NOT_FOUND)


class CompleteJobView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)  # Allows uploading the proof image

    @extend_schema(
        summary="Delegate: Complete Job & Award Points",
        description="Records the actual weight, creates a transaction, and awards points to the user.",
        request=CompleteJobInputSerializer,
        responses={200: OpenApiResponse(description="Points awarded successfully.")}
    )
    def post(self, request):
        serializer = CompleteJobInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        data = serializer.validated_data

        try:
            job = DelegateRequest.objects.get(id=data['request_id'], status='ACCEPTED')

            # Using atomic transaction to ensure points and records are created together safely
            with transaction.atomic():
                # 1. Update the Job Status
                job.status = 'COMPLETED'
                job.actual_weight_kg = data['actual_weight_kg']
                if 'proof_image' in data:
                    job.proof_image = data['proof_image']
                job.save()

                # 2. Calculate Points (Business Logic: 10 points per KG)
                points_to_award = int(float(data['actual_weight_kg']) * 10)

                # 3. Create the Recycling Transaction history
                RecyclingTransaction.objects.create(
                    user=job.user,
                    kiosk=None,  # It's a home pickup, not a kiosk drop-off
                    material_type=data['material_type'],
                    material_count=1,  # Bulk bag
                    weight_kg=data['actual_weight_kg'],
                    points_earned=points_to_award
                )

                # 4. Give the user their points!
                profile = job.user.profile
                profile.current_points += points_to_award
                profile.total_points += points_to_award
                profile.save()

            return Response({
                "message": "Delegation completed! Points have been deposited to the user.",
                "points_awarded": points_to_award
            }, status=status.HTTP_200_OK)

        except DelegateRequest.DoesNotExist:
            return Response({"error": "Delegation not found or not in ACCEPTED state."}, status=status.HTTP_400_BAD_REQUEST)


class KioskMapView(generics.ListAPIView):
    """Interactive Map to Locate Partner Kiosks."""
    queryset = Kiosk.objects.filter(status='online')
    serializer_class = KioskSerializer
    permission_classes = [IsAuthenticated]


class HomeCardPagination(PageNumberPagination):
    page_size = 3
    page_size_query_param = 'page_size'
    max_page_size = 10


class HomeCardListView(generics.ListAPIView):
    """Fetches active home cards (Announcements, Deals, Offers) with pagination."""
    serializer_class = HomeCardSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = HomeCardPagination  # Applies the 3-item limit

    def get_queryset(self):
        # Only return active cards, already ordered by priority in the Model Meta
        return HomeCard.objects.filter(is_active=True)

    @extend_schema(
        summary="Get Home UI Cards (Announcements, Deals, Offers)",
        description="Returns paginated cards for the mobile home screen. 3 items per page. Sorted by Priority."
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)


class CommunityImpactView(APIView):
    """Dashboard showing the community's collective impact."""
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Get Extended Global Community Impact Stats",
        responses={200: inline_serializer(
            name='ExtendedCommunityImpactResponse',
            fields={
                'global_stats': inline_serializer('GlobalStats', fields={
                    'total_weight_recycled_kg': serializers.FloatField(),
                    'estimated_co2_saved_kg': serializers.FloatField(),
                    'total_active_recyclers': serializers.IntegerField(),
                    'total_rewards_claimed': serializers.IntegerField(),
                    'total_delegate_pickups': serializers.IntegerField(),
                }),
                'material_breakdown': serializers.ListField(
                    child=serializers.DictField(),
                    help_text="Weight breakdown by material type (e.g., Plastic, Metal)."
                ),
                'top_kiosks': serializers.ListField(
                    child=serializers.DictField(),
                    help_text="The top 3 most active kiosks in the community."
                )
            }
        )}
    )
    def get(self, request):
        # 1. Base Global Stats
        total_weight_stats = RecyclingTransaction.objects.aggregate(total_kg=Sum('weight_kg'))
        total_kg = total_weight_stats['total_kg'] or 0
        # Environmental conversion (Example: 1 KG of plastic saves ~1.5 KG of CO2)
        co2_saved = float(total_kg) * 1.5

        total_users = User.objects.count()
        total_redemptions = RewardRedemption.objects.count()
        total_pickups = DelegateRequest.objects.filter(status='COMPLETED').count()

        # 2. Material Breakdown (Groups by material_type and sums the weight)
        materials = RecyclingTransaction.objects.values('material_type').annotate(
            total_weight=Sum('weight_kg')
        ).order_by('-total_weight')

        # 3. Top Community Kiosks (Gets the 3 kiosks with the most kg recycled)
        top_kiosks = RecyclingTransaction.objects.filter(kiosk__isnull=False).values(
            'kiosk__name', 'kiosk__address'
        ).annotate(
            total_contributed=Sum('weight_kg')
        ).order_by('-total_contributed')[:3]

        return Response({
            "global_stats": {
                "total_weight_recycled_kg": float(total_kg),
                "estimated_co2_saved_kg": float(co2_saved),
                "total_active_recyclers": total_users,
                "total_rewards_claimed": total_redemptions,
                "total_delegate_pickups": total_pickups
            },
            "material_breakdown": list(materials),
            "top_kiosks": list(top_kiosks)
        }, status=status.HTTP_200_OK)
