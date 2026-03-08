import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/models/global_stats_model.dart';
import '../../../../core/models/home_card_model.dart';
import '../../../../core/services/home_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import 'analytics_chart.dart';

class HomeCarousel extends StatelessWidget {
  final HomeService _homeService = HomeService();

  HomeCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HomeCard>>(
      stream: _homeService.getHomeCardsStream(),
      builder: (context, cardSnapshot) {
        if (cardSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }

        final cards = cardSnapshot.data ?? [];
        
        // If no cards, we can show a default promo or hide
        if (cards.isEmpty) {
           // Optional: Show default analytics card if no cards exist
           return SizedBox(height: 200, child: _AnalyticsCard());
        }

        return CarouselSlider(
          options: CarouselOptions(
            height: 200.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 6),
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            aspectRatio: 16/9,
            initialPage: 0,
          ),
          items: cards.map((card) {
            return Builder(
              builder: (BuildContext context) {
                if (card.type == 'analytics') {
                  return _AnalyticsCard(card: card);
                } else {
                  return _PromoCard(card: card);
                }
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final HomeService _homeService = HomeService();
  final HomeCard? card;

  _AnalyticsCard({this.card});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GlobalStats>(
      stream: _homeService.getGlobalStatsStream(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? GlobalStats(totalBottles: 0, totalCans: 0, totalWeightKg: 0);

        return Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Stats Text Column
                Expanded(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          card?.title ?? 'Our statistics',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _StatItem(
                          icon: Icons.local_drink,
                          value: stats.totalBottles,
                          label: 'Bottles',
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 6),
                        _StatItem(
                          icon: Icons.delete_outline,
                          value: stats.totalCans,
                          label: 'Cans',
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: 6),
                        _StatItem(
                          icon: Icons.scale,
                          value: stats.totalWeightKg.toInt(),
                          label: 'Kg Recycled',
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ),
                // Real Analytics Chart
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: AnalyticsChart(stats: stats),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final num value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  final HomeCard card;

  const _PromoCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (card.actionType == 'url' && card.actionValue != null) {
          final uri = Uri.parse(card.actionValue!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
        } else if (card.actionType == 'offer' && card.actionValue != null) {
          context.push('${RoutePaths.offers}?offerId=${card.actionValue}');
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          image: card.imageUrl != null && card.imageUrl!.isNotEmpty
              ? DecorationImage(
                  image: CachedNetworkImageProvider(card.imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (card.description != null)
                  Text(
                    card.description!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
