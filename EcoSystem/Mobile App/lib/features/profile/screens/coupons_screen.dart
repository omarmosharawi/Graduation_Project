// =============================================================================
// COUPONS SCREEN - User's Redeemed Coupons
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_auth_service.dart';

class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<FirebaseAuthService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Coupons'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: authService.getCouponsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final coupons = snapshot.data!.docs;
          final activeCoupons = coupons.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
            final isUsed = data['isUsed'] as bool? ?? false;
            return !isUsed && (expiresAt == null || expiresAt.isAfter(DateTime.now()));
          }).toList();

          final expiredCoupons = coupons.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
            final isUsed = data['isUsed'] as bool? ?? false;
            return isUsed || (expiresAt != null && expiresAt.isBefore(DateTime.now()));
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeCoupons.isNotEmpty) ...[
                _buildSectionHeader('Active Coupons'),
                ...activeCoupons.map((doc) => _CouponCard(doc: doc, isActive: true)),
                const SizedBox(height: 24),
              ],
              if (expiredCoupons.isNotEmpty) ...[
                _buildSectionHeader('Used / Expired'),
                ...expiredCoupons.map((doc) => _CouponCard(doc: doc, isActive: false)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
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
            'No Coupons Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Redeem offers to get coupons!',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool isActive;

  const _CouponCard({required this.doc, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['offerTitle'] as String? ?? 'Coupon';
    final partner = data['partner'] as String? ?? '';
    final code = data['couponCode'] as String? ?? '';
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surface : AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(color: AppColors.primary.withOpacity(0.3))
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.textHint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    color: isActive ? AppColors.primary : AppColors.textHint,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isActive ? AppColors.textPrimary : AppColors.textHint,
                        ),
                      ),
                      Text(
                        partner,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (expiresAt != null)
                        Text(
                          'Expires: ${expiresAt.day}/${expiresAt.month}/${expiresAt.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive ? AppColors.textSecondary : AppColors.error,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coupon code copied!')),
                      );
                    },
                    icon: const Icon(Icons.copy, color: AppColors.primary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
