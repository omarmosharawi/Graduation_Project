// =============================================================================
// OFFERS SCREEN - Browse and Redeem Offers
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/offers_service.dart';

import '../../../app/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OffersScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialOfferId;
  final bool focusSearch;

  const OffersScreen({
    super.key,
    this.initialCategory,
    this.initialOfferId,
    this.focusSearch = false,
  });

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final OffersService _offersService = OffersService();
  final ScrollController _categoryScrollController = ScrollController();
  late String _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
    
    // Scroll to selected category after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCategory != null && widget.initialCategory != 'All') {
        _scrollToSelectedCategory();
      }
    });

    // Handle initial offer redemption if ID is provided
    if (widget.initialOfferId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleInitialOffer(widget.initialOfferId!);
      });
    }
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedCategory() {
    if (!_categoryScrollController.hasClients) return;

    final categories = ['All', ..._offersService.getCategories()];
    final index = categories.indexOf(_selectedCategory);
    if (index <= 0) return;

    // Estimate width: padding (8) + avg char width (8) * length + chip internal padding (24)
    // This is an approximation for smooth UX
    double offset = 0;
    for (int i = 0; i < index; i++) {
      offset += categories[i].length * 8 + 32; // 32 = internal padding + right margin
    }

    // Centering logic: Scroll so the chip is roughly in the middle
    final screenWidth = MediaQuery.of(context).size.width;
    _categoryScrollController.animateTo(
      (offset - screenWidth / 2 + 50).clamp(0, _categoryScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleInitialOffer(String offerId) async {
    // We need to wait for offers to be loaded or fetch it directly
    final offers = await _offersService.getOffersStream().first;
    final offer = offers.firstWhere((o) => o.id == offerId, orElse: () => throw 'Offer not found');
    
    if (mounted) {
      final authService = context.read<FirebaseAuthService>();
      final userPoints = authService.currentUser?.currentPoints ?? 0;
      
      if (userPoints >= offer.pointsRequired) {
        _redeemOffer(offer);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not enough points for ${offer.title}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<FirebaseAuthService>();
    final userPoints = authService.currentUser?.currentPoints ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offers'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  const Icon(Icons.stars, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$userPoints pts',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.confirmation_number),
            tooltip: 'My Coupons',
            onPressed: () => context.push(RoutePaths.coupons),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
            child: TextField(
              autofocus: widget.focusSearch, // Only auto-focus when coming from Home search bar
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
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          
          // Category Filter
          SizedBox(
            height: 50,
            child: ListView(
              controller: _categoryScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _CategoryChip(
                  label: 'All',
                  isSelected: _selectedCategory == 'All',
                  onTap: () {
                    setState(() => _selectedCategory = 'All');
                    _scrollToSelectedCategory();
                  },
                ),
                ..._offersService.getCategories().map((cat) => _CategoryChip(
                      label: cat,
                      isSelected: _selectedCategory == cat,
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        _scrollToSelectedCategory();
                      },
                    )),
              ],
            ),
          ),

          // Offers Grid
          Expanded(
            child: StreamBuilder<List<Offer>>(
              stream: _offersService.getOffersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                var offers = snapshot.data!;
                if (_selectedCategory != 'All') {
                  offers = offers.where((o) => o.category == _selectedCategory).toList();
                }
                
                if (_searchQuery.isNotEmpty) {
                  offers = offers.where((o) => o.title.toLowerCase().contains(_searchQuery)).toList();
                }

                if (offers.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    return _OfferCard(
                      offer: offers[index],
                      canAfford: userPoints >= offers[index].pointsRequired,
                      onRedeem: () => _redeemOffer(offers[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            'No Offers Available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new offers!',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _redeemOffer(Offer offer) async {
    final authService = context.read<FirebaseAuthService>();

    // Use the state's persistent context for the dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Redeem ${offer.title}?'),
        content: Text('This will cost ${offer.pointsRequired} points.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await authService.redeemOffer(
        offerId: offer.id,
        offerTitle: offer.title,
        partner: offer.partner,
        pointsRequired: offer.pointsRequired,
      );

      if (mounted) {
        if (result != null && !result.startsWith('Error:')) {
          _showCouponDialog(offer, result);
        } else {
          final errorMessage = result?.replaceFirst('Error: ', '') ?? 'Failed to redeem coupon. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showCouponDialog(Offer offer, String code) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            const Text('Redemption Successful!', textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You have successfully redeemed ${offer.title} from ${offer.partner}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            const Text(
              'COUPON CODE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.primary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coupon code copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copy Code',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Valid for 30 days',
              style: TextStyle(fontSize: 12, color: AppColors.textHint, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.push(RoutePaths.coupons);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('My Coupons'),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Offer offer;
  final bool canAfford;
  final VoidCallback onRedeem;

  const _OfferCard({
    required this.offer,
    required this.canAfford,
    required this.onRedeem,
  });

  Color _getCategoryColor() {
    switch (offer.category) {
      case 'Groceries':
        return AppColors.groceries;
      case 'Beauty':
        return AppColors.beauty;
      case 'Restaurants':
        return AppColors.restaurants;
      case 'Entertainment':
        return AppColors.entertainment;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Color Header
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _getCategoryColor().withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: offer.imageUrl != null && offer.imageUrl!.isNotEmpty
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(offer.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: offer.imageUrl == null || offer.imageUrl!.isEmpty
                ? Center(
                  child: Icon(
                    Icons.local_offer,
                    size: 40,
                    color: _getCategoryColor(),
                  ),
                )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  offer.partner,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.stars, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '${offer.pointsRequired} pts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: canAfford ? AppColors.primary : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canAfford ? onRedeem : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      canAfford ? 'Redeem' : 'Need more pts',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
