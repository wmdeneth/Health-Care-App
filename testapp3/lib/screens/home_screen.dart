import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/step_ring.dart';
import '../widgets/water_card.dart';
import '../services/step_counter_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/meal_tip.dart';
import '../services/meal_tip_service.dart';
import '../services/water_notification_test.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _dailyWaterGoalMl = 2000;
  static const int _incrementMl = 250;

  int _currentWaterMl = 0;
  String? _waterReminderHint;
  bool _hasActivityPermission = false;

  final MealTipService _mealTipService = MealTipService();

  Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    var cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) {
      buffer.write('ff');
    }
    buffer.write(cleaned);
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  void initState() {
    super.initState();
    _loadWaterReminderState();
    _loadWaterIntake();
    _checkActivityPermission();
  }

  Future<void> _loadWaterIntake() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data() ?? <String, dynamic>{};
      final intake = (data['currentIntake'] as num?)?.toInt() ?? 0;
      if (mounted) {
        setState(() {
          _currentWaterMl = intake;
        });
      }
    } catch (e) {
      debugPrint('Error loading water intake: $e');
    }
  }

  Future<void> _addWaterIntake() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'currentIntake': FieldValue.increment(_incrementMl),
      }, SetOptions(merge: true));

      // Reload water intake to update UI
      await _loadWaterIntake();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $_incrementMl ml! Keep it up! 💧'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding water intake: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _loadWaterReminderState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data() ?? <String, dynamic>{};
      final enabled = data['waterEnabled'] as bool? ?? false;
      if (mounted) {
        setState(() {
          _waterReminderHint =
              enabled
                  ? 'Water reminders are enabled for your account.'
                  : 'Water reminders are currently turned off.';
        });
      }
    } catch (_) {
      // Ignore errors and keep default false.
    }
  }

  Future<void> _checkActivityPermission() async {
    final status = await Permission.activityRecognition.status;
    if (mounted) {
      setState(() => _hasActivityPermission = status.isGranted);
    }
  }

  Future<void> _requestActivityPermission() async {
    final status = await Permission.activityRecognition.request();
    if (mounted) {
      setState(() => _hasActivityPermission = status.isGranted);
    }
    if (!status.isGranted) {
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_walk),
            tooltip: 'Steps',
            onPressed: () {
              Navigator.of(context).pushNamed('/steps');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.of(context).pushNamed('/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Account',
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0E11), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      if (!_hasActivityPermission)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.directions_walk,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Allow activity recognition to track your steps.',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _requestActivityPermission,
                                  child: const Text('Allow'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Steps ring showing today's progress
                      StreamBuilder<int>(
                        stream: StepCounterService().getTodayStepsStream(),
                        builder: (context, snapshot) {
                          final steps = snapshot.data ?? 0;
                          const goal = 10000;
                          return StepRing(steps: steps, goal: goal);
                        },
                      ),
                      const SizedBox(height: 20),
                      WaterCard(
                        currentMl: _currentWaterMl,
                        dailyGoalMl: _dailyWaterGoalMl,
                        onAddWater: _addWaterIntake,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Tips',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<List<MealTip>>(
                        stream: _mealTipService.streamMealTips(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final tips = snapshot.data ?? [];
                          if (tips.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children:
                                tips
                                    .map(
                                      (tip) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Card(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: _colorFromHex(
                                                tip.colorHex,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tip.title,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  tip.subtitle,
                                                  style:
                                                      Theme.of(
                                                        context,
                                                      ).textTheme.bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _waterReminderHint ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      // Test water notifications button
                      Card(
                        color: Colors.purple.shade900.withValues(alpha: 0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.science_outlined,
                                    color: Colors.purple.shade300,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Testing Tools',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade100,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Test water notification functionality',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.purple.shade200),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Running tests... Check console output',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    await WaterNotificationTest.runAllTests();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Tests complete! Check console for results',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Run All Tests'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
