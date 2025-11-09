import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  void login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        loading = true;
      });
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Login successful')));
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
        }
      }
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _showResetPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Form(
            key: resetFormKey,
            child: TextFormField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (resetFormKey.currentState!.validate()) {
                  final navigator = Navigator.of(context);
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                      email: resetEmailController.text.trim(),
                    );
                    if (!mounted) return;
                    Fluttertoast.showToast(msg: 'Password reset email sent');
                    navigator.pop();
                  } on FirebaseAuthException catch (e) {
                    if (!mounted) return;
                    Fluttertoast.showToast(
                      msg: e.message ?? 'Failed to send reset email',
                    );
                  }
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
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
                  // Placeholder for logo image (add your asset in pubspec.yaml)
                  // Image.asset('assets/logo.png', height: 100.0),
                  const Icon(
                    Icons.local_hospital_rounded,
                    size: 100.0,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Health Care App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(color: Colors.white70, fontSize: 18.0),
                  ),
                ],
              ),
              const SizedBox(height: 120.0),
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showResetPasswordDialog,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.teal),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      ElevatedButton(
                        onPressed: loading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          minimumSize: const Size(double.infinity, 50.0),
                        ),
                        child:
                            loading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                      const SizedBox(height: 10.0),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Create New Account',
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
