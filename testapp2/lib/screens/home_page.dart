import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  final AuthService _auth = AuthService();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: const Color(0xFF4285F4),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await _auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You are signed in!',
                style: GoogleFonts.inter(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await _auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => LoginPage()),
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.black),
                label: const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 8.0,
                  ),
                  child: Text(
                    'Sign out',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFDE2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
