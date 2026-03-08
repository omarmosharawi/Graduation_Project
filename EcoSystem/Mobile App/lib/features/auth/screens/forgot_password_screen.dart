// =============================================================================
// FORGOT PASSWORD SCREEN - Password Recovery Flow
// =============================================================================
// Multi-step password reset flow with custom painted background.
// Steps: Email → OTP → New Password → Success
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/widgets/auth_background.dart';
import '../../../core/utils/validation_utils.dart';
import 'dart:async';


/// ForgotPasswordScreen handles the multi-step password reset flow
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}



class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 0;
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Timer Variables
  Timer? _timer;
  int _start = 30;
  bool _canResend = false;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _start = 30;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  Future<void> _resendOtp() async {
    final authService = context.read<FirebaseAuthService>();
    final success = await authService.sendOtp(_emailController.text.trim());
    
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully! Check console for code.')),
      );
      _startTimer();
    } else {
      _showError(authService.error ?? 'Failed to resend OTP');
    }
  }

  Future<void> _nextStep() async {
    final authService = context.read<FirebaseAuthService>();

    switch (_currentStep) {
      case 0: // Email step
        final emailError = ValidationUtils.validateEmail(_emailController.text.trim());
        if (emailError != null) {
          _showError(emailError);
          return;
        }
        final success = await authService.sendOtp(_emailController.text.trim());
        
        if (!mounted) return;

        if (success) {
          setState(() {
            _currentStep = 1;
          });
          _startTimer();
        } else {
          _showError(authService.error ?? 'Failed to send OTP');
        }
        break;

      case 1: // OTP step
        if (_otpController.text.length != 6) {
          _showError('Please enter the complete 6-digit OTP');
          return;
        }
        final success = await authService.verifyOtp(
          _emailController.text.trim(),
          _otpController.text,
        );

        if (!mounted) return;

        if (success) {
          setState(() => _currentStep = 2);
          _timer?.cancel();
        } else {
          _showError(authService.error ?? 'Invalid OTP');
        }
        break;

      case 2: // New password step
        final passwordError = ValidationUtils.validateStrongPassword(_newPasswordController.text);
        if (passwordError != null) {
          _showError(passwordError);
          return;
        }
        final confirmError = ValidationUtils.validateConfirmPassword(
          _confirmPasswordController.text,
          _newPasswordController.text,
        );
        if (confirmError != null) {
          _showError(confirmError);
          return;
        }
        final success = await authService.resetPassword(
          _emailController.text.trim(),
          _newPasswordController.text,
        );

        if (!mounted) return;

        if (success) {
          setState(() => _currentStep = 3);
        } else {
          _showError(authService.error ?? 'Failed to reset password');
        }
        break;

      case 3: // Success step
        context.go(RoutePaths.login);
        break;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<FirebaseAuthService>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _currentStep < 2
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () {
                  if (_currentStep == 0) {
                    context.pop();
                  } else {
                    setState(() => _currentStep--);
                  }
                },
              ),
              title: Text(
                _currentStep == 0 ? 'Forgot Password' : 'Verify',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: _currentStep == 2
          ? _buildNewPasswordStep(authService)
          : _currentStep == 3
              ? _buildSuccessStep()
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _currentStep == 0
                        ? _buildEmailStep(authService)
                        : _buildOtpStep(authService),
                  ),
                ),
    );
  }

  Widget _buildEmailStep(FirebaseAuthService authService) {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_reset, size: 64, color: AppColors.primary),
              const SizedBox(height: 8),
              Text('Reset Password',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          "Don't worry! It happens. Please enter email associated with your account.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter your email',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: authService.isLoading ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: authService.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.textOnPrimary))
                : const Text('Send OTP',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnPrimary)),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep(FirebaseAuthService authService) {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user, size: 64, color: AppColors.primary),
              const SizedBox(height: 8),
              Text('Verification',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('Enter OTP',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('A 6 digit OTP has been sent',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        PinCodeTextField(
          appContext: context,
          length: 6,
          controller: _otpController,
          keyboardType: TextInputType.number,
          animationType: AnimationType.fade,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(12),
            fieldHeight: 56,
            fieldWidth: 48,
            activeFillColor: AppColors.background,
            inactiveFillColor: AppColors.background,
            selectedFillColor: AppColors.background,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            selectedColor: AppColors.primary,
          ),
          enableActiveFill: true,
          onChanged: (value) {},
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: authService.isLoading ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: authService.isLoading
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('Verify',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnPrimary)),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _canResend ? _resendOtp : null,
          child: Text(
            _canResend 
              ? 'Resend OTP' 
              : 'Resend OTP (00:${_start.toString().padLeft(2, '0')})',
            style: TextStyle(
              color: _canResend ? AppColors.primary : AppColors.textSecondary,
              fontWeight: _canResend ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep(FirebaseAuthService authService) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Column(
        children: [
          AuthBackground(
            height: screenHeight * 0.32,
            child: Stack(
              children: [
                Positioned(
                  top: 48,
                  left: 16,
                  child: IconButton(
                    onPressed: () => setState(() => _currentStep--),
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textOnPrimary),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Image.asset(
                      'assets/images/logo_text.png',
                      height: 40,
                      errorBuilder: (context, error, stackTrace) {
                        return RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                  text: 'RE',
                                  style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4A7C6F))),
                              TextSpan(
                                  text: 'ward',
                                  style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFD4A574))),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create New Password',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                const Text('Password',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textHint),
                      onPressed: () => setState(
                          () => _obscureNewPassword = !_obscureNewPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('must contain 8 characters.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                const Text('Confirm Password',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textHint),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authService.isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: authService.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.textOnPrimary))
                        : const Text('Reset password',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textOnPrimary)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  size: 60, color: AppColors.success),
            ),
            const SizedBox(height: 24),
            const Text('Password Changed!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Your password has been changed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Back to Login',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
