import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/wave_header.dart';
import 'login_page.dart';
import 'signup_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pc = PageController(viewportFraction: 0.92);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: SafeArea(
          child: PageView(
            controller: _pc,
            children: [
              _buildQuickSignIn(context),
              _buildLoginPreview(context),
              _buildSignupPreview(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSignIn(BuildContext context) {
    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WaveHeader(height: 240, child: SizedBox()),
          const SizedBox(height: 24),
          const CircleAvatar(
            radius: 48,
            backgroundImage: NetworkImage('https://picsum.photos/200'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                Text('Last signed in', style: GoogleFonts.inter()),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _blueButton(
            'Sign in',
            () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LoginPage())),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed:
                () => _pc.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.ease,
                ),
            child: Text(
              'Sign in using another account',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLoginPreview(BuildContext context) {
    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WaveHeader(
            height: 180,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'Welcome Back',
                  style: GoogleFonts.inter(fontSize: 28, color: Colors.white),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _textField(hint: 'Email', icon: Icons.person),
                const SizedBox(height: 12),
                _textField(hint: 'Password', icon: Icons.lock, obscure: true),
                const SizedBox(height: 20),
                _blueButton(
                  'Log in',
                  () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => LoginPage())),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => LoginPage()),
                          ),
                      child: Text(
                        'Forgot password?',
                        style: GoogleFonts.inter(color: Colors.white70),
                      ),
                    ),
                    TextButton(
                      onPressed:
                          () => _pc.animateToPage(
                            2,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.ease,
                          ),
                      child: Text(
                        'Sign up',
                        style: GoogleFonts.inter(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupPreview(BuildContext context) {
    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WaveHeader(
            height: 180,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'Create Account',
                  style: GoogleFonts.inter(fontSize: 28, color: Colors.white),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _textField(hint: 'Name', icon: Icons.person),
                const SizedBox(height: 12),
                _textField(hint: 'Email', icon: Icons.email),
                const SizedBox(height: 12),
                _textField(hint: 'Password', icon: Icons.lock, obscure: true),
                const SizedBox(height: 12),
                _textField(
                  hint: 'Confirm Password',
                  icon: Icons.lock,
                  obscure: true,
                ),
                const SizedBox(height: 20),
                _blueButton(
                  'Sign up',
                  () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const SignupPage())),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed:
                      () => _pc.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.ease,
                      ),
                  child: Text(
                    'Log in',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _card({required Widget child}) {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 12,
        child: child,
      ),
    );
  }

  Widget _textField({
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      obscureText: obscure,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF4285F4)),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
        ),
      ),
    );
  }

  Widget _blueButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4285F4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 4,
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
