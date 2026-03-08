// =============================================================================
// ADMIN DASHBOARD SCREEN - Manage Offers and Users
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/offers_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/home_service.dart';
import '../../../core/services/kiosk_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/models/home_card_model.dart';
import '../../esp32/screens/ble_config_screen.dart';
import '../../../core/models/pickup_request_model.dart';
import '../../../core/services/pickup_service.dart';
import 'package:intl/intl.dart';

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
  final KioskService _kioskService = KioskService();
  final PickupService _pickupService = PickupService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white,
              labelPadding: EdgeInsets.zero,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(child: Text('Offers', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                Tab(child: Text('Cards', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                Tab(child: Text('Kiosks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                Tab(child: Text('Pickups', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                Tab(child: Text('Stats', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OffersManagement(offersService: _offersService),
          _HomeCardsManagement(homeService: _homeService),
          _KiosksManagement(kioskService: _kioskService),
          _PickupManagement(pickupService: _pickupService),
          const _StatsView(),
        ],
      ),
      floatingActionButton: _tabController.index < 3
          ? FloatingActionButton(
              onPressed: () {
                if (_tabController.index == 0) {
                  _showAddOfferDialog(context);
                } else if (_tabController.index == 1) {
                  _showAddHomeCardDialog(context);
                } else if (_tabController.index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BleConfigScreen()),
                  );
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
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
    final actionValueController = TextEditingController(text: card?.actionValue ?? '');
    String selectedType = card?.type ?? 'promo';
    String selectedActionType = card?.actionType ?? 'none';
    bool isActive = card?.isActive ?? true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                card == null ? Icons.add_circle : Icons.edit,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Text(card == null ? 'Add Home Card' : 'Edit Home Card'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Component Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'analytics', child: Text('Analytics Chart')),
                      DropdownMenuItem(value: 'promo', child: Text('Promo Card')),
                    ],
                    onChanged: (val) {
                      setDialogState(() => selectedType = val ?? 'promo');
                    },
                  ),
                  if (selectedType == 'promo') ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. Current Impact or Recycle Now',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Brief text details...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: imageController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        hintText: 'https://...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.image),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: selectedActionType,
                      decoration: const InputDecoration(
                        labelText: 'Click Action',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.touch_app),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'none', child: Text('No Action')),
                        DropdownMenuItem(value: 'offer', child: Text('Go to Offer')),
                        DropdownMenuItem(value: 'url', child: Text('Open Web Link')),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedActionType = val ?? 'none');
                      },
                    ),
                    const SizedBox(height: 20),
                    if (selectedActionType == 'offer')
                      StreamBuilder<List<Offer>>(
                        stream: _offersService.getOffersStream(),
                        builder: (context, snapshot) {
                          final offers = snapshot.data ?? [];
                          final selectedOffer = offers.cast<Offer?>().firstWhere(
                            (o) => o?.id == actionValueController.text,
                            orElse: () => null,
                          );

                          return InkWell(
                            onTap: () async {
                              final result = await _showSearchableOfferDialog(context, offers);
                              if (result != null) {
                                setDialogState(() => actionValueController.text = result.id);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_offer, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      selectedOffer != null
                                          ? '[${selectedOffer.category}] ${selectedOffer.partner}: ${selectedOffer.title}'
                                          : 'Tap to Search & Select Offer...',
                                      style: TextStyle(
                                        color: selectedOffer != null ? Colors.black : Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.search, color: AppColors.primary),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    else
                      TextField(
                        controller: actionValueController,
                        decoration: InputDecoration(
                          labelText: selectedActionType == 'url' ? 'Web URL' : 'Action Value',
                          hintText: selectedActionType == 'url' ? 'https://...' : 'ID or URL...',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.link),
                        ),
                      ),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    controller: priorityController,
                    decoration: const InputDecoration(
                      labelText: 'Priority Index',
                      hintText: 'Higher values appear first',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sort),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SwitchListTile(
                      title: const Text('Visible to Users'),
                      subtitle: Text(isActive ? 'Currently Active' : 'Hidden'),
                      value: isActive,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            SizedBox(
              width: 140,
              child: ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (selectedType == 'promo' && titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a title for the promo card')),
                    );
                    return;
                  }

                  setDialogState(() => isSaving = true);
                  
                  try {
                    final newCard = HomeCard(
                      id: card?.id ?? '',
                      type: selectedType,
                      title: selectedType == 'analytics' ? null : titleController.text,
                      description: descController.text.isEmpty ? null : descController.text,
                      imageUrl: imageController.text.isEmpty ? null : imageController.text,
                      isActive: isActive,
                      priority: int.tryParse(priorityController.text) ?? 0,
                      actionType: selectedActionType,
                      actionValue: actionValueController.text.isEmpty ? null : actionValueController.text,
                    );

                    if (card == null) {
                      await _homeService.addHomeCard(newCard);
                    } else {
                      await _homeService.updateHomeCard(newCard);
                    }
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(card == null ? 'Card created successfully' : 'Card updated successfully')),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSaving 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(card == null ? 'Create' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Offer?> _showSearchableOfferDialog(BuildContext context, List<Offer> offers) {
    String searchQuery = '';
    
    return showDialog<Offer>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredOffers = offers.where((offer) {
            final searchLower = searchQuery.toLowerCase();
            return offer.title.toLowerCase().contains(searchLower) ||
                   offer.partner.toLowerCase().contains(searchLower) ||
                   offer.category.toLowerCase().contains(searchLower);
          }).toList();

          return AlertDialog(
            title: const Text('Select Offer'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search Offers',
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Type partner, title, or category...',
                    ),
                    onChanged: (val) {
                      setDialogState(() => searchQuery = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SizedBox(
                      height: 400,
                      child: filteredOffers.isEmpty
                        ? const Center(child: Text('No matching offers found'))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredOffers.length,
                            itemBuilder: (context, index) {
                              final offer = filteredOffers[index];
                              return ListTile(
                                leading: const Icon(Icons.local_offer, color: AppColors.primary),
                                title: Text(offer.title),
                                subtitle: Text('${offer.partner} • ${offer.category}'),
                                trailing: Text('${offer.pointsRequired} pts'),
                                onTap: () => Navigator.pop(context, offer),
                              );
                            },
                          ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showOfferDialog(BuildContext context, Offer? offer) {
    final titleController = TextEditingController(text: offer?.title ?? '');
    final descController = TextEditingController(text: offer?.description ?? '');
    final partnerController = TextEditingController(text: offer?.partner ?? '');
    final pointsController = TextEditingController(text: offer?.pointsRequired.toString() ?? '');
    final imageController = TextEditingController(text: offer?.imageUrl ?? '');
    String selectedCategory = offer?.category ?? 'Groceries';
    bool isActive = offer?.isActive ?? true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                offer == null ? Icons.add_circle : Icons.edit,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Text(offer == null ? 'Add New Offer' : 'Edit Offer'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: partnerController,
                    decoration: const InputDecoration(
                      labelText: 'Partner / Brand Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: pointsController,
                    decoration: const InputDecoration(
                      labelText: 'Points Required',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.stars),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: imageController,
                    decoration: const InputDecoration(
                      labelText: 'Image URL',
                      hintText: 'https://...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    menuMaxHeight: 300,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _offersService.getCategories().map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedCategory = val ?? 'Groceries');
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SwitchListTile(
                      title: const Text('Is Active'),
                      subtitle: Text(isActive ? 'Visible to users' : 'Hidden from users'),
                      value: isActive,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            SizedBox(
              width: 140,
              child: ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (titleController.text.isEmpty || pointsController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in title and points')),
                    );
                    return;
                  }

                  setDialogState(() => isSaving = true);

                  try {
                    if (offer == null) {
                      final newOffer = Offer(
                        id: '',
                        title: titleController.text,
                        description: descController.text,
                        partner: partnerController.text,
                        category: selectedCategory,
                        pointsRequired: int.tryParse(pointsController.text) ?? 0,
                        imageUrl: imageController.text.isEmpty ? null : imageController.text,
                        isActive: true,
                      );
                      await _offersService.createOffer(newOffer);
                    } else {
                      await _offersService.updateOffer(offer.id, {
                        'title': titleController.text,
                        'description': descController.text,
                        'partner': partnerController.text,
                        'category': selectedCategory,
                        'pointsRequired': int.tryParse(pointsController.text) ?? 0,
                        'imageUrl': imageController.text.isEmpty ? null : imageController.text,
                        'isActive': isActive,
                      });
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(offer == null ? 'Offer created' : 'Offer updated')),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(offer == null ? 'Create' : 'Save'),
              ),
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
                    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collectionGroup('coupons').snapshots(),
                builder: (context, snapshot) {
                  final couponCount = snapshot.data?.docs.length ?? 0;
                  return _StatCard(
                    title: 'Coupons Redeemed',
                    value: couponCount.toString(),
                    icon: Icons.card_giftcard,
                    color: AppColors.success,
                  );
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
                builder: (context, snapshot) {
                  int totalItems = 0;
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      totalItems += (data['plasticCount'] as int? ?? 0) + (data['metalCount'] as int? ?? 0);
                    }
                  }
                  return _StatCard(
                    title: 'Total Recycled',
                    value: totalItems.toString(),
                    icon: Icons.recycling,
                    color: const Color(0xFF4CAF50),
                  );
                },
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: const Text('Send Announcement'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
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

              // Trigger push notification to all users
              try {
                await NotificationService().sendPushToTopic(
                  topic: 'all_users',
                  title: '📢 ${titleController.text}',
                  body: messageController.text,
                );
              } catch (e) {
                AppLogger.error('Failed to trigger announcement push: $e');
              }
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
      stream: homeService.getAdminHomeCardsStream(),
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
                    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                        card.title ?? (card.type == 'analytics' ? 'Analytics Chart' : 'No Title'),
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

// =============================================================================
// KIOSKS MANAGEMENT TAB
// =============================================================================
class _KiosksManagement extends StatelessWidget {
  final KioskService kioskService;

  const _KiosksManagement({required this.kioskService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Kiosk>>(
      stream: kioskService.getKiosksStream(includeInactive: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final kiosks = snapshot.data ?? [];

        if (kiosks.isEmpty) {
          return const Center(child: Text('No kiosks registered.'));
        }

        // Count alert kiosks
        final alertKiosks = kiosks.where((k) => !k.isOperational).toList();

        return Column(
          children: [
            // Alert banner
            if (alertKiosks.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${alertKiosks.length} kiosk(s) need attention',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            title: const Text('Cleanup Kiosks?'),
                            content: const Text('This will set all kiosks except "kiosk_01" to OFFLINE.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Disable Others', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await kioskService.disableAllOthers('kiosk_01');
                        }
                      },
                      child: Text('Fix All', style: TextStyle(color: Colors.red.shade700)),
                    ),
                  ],
                ),
              ),
            // BLE Configuration Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BleConfigScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bluetooth, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Configure Kiosk via Bluetooth',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Set WiFi, Kiosk ID & API key wirelessly',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: kiosks.length,
                itemBuilder: (context, index) {
                  final kiosk = kiosks[index];
                  return _KioskAdminCard(
                    kiosk: kiosk,
                    onEdit: () => _showEditKioskDialog(context, kiosk),
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          title: const Text('Delete Kiosk?'),
                          content: Text('Delete "${kiosk.name}"? This action cannot be undone.'),
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
                        await kioskService.deleteKiosk(kiosk.id);
                      }
                    },
                    onEmpty: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          title: const Text('Empty Machine?'),
                          content: Text('Reset "${kiosk.name}" capacity to zero? This will also mark it as available.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Empty', style: TextStyle(color: AppColors.primary)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await kioskService.emptyKiosk(kiosk.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${kiosk.name} emptied.')),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditKioskDialog(BuildContext context, Kiosk kiosk) {
    String selectedStatus = kiosk.status;
    final maxCapController = TextEditingController(text: kiosk.maxCapacity.toString());
    final latController = TextEditingController(text: kiosk.latitude.toString());
    final lngController = TextEditingController(text: kiosk.longitude.toString());
    final statuses = ['available', 'maintenance', 'offline', 'full', 'out_of_service'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: Text('Edit: ${kiosk.name}'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: statuses.map((s) {
                      return DropdownMenuItem(value: s, child: Text(_statusLabel(s)));
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedStatus = val ?? 'available');
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: maxCapController,
                    decoration: const InputDecoration(labelText: 'Max Capacity'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latController,
                          decoration: const InputDecoration(labelText: 'Latitude'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: lngController,
                          decoration: const InputDecoration(labelText: 'Longitude'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Quick info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current: ${kiosk.currentCapacity}/${kiosk.maxCapacity} items',
                            style: const TextStyle(fontSize: 13)),
                        Text('Plastic: ${kiosk.plasticCount} | Metal: ${kiosk.metalCount}',
                            style: const TextStyle(fontSize: 13)),
                        if (kiosk.lastUpdated != null)
                          Text(
                            'Last update: ${_formatDate(kiosk.lastUpdated!)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updates = <String, dynamic>{
                  'status': selectedStatus,
                  'maxCapacity': int.tryParse(maxCapController.text) ?? kiosk.maxCapacity,
                  'latitude': double.tryParse(latController.text) ?? kiosk.latitude,
                  'longitude': double.tryParse(lngController.text) ?? kiosk.longitude,
                  'lastUpdated': FieldValue.serverTimestamp(),
                };
                await kioskService.updateKiosk(kiosk.id, updates);
                // Notify admins if status changed to a problem state
                if (selectedStatus != kiosk.status) {
                  await kioskService.notifyAdminsOnStatusChange(
                    kiosk.id, kiosk.name, selectedStatus,
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available': return 'Available';
      case 'maintenance': return 'Under Maintenance';
      case 'offline': return 'Offline';
      case 'full': return 'Full';
      case 'out_of_service': return 'Out of Service';
      default: return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _KioskAdminCard extends StatelessWidget {
  final Kiosk kiosk;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onEmpty;

  const _KioskAdminCard({
    required this.kiosk,
    required this.onEdit,
    required this.onDelete,
    required this.onEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: kiosk.isOperational
            ? null
            : Border.all(color: kiosk.statusColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Status icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: kiosk.statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _statusIcon(kiosk.status),
                    color: kiosk.statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kiosk.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Machine ID: ${kiosk.id}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kiosk.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              kiosk.statusDisplay,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: kiosk.statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${kiosk.currentCapacity}/${kiosk.maxCapacity}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Capacity bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: kiosk.capacityPercent,
                          minHeight: 4,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            kiosk.capacityPercent > 0.9
                                ? Colors.red
                                : kiosk.capacityPercent > 0.7
                                    ? Colors.amber
                                    : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit and Delete
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cleaning_services_outlined, color: Colors.blue, size: 20),
                      onPressed: onEmpty,
                      tooltip: 'Empty machine',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Edit',
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'available': return Icons.check_circle;
      case 'full': return Icons.inventory;
      case 'maintenance': return Icons.build;
      case 'offline': return Icons.cloud_off;
      case 'out_of_service': return Icons.error;
      default: return Icons.help;
    }
  }
}

// =============================================================================
// PICKUP MANAGEMENT TAB
// =============================================================================
class _PickupManagement extends StatelessWidget {
  final PickupService pickupService;

  const _PickupManagement({required this.pickupService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PickupRequest>>(
      stream: pickupService.getAllRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No pickup requests yet.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _PickupAdminCard(
              request: request,
              onUpdate: (status, eta) async {
                await pickupService.updateRequestStatus(request.id, status, eta: eta);
              },
            );
          },
        );
      },
    );
  }
}

class _PickupAdminCard extends StatelessWidget {
  final PickupRequest request;
  final Function(PickupStatus, String?) onUpdate;

  const _PickupAdminCard({
    required this.request,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(request.status);

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(request.status),
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Requested ${DateFormat('MMM d, h:mm a').format(request.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.address,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Scheduled: ${DateFormat('EEEE, MMM d @ h:mm a').format(request.scheduledTime)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (request.location != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.pin_drop_outlined, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text(
                    'Coordinates: ${request.location!.latitude.toStringAsFixed(4)}, ${request.location!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            if (request.eta != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'ETA: ${request.eta}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (request.status == PickupStatus.pending)
                  ElevatedButton.icon(
                    onPressed: () => _showConfirmDialog(context),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                if (request.status == PickupStatus.confirmed)
                  ElevatedButton.icon(
                    onPressed: () => onUpdate(PickupStatus.completed, null),
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                const SizedBox(width: 8),
                if (request.status != PickupStatus.cancelled && request.status != PickupStatus.completed)
                  OutlinedButton.icon(
                    onPressed: () => onUpdate(PickupStatus.cancelled, null),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    final etaController = TextEditingController(text: '30-45 mins');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Pickup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter estimated time of arrival for the user:'),
            const SizedBox(height: 16),
            TextField(
              controller: etaController,
              decoration: const InputDecoration(
                labelText: 'ETA',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onUpdate(PickupStatus.confirmed, etaController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PickupStatus status) {
    switch (status) {
      case PickupStatus.pending: return Colors.orange;
      case PickupStatus.confirmed: return AppColors.primary;
      case PickupStatus.onWay: return AppColors.secondary;
      case PickupStatus.completed: return AppColors.success;
      case PickupStatus.cancelled: return Colors.red;
    }
  }

  IconData _getStatusIcon(PickupStatus status) {
    switch (status) {
      case PickupStatus.pending: return Icons.pending_actions;
      case PickupStatus.confirmed: return Icons.local_shipping;
      case PickupStatus.onWay: return Icons.delivery_dining;
      case PickupStatus.completed: return Icons.check_circle;
      case PickupStatus.cancelled: return Icons.cancel;
    }
  }
}
