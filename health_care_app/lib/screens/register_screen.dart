import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  void register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Registration failed')),
          );
        }
      }
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal, Colors.tealAccent],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            children: <Widget>[
              const SizedBox(height: 80.0),
              Column(
                children: <Widget>[
                  const Icon(
                    Icons.person_add_rounded,
                    size: 100.0,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Join us and stay healthy!',
                    style: TextStyle(color: Colors.white70, fontSize: 18.0),
                  ),
                ],
              ),
              const SizedBox(height: 100.0),
              Container(
                padding: const EdgeInsets.all(20.0),
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15.0,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      // Email Field
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Colors.teal,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor: Colors.teal.withValues(alpha: 0.05),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter email';
                          }
                          if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                            return 'Enter valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      // Password Field
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Colors.teal,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor: Colors.teal.withValues(alpha: 0.05),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter password';
                          }
                          if (value.length < 6) {
                            return 'Password must be 6+ characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      // Confirm Password Field
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Colors.teal,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor: Colors.teal.withValues(alpha: 0.05),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm your password';
                          }
                          if (value != passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30.0),

                      // Register Button
                      ElevatedButton(
                        onPressed: loading ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          minimumSize: const Size(double.infinity, 50.0),
                          elevation: 5,
                        ),
                        child:
                            loading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                      const SizedBox(height: 15.0),

                      // Back to Login
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Already have an account? Login',
                          style: TextStyle(color: Colors.teal),
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
    );
  }
}
