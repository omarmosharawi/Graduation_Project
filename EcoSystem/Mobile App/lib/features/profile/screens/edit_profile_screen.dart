// =============================================================================
// EDIT PROFILE SCREEN - Profile Settings
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authService = context.read<FirebaseAuthService>();
    final user = authService.currentUser;
    
    // Refresh email verification status from Firebase
    authService.refreshEmailVerificationStatus();
    
    // Split name into first and last
    final nameParts = (user?.name ?? '').split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    
    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<FirebaseAuthService>();
    final user = authService.currentUser;
    final isGoogleUser = user?.avatarUrl?.contains('google') ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile settings'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    backgroundImage: user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!)
                        : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Change profile picture',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Name Fields
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email (read-only for Google users)
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                readOnly: isGoogleUser,
                suffixIcon: isGoogleUser
                    ? const Icon(Icons.lock, size: 18, color: AppColors.textHint)
                    : null,
              ),
              
              // Email verification status (for email/password users)
              if (!authService.isGoogleUser) ...[
                const SizedBox(height: 8),
                _buildEmailVerificationCard(authService),
              ],
              
              const SizedBox(height: 16),

              // Phone
              _buildTextField(
                controller: _phoneController,
                label: 'Phone number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Address
              _buildTextField(
                controller: _addressController,
                label: 'Full Address',
              ),
              const SizedBox(height: 16),

              // Password (only for non-Google users)
              if (!isGoogleUser)
                _buildTextField(
                  label: 'Password',
                  readOnly: true,
                  obscureText: true,
                  initialValue: '••••••••',
                  suffixIcon: TextButton(
                    onPressed: () {
                      // Navigate to change password
                    },
                    child: const Text('Change'),
                  ),
                ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? label,
    bool readOnly = false,
    bool obscureText = false,
    String? initialValue,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildEmailVerificationCard(FirebaseAuthService authService) {
    final isVerified = authService.isEmailVerified;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.success.withOpacity(0.1)
            : AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified
              ? AppColors.success.withOpacity(0.3)
              : AppColors.secondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.warning_amber_rounded,
            color: isVerified ? AppColors.success : AppColors.secondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isVerified ? 'Email verified' : 'Email not verified',
              style: TextStyle(
                color: isVerified ? AppColors.success : AppColors.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!isVerified)
            TextButton(
              onPressed: _sendVerificationEmail,
              child: const Text('Verify Now'),
            ),
        ],
      ),
    );
  }

  Future<void> _sendVerificationEmail() async {
    final authService = context.read<FirebaseAuthService>();
    final success = await authService.sendEmailVerification();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Verification email sent! Check your inbox.'
                : 'Failed to send email. Try again later.',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<FirebaseAuthService>();
      final fullName = '${_firstNameController.text} ${_lastNameController.text}'.trim();
      
      await authService.updateUserProfile(
        name: fullName,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
