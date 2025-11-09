import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/wave_header.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  final bool initialRegister;
  const LoginPage({super.key, this.initialRegister = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  String? _error;
  late bool _isRegister;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialRegister;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isRegister) {
        await _auth.registerWithEmail(
          _emailCtrl.text.trim(),
          _passCtrl.text.trim(),
        );
      } else {
        await _auth.signInWithEmail(
          _emailCtrl.text.trim(),
          _passCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showPasswordResetDialog() async {
    final emailController = TextEditingController(text: _emailCtrl.text);
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Reset password', style: GoogleFonts.inter()),
            content: TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Enter your email'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancel', style: GoogleFonts.inter()),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFDE2E),
                ),
                onPressed: () {
                  final email = emailController.text.trim();
                  if (email.isEmpty) return;
                  Navigator.of(ctx).pop();
                  _auth
                      .sendPasswordResetEmail(email)
                      .then((_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset email sent'),
                          ),
                        );
                      })
                      .catchError((e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      });
                },
                child: Text(
                  'Send',
                  style: GoogleFonts.inter(color: Colors.black),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                margin: const EdgeInsets.all(24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 12,
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
                            _isRegister ? 'Create Account' : 'Login',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDeco('Email', Icons.person),
                              validator:
                                  (v) =>
                                      (v == null || v.isEmpty)
                                          ? 'Enter email'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: true,
                              decoration: _inputDeco('Password', Icons.lock),
                              validator:
                                  (v) =>
                                      (v == null || v.length < 6)
                                          ? 'Min 6 characters'
                                          : null,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showPasswordResetDialog,
                                child: Text(
                                  'Forgot password?',
                                  style: GoogleFonts.inter(
                                    color: Colors.grey[700]!,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4285F4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                onPressed: _loading ? null : _submit,
                                child:
                                    _loading
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Text(
                                          _isRegister
                                              ? 'Create account'
                                              : 'Sign in',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed:
                                  () => setState(
                                    () => _isRegister = !_isRegister,
                                  ),
                              child: Text(
                                _isRegister
                                    ? 'Have an account? Sign in'
                                    : 'No account? Create one',
                                style: GoogleFonts.inter(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF4285F4)),
      filled: true,
      fillColor: Colors.white,
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
    );
  }
}
