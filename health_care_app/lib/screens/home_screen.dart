import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/smart_water_reminder.dart';

import '../services/notification_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  StreamSubscription<StepCount>? _stepCountStream;
  int _todaySteps = 0;
  int _lastSavedSteps = 0;
  // Last raw total step value reported by the pedometer (monotonic since boot)
  int _lastTotal = 0;
  final int _dailyGoal = 8000;

  bool _waterRemindersEnabled = false;
  int _waterIntervalHours = 2;
  bool _smartRemindersEnabled = false;
  bool _exactAlarmsPermitted = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Delay heavy or I/O work until after first frame to avoid blocking
    // the UI during app startup. didChangeDependencies can be called
    // multiple times, so ensure we schedule the one-time post-frame work.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWaterPrefs();
      // load exact-alarm permission state used to show a helpful banner
      _loadExactAlarmPref();
    });
  }

  Future<void> _loadWaterPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('water_reminders_enabled') ?? false;
    final hours = prefs.getInt('water_interval_hours') ?? 2;
    final smartEnabled = prefs.getBool('smart_water_enabled') ?? false;
    setState(() {
      _waterRemindersEnabled = enabled;
      _waterIntervalHours = hours;
      _smartRemindersEnabled = smartEnabled;
    });
    // If reminders are enabled, schedule them in the background so we
    // don't block UI on first frame. Any errors are logged by the
    // service — we purposely do not await here.
    if (_waterRemindersEnabled) {
      NotificationService.instance
          .scheduleWaterReminders(intervalHours: _waterIntervalHours, days: 7)
          .catchError(
            (e) => debugPrint('Failed scheduling water reminders: $e'),
          );
    }

    // Initialize smart reminder service if enabled, but don't await here to
    // avoid blocking startup. The service will start and listen when ready.
    if (_smartRemindersEnabled) {
      SmartWaterReminder.instance.init().catchError(
        (e) => debugPrint('SmartWaterReminder init failed: $e'),
      );
    }
  }

  Future<void> _loadExactAlarmPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool exactOk = prefs.getBool('exact_alarms_permitted') ?? true;
      if (mounted) {
        setState(() {
          _exactAlarmsPermitted = exactOk;
        });
      }
    } catch (e) {
      debugPrint('Failed to load exact alarm pref: $e');
    }
  }

  Future<void> _setWaterRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('water_reminders_enabled', enabled);
    await prefs.setInt('water_interval_hours', _waterIntervalHours);
    setState(() {
      _waterRemindersEnabled = enabled;
    });
    if (enabled) {
      await NotificationService.instance.scheduleWaterReminders(
        intervalHours: _waterIntervalHours,
        days: 7,
      );
      Fluttertoast.showToast(msg: 'Water reminders enabled');
    } else {
      await NotificationService.instance.cancelWaterReminders();
      Fluttertoast.showToast(msg: 'Water reminders disabled');
    }
  }

  Future<void> _setSmartRemindersEnabled(bool enabled) async {
    await SmartWaterReminder.instance.setEnabled(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smart_water_enabled', enabled);
    setState(() {
      _smartRemindersEnabled = enabled;
    });
    Fluttertoast.showToast(
      msg: enabled ? 'Smart reminders enabled' : 'Smart reminders disabled',
    );
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Fluttertoast.showToast(msg: 'Logged out');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer pedometer / permission / shared_preferences work until after
    // the first frame so the app can render quickly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStepCounter();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepCountStream?.cancel();
    // persist step state when disposing
    _persistStepState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Persist step counts when the app goes to background or is detached
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _persistStepState();
    }
  }

  Future<void> _initStepCounter() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _prefKeyForDate(DateTime.now());
    _todaySteps = prefs.getInt(todayKey) ?? 0;
    final lastTotalKey = 'pedometer_last_total';
    _lastTotal = prefs.getInt(lastTotalKey) ?? 0;

    Future<bool> ensureActivityPermission() async {
      final status = await Permission.activityRecognition.status;
      if (status.isGranted) {
        return true;
      }
      final result = await Permission.activityRecognition.request();
      return result.isGranted;
    }

    final permOk = await ensureActivityPermission();
    if (!permOk) {
      Fluttertoast.showToast(
        msg: 'Activity permission denied. Steps disabled.',
      );
      return;
    }

    try {
      _stepCountStream = Pedometer.stepCountStream.listen(
        (event) async {
          debugPrint('Pedometer event: ${event.steps}');
          final prefs = await SharedPreferences.getInstance();
          final int newTotal = event.steps;
          int delta = newTotal - _lastTotal;
          // If sensor reset (reboot) or newTotal < _lastTotal, treat newTotal as delta
          if (delta < 0) delta = newTotal;

          if (delta > 0) {
            _todaySteps += delta;
            _lastTotal = newTotal;
            await prefs.setInt(todayKey, _todaySteps);
            await prefs.setInt('pedometer_last_total', newTotal);
            if (mounted) {
              setState(() {});
            }
          } else {
            // still persist the lastTotal in case it's changed to 0 after reboot
            if (_lastTotal != newTotal) {
              _lastTotal = newTotal;
              await prefs.setInt('pedometer_last_total', newTotal);
            }
          }
        },
        onError: (err) {
          debugPrint('Pedometer error: $err');
        },
      );
    } catch (e) {
      debugPrint('Pedometer subscription failed: $e');
    }

    await _maybeSavePreviousDayCount();
  }

  String _prefKeyForDate(DateTime dt) =>
      'steps_${DateFormat('yyyy-MM-dd').format(dt)}';

  Future<void> _maybeSavePreviousDayCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayKey = _prefKeyForDate(yesterday);
    final int yCount = prefs.getInt(yesterdayKey) ?? 0;

    final savedFlagKey = 'saved_${DateFormat('yyyy-MM-dd').format(yesterday)}';
    final bool alreadySaved = prefs.getBool(savedFlagKey) ?? false;
    if (yCount > 0 && !alreadySaved) {
      await _saveStepsToFirestore(yesterday, yCount);
      await prefs.setBool(savedFlagKey, true);
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
      debugPrint('Failed saving steps: $e');
    }
  }

  Future<void> _persistStepState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _prefKeyForDate(DateTime.now());
      await prefs.setInt(todayKey, _todaySteps);
      await prefs.setInt('pedometer_last_total', _lastTotal);
    } catch (e) {
      debugPrint('Failed to persist step state: $e');
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.email ?? 'User'}!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            SwitchListTile(
              title: const Text('Water Reminders'),
              subtitle: Text('Every $_waterIntervalHours hours'),
              value: _waterRemindersEnabled,
              onChanged: (val) async => await _setWaterRemindersEnabled(val),
            ),

            SwitchListTile(
              title: const Text('Smart Water Reminders'),
              subtitle: const Text('Adaptive reminders based on activity/time'),
              value: _smartRemindersEnabled,
              onChanged: (val) async => await _setSmartRemindersEnabled(val),
            ),

            // Show a banner if exact alarms are not permitted so users know why
            // reminders might be inexact. Offer a button to open app settings.
            if (!_exactAlarmsPermitted)
              Card(
                color: Colors.orange.shade50,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: const Icon(
                    Icons.error_outline,
                    color: Colors.orange,
                  ),
                  title: const Text('Precise alarms not permitted'),
                  subtitle: const Text(
                    'Your device blocked exact alarms. Open settings to enable precise reminders.',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      await openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                ),
              ),

            if (_waterRemindersEnabled)
              ExpansionTile(
                title: const Text('Reminder schedule'),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(6, (i) {
                        final dt = DateTime.now().add(
                          Duration(hours: i * _waterIntervalHours),
                        );
                        return Text(
                          '- ${DateFormat('yyyy-MM-dd HH:mm').format(dt)}',
                        );
                      }),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),
            StepCounterCard(
              steps: _todaySteps,
              goal: _dailyGoal,
              lastSynced: _lastSavedSteps,
              onSavePressed: () async {
                await _saveStepsToFirestore(DateTime.now(), _todaySteps);
                setState(() {
                  _lastSavedSteps = _todaySteps;
                });
              },
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

// StepCounterCard with animation
class StepCounterCard extends StatefulWidget {
  final int steps;
  final int goal;
  final int lastSynced;
  final VoidCallback onSavePressed;
  const StepCounterCard({
    super.key,
    required this.steps,
    required this.goal,
    this.lastSynced = 0,
    required this.onSavePressed,
  });

  @override
  @override
  State<StepCounterCard> createState() => _StepCounterCardState();
}

class _StepCounterCardState extends State<StepCounterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _progressAnim = Tween<double>(
      begin: 0.0,
      end: _computeProgress(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  double _computeProgress() {
    final p = widget.goal > 0 ? (widget.steps / widget.goal) : 0.0;
    return p.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(covariant StepCounterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newProgress = _computeProgress();
    _progressAnim = Tween<double>(
      begin: _progressAnim.value,
      end: newProgress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RingPainter(progress: _progressAnim.value),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(_progressAnim.value * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text('of goal', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Steps",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.steps.toString(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Last synced: ${widget.lastSynced > 0 ? widget.lastSynced.toString() : 'never'}',
                      ),
                      ElevatedButton(
                        onPressed: widget.onSavePressed,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;
    final bg =
        Paint()
          // replace deprecated withOpacity to avoid precision-loss warning
          ..color = Colors.grey.withAlpha((0.2 * 255).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8;
    final fg =
        Paint()
          ..color = Colors.teal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    final sweep = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweep,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
