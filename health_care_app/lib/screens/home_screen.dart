import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  StreamSubscription<StepCount>? _stepCountStream;
  int _todaySteps = 0;
  int _lastSavedSteps = 0; // used to avoid duplicate saves

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Fluttertoast.showToast(msg: "Logged out");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _initStepCounter();
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    super.dispose();
  }

  Future<void> _initStepCounter() async {
    // load persisted today's count
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _prefKeyForDate(DateTime.now());
    _todaySteps = prefs.getInt(todayKey) ?? 0;

    // listen to pedometer step count (cumulative since device boot)
    try {
      // pedometer provides a static stepCountStream that emits StepCount events
      _stepCountStream = Pedometer.stepCountStream.listen(
        (event) async {
          // event.steps is the total steps since boot; we treat it as increments
          final prefs = await SharedPreferences.getInstance();
          final lastTotalKey = 'pedometer_last_total';
          final int lastTotal = prefs.getInt(lastTotalKey) ?? 0;
          final int newTotal = event.steps;
          int delta = newTotal - lastTotal;
          if (delta < 0) delta = newTotal; // device rebooted or counter reset

          if (delta > 0) {
            _todaySteps += delta;
            prefs.setInt(todayKey, _todaySteps);
            prefs.setInt(lastTotalKey, newTotal);
            if (mounted) setState(() {});
          }
        },
        onError: (err) {
          // ignore pedometer errors for now
        },
      );
    } catch (e) {
      // pedometer may not be supported on simulator
    }

    // schedule a daily save at midnight (or when app resumes) - simplest: check on startup
    _maybeSavePreviousDayCount();
  }

  String _prefKeyForDate(DateTime dt) =>
      'steps_${DateFormat('yyyy-MM-dd').format(dt)}';

  Future<void> _maybeSavePreviousDayCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final yesterday = today.subtract(Duration(days: 1));
    final yesterdayKey = _prefKeyForDate(yesterday);
    final int yCount = prefs.getInt(yesterdayKey) ?? 0;

    // if yesterday hasn't been saved to Firestore, save it
    final savedFlagKey = 'saved_${DateFormat('yyyy-MM-dd').format(yesterday)}';
    final bool alreadySaved = prefs.getBool(savedFlagKey) ?? false;
    if (yCount > 0 && !alreadySaved) {
      await _saveStepsToFirestore(yesterday, yCount);
      prefs.setBool(savedFlagKey, true);
    }
  }

  Future<void> _saveStepsToFirestore(DateTime date, int steps) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final dayId = DateFormat('yyyy-MM-dd').format(date);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('step_counts')
          .doc(dayId)
          .set({
            'date': dayId,
            'steps': steps,
            'email': user.email,
            'updated_at': FieldValue.serverTimestamp(),
          });
      Fluttertoast.showToast(msg: 'Saved $steps steps for $dayId');
    } catch (e) {
      // could retry later
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Care Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.email ?? 'User'}!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Steps',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _todaySteps.toString(),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                // manual save for testing
                                await _saveStepsToFirestore(
                                  DateTime.now(),
                                  _todaySteps,
                                );
                              },
                              child: Text('Save Now'),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Last synced: ${_lastSavedSteps > 0 ? _lastSavedSteps.toString() : 'never'}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.teal),
                title: const Text('Health Tips'),
                subtitle: const Text('Check daily health tips and advice.'),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 15),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.local_hospital,
                  color: Colors.redAccent,
                ),
                title: const Text('Appointments'),
                subtitle: const Text('View or book appointments.'),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
