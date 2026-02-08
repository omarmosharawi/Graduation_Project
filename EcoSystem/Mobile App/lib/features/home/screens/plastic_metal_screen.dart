// =============================================================================
// PLASTIC METAL SCREEN - RVM Info & How It Works
// =============================================================================
// Matches the Figma design showing:
// - RVM machine image
// - What materials RVM accepts
// - Where to find RVMs
// - How to get rewards (4 steps)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';

class PlasticMetalScreen extends StatefulWidget {
  const PlasticMetalScreen({super.key});

  @override
  State<PlasticMetalScreen> createState() => _PlasticMetalScreenState();
}

class _PlasticMetalScreenState extends State<PlasticMetalScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final List<Map<String, String>> _steps = [
    {
      'number': '01',
      'title': 'Recycle bottles and cans',
      'description': 'Find nearest RVM using the map and follow the instructions on the machine.',
      'image': 'assets/images/step_rvm.png',
    },
    {
      'number': '02',
      'title': 'Sign up with your email address',
      'description': 'When recycling containers at a RVM or on our app, You will receive 10 bonuses for each bottle or can you return.',
      'image': 'assets/images/step_signup.png',
    },
    {
      'number': '03',
      'title': 'Monitor statistics',
      'description': 'You can always monitor your statistics and ranking in your profile on the app.',
      'image': 'assets/images/step_stats.png',
    },
    {
      'number': '04',
      'title': 'Exchange bonuses for real benefits',
      'description': 'Explore discounts, loyalty card bonuses and gifts from our partners in your profile.',
      'image': 'assets/images/step_exchange.png',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plastic & metal'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // RVM Machine Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.background,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // RVM Machine image
                  Image.asset(
                    'assets/images/rvm_machine.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Recycle plastic bottles and aluminum cans with RVMs, and get bonus points for your contribution to a sustainable future. Like the bonus program.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // What does a RVM accept?
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What does a RVM accept?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _AcceptedItemWithImage(
                        label: 'Plastic bottles and aluminum cans',
                        imagePath: 'assets/images/bottle_can.png',
                      ),
                      _AcceptedItemWithImage(
                        label: 'Tin cans',
                        imagePath: 'assets/images/can.png',
                      ),
                      _AcceptedItemWithImage(
                        label: 'Juice bottles',
                        imagePath: 'assets/images/bottle.png',
                      ),
                      _AcceptedItemWithImage(
                        label: 'Empty & uncrushed',
                        imagePath: 'assets/images/bottle_warning.png',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Where to find RVMs?
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Where to find RVMs?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.go(RoutePaths.map),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            child: const Text('View map'),
                          ),
                        ],
                      ),
                    ),
                    // Map preview
                    Image.asset(
                      'assets/images/map_pin.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // How to get rewards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'How to get rewards for recycling',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Step carousel
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return _StepCard(
                    number: step['number']!,
                    title: step['title']!,
                    description: step['description']!,
                    imagePath: step['image']!,
                  );
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentStep == index
                        ? AppColors.primary
                        : AppColors.textHint.withOpacity(0.3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AcceptedItemWithImage extends StatelessWidget {
  final String label;
  final String imagePath;

  const _AcceptedItemWithImage({required this.label, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imagePath,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final String imagePath;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Text(
                number,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              const Spacer(),
              Image.asset(
                imagePath,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
