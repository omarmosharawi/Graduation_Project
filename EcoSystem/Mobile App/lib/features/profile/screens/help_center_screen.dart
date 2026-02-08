// =============================================================================
// HELP CENTER SCREEN - FAQs and Support
// =============================================================================

import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for help...',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: AppColors.textHint),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // FAQ Section
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _FaqItem(
            question: 'How do I earn points?',
            answer: 'You can earn points by recycling plastic bottles and aluminum cans at any REward RVM (Reverse Vending Machine) kiosk. Each item recycled earns you 10 points.',
          ),
          _FaqItem(
            question: 'Where can I find RVM kiosks?',
            answer: 'Open the Map tab in the app to see all RVM kiosk locations near you. Each location shows the address and available materials it accepts.',
          ),
          _FaqItem(
            question: 'How do I redeem my points?',
            answer: 'Go to the Offers page to browse available rewards. Select an offer that fits your points balance and tap "Redeem" to get your coupon code.',
          ),
          _FaqItem(
            question: 'How long are coupons valid?',
            answer: 'Coupons are typically valid for 30 days from the date of redemption. Check the expiry date on each coupon in your My Coupons section.',
          ),
          _FaqItem(
            question: 'Can I transfer points to another user?',
            answer: 'Currently, points cannot be transferred between accounts. Each user earns and redeems their own points.',
          ),
          _FaqItem(
            question: 'What materials can I recycle?',
            answer: 'Our RVMs accept:\n• Plastic bottles (PET)\n• Aluminum cans\n• Glass bottles (at select locations)\n\nMake sure items are empty and not crushed.',
          ),

          const SizedBox(height: 24),

          // Contact Support
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.support_agent, size: 48, color: AppColors.primary),
                const SizedBox(height: 12),
                const Text(
                  'Need more help?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact our support team',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Open email or chat
                  },
                  icon: const Icon(Icons.email),
                  label: const Text('Contact Support'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          widget.question,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Icon(
          _isExpanded ? Icons.remove : Icons.add,
          color: AppColors.primary,
        ),
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              widget.answer,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
