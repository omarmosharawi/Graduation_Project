import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../core/models/pickup_request_model.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/pickup_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_picker_screen.dart';
import '../../../core/widgets/profile_completion_popup.dart';

class PickupRequestScreen extends StatefulWidget {
  const PickupRequestScreen({super.key});

  @override
  State<PickupRequestScreen> createState() => _PickupRequestScreenState();
}

class _PickupRequestScreenState extends State<PickupRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
  LatLng? _pickedLocation;
  bool _isSubmitting = false;
  final PickupService _pickupService = PickupService();

  // Selected materials and quantities
  final List<PickupItem> _selectedItems = [];
  final List<Map<String, dynamic>> _availableMaterials = [
    {'type': 'Plastic', 'icon': Icons.recycling, 'color': Colors.blue},
    {'type': 'Metal', 'icon': Icons.reorder, 'color': Colors.orange},
    {'type': 'Glass', 'icon': Icons.wine_bar, 'color': Colors.green},
    {'type': 'Others', 'icon': Icons.category, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    
    // Check if profile is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<FirebaseAuthService>();
      if (authService.isProfileIncomplete) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ProfileCompletionDialog(
            isProfileIncomplete: true,
            needsEmailVerification: !authService.isGoogleUser && !authService.isEmailVerified,
          ),
        ).then((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    });
  }
  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _updateQuantity(String type, int delta) {
    setState(() {
      final index = _selectedItems.indexWhere((item) => item.materialType == type);
      if (index != -1) {
        final newQuantity = _selectedItems[index].quantity + delta;
        if (newQuantity > 0) {
          _selectedItems[index] = PickupItem(materialType: type, quantity: newQuantity);
        } else {
          _selectedItems.removeAt(index);
        }
      } else if (delta > 0) {
        _selectedItems.add(PickupItem(materialType: type, quantity: delta));
      }
    });
  }

  int _getQuantity(String type) {
    final index = _selectedItems.indexWhere((item) => item.materialType == type);
    return index != -1 ? _selectedItems[index].quantity : 0;
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _pickLocation() async {
    final LatLng? result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(initialLocation: _pickedLocation),
      ),
    );

    if (result != null) {
      setState(() => _pickedLocation = result);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one material to recycle.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = context.read<FirebaseAuthService>().currentUser;
      if (user == null) return;

      final request = PickupRequest(
        id: '',
        userId: user.id,
        userName: user.name,
        address: _addressController.text,
        location: _pickedLocation != null ? GeoPoint(_pickedLocation!.latitude, _pickedLocation!.longitude) : null,
        scheduledTime: _selectedDate,
        items: List.from(_selectedItems),
      );

      final requestId = await _pickupService.createRequest(request);

      if (requestId != null && mounted) {
        _showSuccessDialog();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit request. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 64),
            SizedBox(height: 16),
            Text('Request Confirmed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A delegate has been assigned to your collection.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ETA: 30 - 45 mins',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Great!'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Pickup'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Home Collection Service',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Schedule a pickup and we\'ll collect your recyclables.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Pickup Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select the materials you want to recycle.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  
                  // Materials Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _availableMaterials.length,
                    itemBuilder: (context, index) {
                      final material = _availableMaterials[index];
                      final type = material['type'] as String;
                      final quantity = _getQuantity(type);
                      final isSelected = quantity > 0;
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected ? material['color'].withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? material['color'] : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(material['icon'], color: material['color'], size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  type,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? material['color'] : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () => _updateQuantity(type, -1),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.remove, size: 16),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    '$quantity',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _updateQuantity(type, 1),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: material['color'].withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.add, size: 16, color: material['color']),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    '2. Pickup Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Collection Address',
                      hintText: 'Unit number, street, complex name',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 2,
                    validator: (val) => val == null || val.isEmpty ? 'Please enter your address' : null,
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: _selectDateTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Scheduled Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  DateFormat('EEEE, MMM d @ h:mm a').format(_selectedDate),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: _pickLocation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _pickedLocation != null ? AppColors.primary : Colors.grey,
                          width: _pickedLocation != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _pickedLocation != null ? AppColors.primary.withOpacity(0.05) : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.map_outlined,
                            color: _pickedLocation != null ? AppColors.primary : AppColors.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pickup Location', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  _pickedLocation != null
                                      ? 'Location pinned on map ✓'
                                      : 'Set location on map (Optional)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: _pickedLocation != null ? FontWeight.bold : FontWeight.w600,
                                    color: _pickedLocation != null ? AppColors.primary : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_pickedLocation != null)
                            const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                          else
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Confirm Collection',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Our delegate will arrive within the scheduled window.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
