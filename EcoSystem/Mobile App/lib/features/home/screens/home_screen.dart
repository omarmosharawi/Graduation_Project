// =============================================================================
// HOME SCREEN - Main Dashboard
// =============================================================================
// The main dashboard displaying:
// - Welcome message with user name
// - Search bar for offers/rewards
// - Featured offers carousel
// - Categories grid
// - Quick action buttons
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/offers_service.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/profile_completion_popup.dart';
import '../widgets/home_carousel.dart';

/// Category data model
class Category {
  final String name;
  final IconData icon;
  final Color color;

  const Category({
    required this.name,
    required this.icon,
    required this.color,
  });
}

// Note: Offer model is imported from OffersService

/// HomeScreen displays the main dashboard
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Sample categories
  static const List<Category> _categories = [
    Category(name: 'Groceries', icon: Icons.shopping_basket, color: AppColors.groceries),
    Category(name: 'Beauty', icon: Icons.spa, color: AppColors.beauty),
    Category(name: 'Restaurants', icon: Icons.restaurant, color: AppColors.restaurants),
    Category(name: 'Entertainment', icon: Icons.movie, color: AppColors.entertainment),
    Category(name: 'Shopping', icon: Icons.shopping_bag, color: Color(0xFF7E57C2)),
    Category(name: 'Health', icon: Icons.favorite, color: Color(0xFF26A69A)),
  ];

  // OffersService for real data
  static final OffersService _offersService = OffersService();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<FirebaseAuthService>();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ProfileCompletionChecker(
        child: AnimatedBackground(
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                // Refresh both auth and offers
                await authService.refreshUserData();
                await _offersService.getOffersStream().first;
              },
              child: CustomScrollView(
                slivers: [
                // ---------------------------------------------------------------
                // App Bar with Welcome & Notifications
            // ---------------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Welcome message
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (user?.name ?? 'User').split(' ').first,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    // Notification bell
                    StreamBuilder<int>(
                      stream: context.read<FirebaseAuthService>().getUnreadNotificationsCountStream(),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        return IconButton(
                          onPressed: () => context.push(RoutePaths.notifications),
                          icon: Stack(
                            children: [
                              const Icon(
                                Icons.notifications_outlined,
                                size: 28,
                                color: AppColors.textPrimary,
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ---------------------------------------------------------------
            // Points Balance Card
            // ---------------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Points',
                            style: TextStyle(
                              color: AppColors.textOnPrimary,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user?.rank ?? 'Bronze',
                              style: const TextStyle(
                                color: AppColors.textOnPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${user?.currentPoints ?? 0}',
                            style: const TextStyle(
                              color: AppColors.textOnPrimary,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text(
                              'pts',
                              style: TextStyle(
                                color: AppColors.textOnPrimary,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: ${user?.totalPoints ?? 0} points earned',
                        style: TextStyle(
                          color: AppColors.textOnPrimary.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ---------------------------------------------------------------
            // Search Bar
            // ---------------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  readOnly: true,
                  onTap: () {
                    context.push('${RoutePaths.offers}?focusSearch=true');
                  },
                  decoration: InputDecoration(
                    hintText: 'Search offers & rewards',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            // ---------------------------------------------------------------
            // Home Carousel (Analytics & Promos)
            // ---------------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: HomeCarousel(),
              ),
            ),

            // ---------------------------------------------------------------
            // Featured Offers Section
            // ---------------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Featured Offers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(RoutePaths.offers),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),

            // Offers Carousel - Real data from Firestore
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: StreamBuilder<List<Offer>>(
                  stream: _offersService.getOffersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final offers = snapshot.data ?? [];
                    
                    if (offers.isEmpty) {
                      return Center(
                        child: Text(
                          'No offers available yet',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: offers.length > 5 ? 5 : offers.length, // Show max 5
                      itemBuilder: (context, index) {
                        return _OfferCard(offer: offers[index]);
                      },
                    );
                  },
                ),
              ),
            ),

            // ---------------------------------------------------------------
            // Recycle & Earn Section
            // ---------------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recycle and earn rewards',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Plastic & Metal Card
                    InkWell(
                      onTap: () => context.push(RoutePaths.plasticMetal),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Plastic & metal',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Recycle bottles and cans at RVMs',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.recycling,
                                size: 32,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Rewards Center Card
                    InkWell(
                      onTap: () => context.push(RoutePaths.offers),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rewards center',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Redeem points for offers',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.card_giftcard,
                                size: 32,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // On-demand collection Card (Premium)
                    InkWell(
                      onTap: () {
                        if (authService.isProfileIncomplete) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => ProfileCompletionDialog(
                              isProfileIncomplete: true,
                              needsEmailVerification: !authService.isGoogleUser && !authService.isEmailVerified,
                            ),
                          );
                        } else {
                          context.push(RoutePaths.pickupRequest);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'On-demand collection',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Get your recyclables collected from home',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_shipping,
                                size: 32,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------------------------------------------------------------
            // Categories Section
            // ---------------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            // Categories Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _CategoryCard(category: _categories[index]);
                  },
                  childCount: _categories.length,
                ),
              ),
            ),

            // Bottom padding for nav bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
        ),
      ),
    ));
  }
}

/// Offer card widget
class _OfferCard extends StatelessWidget {
  final Offer offer;

  const _OfferCard({required this.offer});

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Groceries':
        return AppColors.groceries;
      case 'Beauty':
        return AppColors.beauty;
      case 'Restaurants':
        return AppColors.restaurants;
      case 'Entertainment':
        return AppColors.entertainment;
      case 'Shopping':
        return const Color(0xFF7E57C2);
      case 'Health':
        return const Color(0xFF26A69A);
      default:
        return AppColors.primary;
    }
  }

  LinearGradient _getCategoryGradient(String category) {
    final color = _getCategoryColor(category);
    return LinearGradient(
      colors: [color, color.withOpacity(0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(offer.category);
    final gradient = _getCategoryGradient(offer.category);
    
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => context.push(RoutePaths.offers),
          child: Stack(
            children: [
              // Background: Image or Gradient
              Positioned.fill(
                child: offer.imageUrl != null && offer.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: offer.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(gradient: gradient),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(gradient: gradient),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(gradient: gradient),
                      ),
              ),
              
              // Overlay for readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Tag + Redeem Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Text(
                                offer.category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: color,
                          ),
                        ),
                      ],
                    ),

                    // Bottom: Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offer.partner,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Points required
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${offer.pointsRequired} pts',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category card widget
class _CategoryCard extends StatelessWidget {
  final Category category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push(RoutePaths.offers, extra: category.name);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
