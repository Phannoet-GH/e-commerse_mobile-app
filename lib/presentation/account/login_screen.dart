import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/custom_text_field.dart';
import '../../providers/session_provider.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onNavigateToRegister;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onBack;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onNavigateToRegister,
    this.onForgotPassword,
    this.onBack,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. Empty Field Check
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both your email address and password.'),
          backgroundColor: Color(0xFF1E1E2F),
        ),
      );
      return;
    }

    context.read<SessionProvider>().completeSignIn(
          email: email,
          name: email.split('@').first,
        );
    widget.onLoginSuccess();
  }

  void _handleSocialLogin(String provider) {
    context.read<SessionProvider>().signInWithSocial(provider: provider);
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onBack == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: widget.onBack,
              ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFFF2D6F), size: 26),
              ),
              const SizedBox(height: 20),
              const Text('Welcome Back!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                'Sign in to access your orders, favorites, and saved shipping addresses.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                label: 'Email Address',
                hint: 'emma.wills@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    label: 'Password',
                    hint: '••••••••',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: widget.onForgotPassword ?? () => context.read<SessionProvider>().openForgotPassword(),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFFFF2D6F),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
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
                  onPressed: _handleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2D6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),

              // Social Logins Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'or continue with',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 20),

              // Social Login Buttons (Google & Facebook)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleSocialLogin('google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.g_mobiledata_rounded, color: Color(0xFFEA4335), size: 28),
                          SizedBox(width: 4),
                          Text(
                            'Google',
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleSocialLogin('facebook'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.facebook_rounded, color: Color(0xFF1877F2), size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Facebook',
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Center(
                child: TextButton(
                  onPressed: widget.onNavigateToRegister,
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Outfit'),
                      children: const [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(color: Color(0xFFFF2D6F), fontWeight: FontWeight.bold),
                        ),
                      ],
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
}