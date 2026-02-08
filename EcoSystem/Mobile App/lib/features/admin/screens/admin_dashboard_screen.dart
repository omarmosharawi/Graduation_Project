// =============================================================================
// ADMIN DASHBOARD SCREEN - Manage Offers and Users
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/offers_service.dart';
import '../../../core/services/home_service.dart';
import '../../../core/models/home_card_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OffersService _offersService = OffersService();
  final HomeService _homeService = HomeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<FirebaseAuthService>();
    final isAdmin = authService.currentUser?.isAdmin ?? false;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Access Denied', style: TextStyle(fontSize: 24)),
              SizedBox(height: 8),
              Text('You need admin privileges to access this page.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Offers'),
            Tab(text: 'Home Cards'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OffersManagement(offersService: _offersService),
          _HomeCardsManagement(homeService: _homeService),
          const _StatsView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddOfferDialog(context);
          } else if (_tabController.index == 1) {
            _showAddHomeCardDialog(context);
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddOfferDialog(BuildContext context) {
    _showOfferDialog(context, null);
  }

  void _showAddHomeCardDialog(BuildContext context) {
    _showHomeCardDialog(context, null);
  }

  void _showHomeCardDialog(BuildContext context, HomeCard? card) {
    final titleController = TextEditingController(text: card?.title ?? '');
    final descController = TextEditingController(text: card?.description ?? '');
    final imageController = TextEditingController(text: card?.imageUrl ?? '');
    final priorityController = TextEditingController(text: card?.priority.toString() ?? '0');
    String selectedType = card?.type ?? 'promo';
    bool isActive = card?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(card == null ? 'Add Home Card' : 'Edit Home Card'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'analytics', child: Text('Analytics Chart')),
                    DropdownMenuItem(value: 'promo', child: Text('Promo Card')),
                  ],
                  onChanged: (val) {
                    setDialogState(() => selectedType = val ?? 'promo');
                  },
                ),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                if (selectedType == 'promo') ...[
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  TextField(
                    controller: imageController,
                    decoration: const InputDecoration(labelText: 'Image URL'),
                  ),
                ],
                TextField(
                  controller: priorityController,
                  decoration: const InputDecoration(labelText: 'Priority (Higher shows first)'),
                  keyboardType: TextInputType.number,
                ),
                if (card != null) ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newCard = HomeCard(
                  id: card?.id ?? '',
                  type: selectedType,
                  title: titleController.text,
                  description: descController.text.isEmpty ? null : descController.text,
                  imageUrl: imageController.text.isEmpty ? null : imageController.text,
                  isActive: isActive,
                  priority: int.tryParse(priorityController.text) ?? 0,
                );

                if (card == null) {
                  await _homeService.addHomeCard(newCard);
                } else {
                  await _homeService.updateHomeCard(newCard);
                }
                
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(card == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOfferDialog(BuildContext context, Offer? offer) {
    final titleController = TextEditingController(text: offer?.title ?? '');
    final descController = TextEditingController(text: offer?.description ?? '');
    final partnerController = TextEditingController(text: offer?.partner ?? '');
    final pointsController = TextEditingController(text: offer?.pointsRequired.toString() ?? '');
    String selectedCategory = offer?.category ?? 'Groceries';
    bool isActive = offer?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(offer == null ? 'Add New Offer' : 'Edit Offer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                TextField(
                  controller: partnerController,
                  decoration: const InputDecoration(labelText: 'Partner'),
                ),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(labelText: 'Points Required'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _offersService.getCategories().map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedCategory = val ?? 'Groceries');
                  },
                ),
                if (offer != null) ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (offer == null) {
                  // Create new offer
                  final newOffer = Offer(
                    id: '',
                    title: titleController.text,
                    description: descController.text,
                    partner: partnerController.text,
                    category: selectedCategory,
                    pointsRequired: int.tryParse(pointsController.text) ?? 0,
                    isActive: true,
                  );
                  await _offersService.createOffer(newOffer);
                } else {
                  // Update existing offer
                  await _offersService.updateOffer(offer.id, {
                    'title': titleController.text,
                    'description': descController.text,
                    'partner': partnerController.text,
                    'category': selectedCategory,
                    'pointsRequired': int.tryParse(pointsController.text) ?? 0,
                    'isActive': isActive,
                  });
                }
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(offer == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

}
class _OffersManagement extends StatelessWidget {
  final OffersService offersService;

  const _OffersManagement({required this.offersService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Offer>>(
      stream: offersService.getAllOffersForAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final offers = snapshot.data ?? [];

        if (offers.isEmpty) {
          return const Center(
            child: Text('No offers yet. Tap + to add one.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            return _OfferAdminCard(
              offer: offer,
              onEdit: () {
                // Get parent state to call dialog
                final state = context.findAncestorStateOfType<_AdminDashboardScreenState>();
                state?._showOfferDialog(context, offer);
              },
              onToggle: () async {
                await offersService.updateOffer(
                  offer.id,
                  {'isActive': !offer.isActive},
                );
              },
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Offer?'),
                    content: Text('Delete "${offer.title}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await offersService.deleteOffer(offer.id);
                }
              },
            );
          },
        );
      },
    );
  }
}

class _OfferAdminCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _OfferAdminCard({
    required this.offer,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: offer.isActive
                        ? AppColors.success.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    offer.isActive ? Icons.check_circle : Icons.cancel,
                    color: offer.isActive ? AppColors.success : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${offer.partner} • ${offer.pointsRequired} pts',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          offer.category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        offer.isActive ? Icons.visibility : Icons.visibility_off,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      onPressed: onToggle,
                      tooltip: offer.isActive ? 'Deactivate' : 'Activate',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  final userCount = snapshot.data?.docs.length ?? 0;
                  return _StatCard(
                    title: 'Total Users',
                    value: userCount.toString(),
                    icon: Icons.people,
                    color: AppColors.primary,
                  );
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('offers')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  final offerCount = snapshot.data?.docs.length ?? 0;
                  return _StatCard(
                    title: 'Active Offers',
                    value: offerCount.toString(),
                    icon: Icons.local_offer,
                    color: AppColors.secondary,
                  );
                },
              ),
              const _StatCard(
                title: 'Coupons Redeemed',
                value: '124', // Mock data for now, would need real tracking
                icon: Icons.card_giftcard,
                color: AppColors.success,
              ),
              const _StatCard(
                title: 'Total Recycled',
                value: '856', // Mock data
                icon: Icons.recycling,
                color: Color(0xFF4CAF50),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: AppColors.primary.withOpacity(0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notification_add, color: AppColors.primary),
              ),
              title: const Text(
                'Send Announcement',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Notify all users about new updates'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
              onTap: () => _showAnnouncementDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Announcement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., New Offer Available!',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Enter your announcement message...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || messageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              // Save announcement to Firestore
              await FirebaseFirestore.instance.collection('announcements').add({
                'title': titleController.text,
                'message': messageController.text,
                'createdAt': FieldValue.serverTimestamp(),
                'isGlobal': true,
              });

              // Assuming NotificationService can listen to this or we trigger it via Cloud Function
              // For demo, we just show success
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Announcement sent to all users!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCardsManagement extends StatelessWidget {
  final HomeService homeService;

  const _HomeCardsManagement({required this.homeService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HomeCard>>(
      stream: homeService.getHomeCardsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final cards = snapshot.data ?? [];

        if (cards.isEmpty) {
          return const Center(
            child: Text('No home cards yet. Tap + to add one.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return _HomeCardAdminWidget(
              card: card,
              onEdit: () {
                 final state = context.findAncestorStateOfType<_AdminDashboardScreenState>();
                 state?._showHomeCardDialog(context, card);
              },
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Card?'),
                    content: Text('Delete "${card.title}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await homeService.deleteHomeCard(card.id);
                }
              },
            );
          },
        );
      },
    );
  }
}

class _HomeCardAdminWidget extends StatelessWidget {
  final HomeCard card;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HomeCardAdminWidget({
    required this.card,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: card.type == 'analytics'
                        ? AppColors.secondary.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    card.type == 'analytics' ? Icons.analytics : Icons.image,
                    color: card.type == 'analytics' ? AppColors.secondary : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: card.isActive ? AppColors.success.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              card.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: card.isActive ? AppColors.success : Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Priority: ${card.priority}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
