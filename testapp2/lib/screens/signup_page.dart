import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/wave_header.dart';
import '../services/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.registerWithEmail(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
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
                    const WaveHeader(
                      height: 180,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Create Account',
                            style: TextStyle(fontSize: 28, color: Colors.white),
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
                              decoration: _inputDeco('Email', Icons.email),
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
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: true,
                              decoration: _inputDeco(
                                'Confirm Password',
                                Icons.lock,
                              ),
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
                                          'Sign up',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Already have an account? Log in',
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
