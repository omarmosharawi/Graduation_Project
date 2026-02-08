// =============================================================================
// PROFILE COMPLETION POPUP - Prompt user to complete profile & verify email
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../services/firebase_auth_service.dart';

/// Shows a popup if user needs to complete profile or verify email
class ProfileCompletionChecker extends StatefulWidget {
  final Widget child;

  const ProfileCompletionChecker({super.key, required this.child});

  @override
  State<ProfileCompletionChecker> createState() => _ProfileCompletionCheckerState();
}

class _ProfileCompletionCheckerState extends State<ProfileCompletionChecker> {
  bool _hasShownPopup = false;

  @override
  void initState() {
    super.initState();
    // Show popup after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowPopup();
    });
  }

  void _checkAndShowPopup() {
    if (_hasShownPopup) return;
    
    final authService = context.read<FirebaseAuthService>();
    
    // Skip if not logged in
    if (authService.currentUser == null) return;

    final isProfileIncomplete = authService.isProfileIncomplete;
    final needsEmailVerification = !authService.isGoogleUser && !authService.isEmailVerified;

    if (isProfileIncomplete || needsEmailVerification) {
      _hasShownPopup = true;
      _showCompletionPopup(
        isProfileIncomplete: isProfileIncomplete,
        needsEmailVerification: needsEmailVerification,
      );
    }
  }

  void _showCompletionPopup({
    required bool isProfileIncomplete,
    required bool needsEmailVerification,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProfileCompletionDialog(
        isProfileIncomplete: isProfileIncomplete,
        needsEmailVerification: needsEmailVerification,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ProfileCompletionDialog extends StatefulWidget {
  final bool isProfileIncomplete;
  final bool needsEmailVerification;

  const _ProfileCompletionDialog({
    required this.isProfileIncomplete,
    required this.needsEmailVerification,
  });

  @override
  State<_ProfileCompletionDialog> createState() => _ProfileCompletionDialogState();
}

class _ProfileCompletionDialogState extends State<_ProfileCompletionDialog> {
  bool _sendingEmail = false;
  bool _emailSent = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Complete Your Profile',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please complete the following to get the full REward experience:',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          
          if (widget.isProfileIncomplete)
            _buildCheckItem(
              icon: Icons.person_outline,
              text: 'Add your name and phone number',
              isComplete: false,
            ),
          
          if (widget.needsEmailVerification) ...[
            if (widget.isProfileIncomplete) const SizedBox(height: 12),
            _buildCheckItem(
              icon: Icons.email_outlined,
              text: _emailSent ? 'Verification email sent!' : 'Verify your email address',
              isComplete: _emailSent,
            ),
          ],
        ],
      ),
      actions: [
        // Close button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        
        // Verify email button
        if (widget.needsEmailVerification && !_emailSent)
          TextButton(
            onPressed: _sendingEmail ? null : _sendVerificationEmail,
            child: _sendingEmail
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send Verification'),
          ),
        
        // Complete profile button
        if (widget.isProfileIncomplete)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(RoutePaths.editProfile);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Complete Profile'),
          ),
      ],
    );
  }

  Widget _buildCheckItem({
    required IconData icon,
    required String text,
    required bool isComplete,
  }) {
    return Row(
      children: [
        Icon(
          isComplete ? Icons.check_circle : Icons.circle_outlined,
          color: isComplete ? AppColors.success : AppColors.textHint,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isComplete ? AppColors.success : AppColors.textPrimary,
              decoration: isComplete ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendVerificationEmail() async {
    setState(() => _sendingEmail = true);
    
    final authService = context.read<FirebaseAuthService>();
    final success = await authService.sendEmailVerification();
    
    if (mounted) {
      setState(() {
        _sendingEmail = false;
        _emailSent = success;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send verification email. Try again later.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
