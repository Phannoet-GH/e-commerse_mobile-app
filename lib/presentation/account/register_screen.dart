import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/custom_text_field.dart';
import '../../providers/session_provider.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegisterSuccess;
  final VoidCallback onBackToSignIn;

  const RegisterScreen({
    super.key,
    required this.onRegisterSuccess,
    required this.onBackToSignIn,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isNotEmpty && email.isNotEmpty) {
      context.read<SessionProvider>().register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
    } else {
      context.read<SessionProvider>().register(
        name: 'Emma Wills',
        email: 'emma.wills@email.com',
        password: 'password123',
      );
    }
    widget.onRegisterSuccess();
  }

  void _handleSocialRegister(String provider) {
    context.read<SessionProvider>().signInWithSocial(provider: provider);
    widget.onRegisterSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: widget.onBackToSignIn,
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
                child: const Icon(Icons.person_add_outlined, color: Color(0xFFFF2D6F), size: 26),
              ),
              const SizedBox(height: 20),
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Register to unlock member rewards, order tracking, and fast checkout.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 28),
              CustomTextField(
                label: 'Full Name',
                hint: 'Emma Wills',
                controller: _nameController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email Address',
                hint: 'emma.wills@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Phone Number (Optional)',
                hint: '+1 (555) 234-5678',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Password',
                hint: '••••••••',
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2D6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Social Logins Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'or register with',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 18),

              // Social Login Buttons (Google & Facebook)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleSocialRegister('google'),
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
                      onPressed: () => _handleSocialRegister('facebook'),
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
              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: widget.onBackToSignIn,
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Outfit'),
                      children: const [
                        TextSpan(
                          text: 'Sign In',
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
