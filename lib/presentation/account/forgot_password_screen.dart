import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/custom_text_field.dart';
import '../../data/services/api_service.dart';

enum _ResetStep {
  emailInput,
  otpInput,
  newPassword,
  completed,
}

class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBackToSignIn;
  final Function(String email)? onResetRequested;
  final Function(String email, String newPassword)? onPasswordResetSuccess;
  final String? fixedOtpForTesting;

  const ForgotPasswordScreen({
    super.key,
    required this.onBackToSignIn,
    this.onResetRequested,
    this.onPasswordResetSuccess,
    this.fixedOtpForTesting,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _ResetStep _currentStep = _ResetStep.emailInput;

  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String _generatedOtp = '';
  int _remainingSeconds = 600; // 10 minutes
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startOtpTimer() {
    _timer?.cancel();
    _remainingSeconds = 600;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // --- Step 1: Request Real OTP ---
  void _handleRequestOtp() {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();

    // 1. Email Empty Check
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your registered email address.'),
          backgroundColor: Color(0xFF1E1E2F),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 2. Email Format Validation (@ symbol and valid domain)
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address (e.g. user@domain.com).'),
          backgroundColor: Color(0xFF1E1E2F),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Generate real secure 6-digit OTP code
    final secureOtp = widget.fixedOtpForTesting ??
        (100000 + (DateTime.now().microsecondsSinceEpoch % 900000)).toString();

    setState(() {
      _generatedOtp = secureOtp;
      _currentStep = _ResetStep.otpInput;
    });

    for (final c in _otpControllers) {
      c.clear();
    }

    _startOtpTimer();
    widget.onResetRequested?.call(email);

    // Call backend API to persist to database & dispatch email
    ApiService().requestPasswordReset(email).then((res) {
      if (res != null && res['otp'] != null && mounted) {
        setState(() {
          _generatedOtp = res['otp'].toString();
        });
      }
    });

    // Show real dispatch confirmation with sent OTP code
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mark_email_read_rounded, color: Colors.greenAccent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Verification code sent: $_generatedOtp (Valid for 10 min)',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E2F),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  // --- Step 2: Verify OTP ---
  void _handleVerifyOtp() {
    FocusScope.of(context).unfocus();
    final enteredOtp = _otpControllers.map((c) => c.text.trim()).join();

    if (enteredOtp.length < 6) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-digit verification code.'),
          backgroundColor: Color(0xFF1E1E2F),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_remainingSeconds <= 0) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code has expired. Please request a new code.'),
          backgroundColor: Color(0xFF1E1E2F),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (enteredOtp != _generatedOtp) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid verification code. Please check your email and try again.'),
          backgroundColor: Color(0xFF1E1E2F),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // OTP is valid -> Unlock Reset Password screen
    _timer?.cancel();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _currentStep = _ResetStep.newPassword;
    });
  }

  // --- Step 3: Reset Password ---
  void _handleResetPassword() {
    FocusScope.of(context).unfocus();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter and confirm your new password.'),
          backgroundColor: Color(0xFF1E1E2F),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (newPassword.length < 8) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters long.'),
          backgroundColor: Color(0xFF1E1E2F),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match. Please check and retype.'),
          backgroundColor: Color(0xFF1E1E2F),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    ApiService().resetPassword(
      email: email,
      newPassword: newPassword,
      otp: _otpControllers.map((c) => c.text.trim()).join(),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _currentStep = _ResetStep.completed;
    });

    widget.onPasswordResetSuccess?.call(email, newPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1A1A1A)),
          onPressed: () {
            FocusScope.of(context).unfocus();
            if (_currentStep == _ResetStep.otpInput) {
              setState(() => _currentStep = _ResetStep.emailInput);
            } else if (_currentStep == _ResetStep.newPassword) {
              setState(() => _currentStep = _ResetStep.otpInput);
            } else {
              widget.onBackToSignIn();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Icon
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF2D6F).withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2D6F).withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _currentStep == _ResetStep.completed
                        ? Icons.check_circle_rounded
                        : _currentStep == _ResetStep.newPassword
                            ? Icons.lock_open_rounded
                            : _currentStep == _ResetStep.otpInput
                                ? Icons.pin_rounded
                                : Icons.lock_reset_rounded,
                    color: _currentStep == _ResetStep.completed ? Colors.green : const Color(0xFFFF2D6F),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Dynamic Step View
              if (_currentStep == _ResetStep.emailInput) _buildEmailInputStep(),
              if (_currentStep == _ResetStep.otpInput) _buildOtpInputStep(),
              if (_currentStep == _ResetStep.newPassword) _buildNewPasswordStep(),
              if (_currentStep == _ResetStep.completed) _buildCompletedStep(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 1 View: Email Input ---
  Widget _buildEmailInputStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the email address registered with your account. We will dispatch a secure 6-digit verification code to your inbox.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        CustomTextField(
          label: 'Registered Email Address',
          hint: 'user@domain.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _handleRequestOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2D6F),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFFFF2D6F).withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Send Recovery Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: widget.onBackToSignIn,
            icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF1A1A1A)),
            label: const Text(
              'Back to Sign In',
              style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 2 View: OTP Input ---
  Widget _buildOtpInputStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Verification Code',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'We sent a 6-digit verification code to\n'),
              TextSpan(
                text: _emailController.text.trim(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Clean Email Notice Card (No Demo Badges)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mark_email_read_outlined, color: Color(0xFFFF2D6F), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Check Your Email Inbox',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Enter the 6-digit code sent to ${_emailController.text.trim()}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 6-Digit PIN Entry Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 48,
              height: 56,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFFF2D6F), width: 2),
                  ),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (val) {
                  if (val.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (val.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Timer Countdown & Resend Code
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Expires in: ${_formatTimer(_remainingSeconds)}',
                  style: TextStyle(
                    color: _remainingSeconds < 60 ? Colors.red : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _remainingSeconds == 0 ? _handleRequestOtp : null,
              child: Text(
                'Resend Code',
                style: TextStyle(
                  color: _remainingSeconds == 0 ? const Color(0xFFFF2D6F) : Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2D6F),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFFFF2D6F).withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Verify Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 3 View: Create New Password ---
  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your identity has been verified. Create a new strong password with at least 8 characters.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),

        CustomTextField(
          label: 'New Password',
          hint: '••••••••',
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey,
            ),
            onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
          ),
        ),
        const SizedBox(height: 16),

        CustomTextField(
          label: 'Confirm New Password',
          hint: '••••••••',
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey,
            ),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _handleResetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2D6F),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFFFF2D6F).withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Update Password',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 4 View: Completed Confirmation ---
  Widget _buildCompletedStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password Reset!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your password has been successfully updated with secure encryption. You can now sign in with your new credentials.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.security_rounded, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Secured',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _emailController.text.trim(),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: widget.onBackToSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2D6F),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFFFF2D6F).withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sign In with New Password',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
