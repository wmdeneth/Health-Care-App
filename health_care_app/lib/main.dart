import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Defer heavy initialization (timezone, notification plugin, Firebase)
  // until after the app's first frame so the UI appears quickly.
  runApp(const MyApp());
}

final ThemeData appTheme = ThemeData(
  primarySwatch: Colors.teal,
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initializing = true;
  Object? _initError;
  bool _firebaseReady = false;

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    try {
      // Initialize timezone data and notifications off the critical path.
      // We intentionally do NOT await these so the first UI frame appears
      // quickly. Any errors are caught and logged.
      Future.microtask(() async {
        try {
          tz.initializeTimeZones();
          try {
            tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
          } catch (_) {
            // ignore
          }
        } catch (_) {
          // ignore
        }
      });

      Future.microtask(() async {
        try {
          // Defer heavy plugin init until after the first frame so we
          // don't block the UI. Using addPostFrameCallback below ensures
          // the app can render its first frame quickly.
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await NotificationService.instance.initialize();
            } catch (_) {
              // ignore initialization errors — service has fallbacks
            }
          });
        } catch (_) {
          // ignore
        }
      });

      // Initialize Firebase in background so we don't block the first frame.
      // We'll mark firebase readiness when it completes and surface errors.
      Firebase.initializeApp()
          .then((_) {
            if (mounted) {
              setState(() {
                _firebaseReady = true;
              });
            }
          })
          .catchError((e) {
            if (mounted) {
              setState(() {
                _initError = e;
              });
            }
          });
    } catch (e) {
      _initError = e;
    } finally {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Care App',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: Builder(
        builder: (context) {
          if (_initializing) {
            // Show a lightweight splash immediately while background init runs.
            return const Scaffold(
              body: Center(
                child: Text('Health Care App', style: TextStyle(fontSize: 22)),
              ),
            );
          }

          if (_initError != null) {
            // If initialization failed (e.g. missing firebase options on web),
            // show a helpful message but allow continuing without Firebase.
            return Scaffold(
              appBar: AppBar(title: const Text('Startup Error')),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Failed to initialize some services',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Error: $_initError'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Continue without Firebase (limited)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // If Firebase finished initializing, use authStateChanges to pick
          // the landing page. If Firebase is still initializing, fall back to
          // a lightweight route (LoginScreen) so the UI is interactive fast;
          // once Firebase is ready the widget will rebuild and attach auth
          // state listeners.
          if (_firebaseReady) {
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasData && snapshot.data != null) {
                  return const HomeScreen();
                }
                return const LoginScreen();
              },
            );
          }

          // Firebase not yet ready; show LoginScreen (limited) so the app
          // becomes responsive immediately. When Firebase completes it will
          // set _firebaseReady and rebuild.
          return const LoginScreen();
        },
      ),
    );
  }
}
