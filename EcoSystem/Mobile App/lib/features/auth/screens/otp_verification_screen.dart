// =============================================================================
// OTP VERIFICATION SCREEN - 6-Digit Code Verification After Signup
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/widgets/auth_background.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _canResend = false;
  int _resendCountdown = 60;
  Timer? _timer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Send OTP immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOtp();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final authService = context.read<FirebaseAuthService>();
    await authService.sendOtp(widget.email);
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() => _errorMessage = null);
    await _sendOtp();
    _startResendTimer();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New OTP sent! Check console log.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  String get _enteredOtp =>
      _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final otp = _enteredOtp;
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final authService = context.read<FirebaseAuthService>();
    final success = await authService.verifyOtp(widget.email, otp);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified successfully! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(RoutePaths.home);
    } else {
      setState(() {
        _isVerifying = false;
        _errorMessage = authService.error ?? 'Invalid OTP. Try again.';
      });
      // Clear fields on error
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  void _onDigitChanged(int index, String value) {
    // Handle paste: if user pastes a full code, distribute across all fields
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 1) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = i < digitsOnly.length ? digitsOnly[i] : '';
      }
      if (digitsOnly.length >= 6) {
        _focusNodes[5].requestFocus();
        _verifyOtp();
      } else {
        final nextIndex = digitsOnly.length.clamp(0, 5);
        _focusNodes[nextIndex].requestFocus();
      }
      setState(() => _errorMessage = null);
      return;
    }

    // Single character: truncate to 1 digit only
    if (digitsOnly.length == 1) {
      _controllers[index].text = digitsOnly;
      _controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: 1),
      );
      if (index < 5) _focusNodes[index + 1].requestFocus();
    } else if (digitsOnly.isEmpty) {
      _controllers[index].text = '';
    }

    // Auto-submit when all 6 digits are entered
    if (_enteredOtp.length == 6) {
      _verifyOtp();
    }
    setState(() => _errorMessage = null);
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            AuthBackground(
              height: screenHeight * 0.22,
              child: Stack(
                children: [
                  Positioned(
                    top: 48,
                    left: 16,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Image.asset(
                        'assets/images/logo_text.png',
                        height: 38,
                        errorBuilder: (context, error, stackTrace) {
                          return RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'RE',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF4A7C6F),
                                  ),
                                ),
                                TextSpan(
                                  text: 'ward',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFD4A574),
                                  ),
                                ),
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

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit code to',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 50,
                        height: 60,
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (event) => _onKeyEvent(index, event),
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.0,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 0,
                              ),
                              filled: true,
                              fillColor: _errorMessage != null
                                  ? AppColors.error.withOpacity(0.05)
                                  : AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _errorMessage != null
                                      ? AppColors.error
                                      : Colors.transparent,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _errorMessage != null
                                      ? AppColors.error
                                      : AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) => _onDigitChanged(index, value),
                          ),
                        ),
                      );
                    }),
                  ),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isVerifying ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textOnPrimary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Resend OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code? ",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: _canResend ? _resendOtp : null,
                        child: Text(
                          _canResend
                              ? 'Resend'
                              : 'Resend in ${_resendCountdown}s',
                          style: TextStyle(
                            color: _canResend
                                ? AppColors.primary
                                : AppColors.textHint,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  // Skip for now
                  TextButton(
                    onPressed: () => context.go(RoutePaths.home),
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 13,
                      ),
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
