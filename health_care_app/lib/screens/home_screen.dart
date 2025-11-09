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
  int _lastTotal = 0;
  final int _dailyGoal = 8000;

  bool _waterRemindersEnabled = false;
  int _waterIntervalHours = 2;
  bool _smartRemindersEnabled = false;
  bool _exactAlarmsPermitted = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWaterPrefs();
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
    if (_waterRemindersEnabled) {
      NotificationService.instance
          .scheduleWaterReminders(intervalHours: _waterIntervalHours, days: 7)
          .catchError((e) => debugPrint('Water reminder schedule failed: $e'));
    }
    if (_smartRemindersEnabled) {
      SmartWaterReminder.instance.init().catchError(
        (e) => debugPrint('Smart reminder init failed: $e'),
      );
    }
  }

  Future<void> _loadExactAlarmPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool exactOk = prefs.getBool('exact_alarms_permitted') ?? true;
      if (mounted) setState(() => _exactAlarmsPermitted = exactOk);
    } catch (e) {
      debugPrint('Failed to load exact alarm pref: $e');
    }
  }

  Future<void> _setWaterRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('water_reminders_enabled', enabled);
    await prefs.setInt('water_interval_hours', _waterIntervalHours);
    setState(() => _waterRemindersEnabled = enabled);
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
    setState(() => _smartRemindersEnabled = enabled);
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _initStepCounter());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepCountStream?.cancel();
    _persistStepState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _persistStepState();
    }
  }

  Future<void> _initStepCounter() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _prefKeyForDate(DateTime.now());
    _todaySteps = prefs.getInt(todayKey) ?? 0;
    _lastTotal = prefs.getInt('pedometer_last_total') ?? 0;

    final permOk = await Permission.activityRecognition.request().isGranted;
    if (!permOk) {
      Fluttertoast.showToast(
        msg: 'Activity permission denied. Steps disabled.',
      );
      return;
    }

    try {
      _stepCountStream = Pedometer.stepCountStream.listen((event) async {
        final newTotal = event.steps;
        int delta = newTotal - _lastTotal;
        if (delta < 0) delta = newTotal;
        if (delta > 0) {
          _todaySteps += delta;
          _lastTotal = newTotal;
          await prefs.setInt(todayKey, _todaySteps);
          await prefs.setInt('pedometer_last_total', newTotal);
          if (mounted) setState(() {});
        } else if (_lastTotal != newTotal) {
          _lastTotal = newTotal;
          await prefs.setInt('pedometer_last_total', newTotal);
        }
      }, onError: (err) => debugPrint('Pedometer error: $err'));
    } catch (e) {
      debugPrint('Pedometer subscription failed: $e');
    }

    await _maybeSavePreviousDayCount();
  }

  String _prefKeyForDate(DateTime dt) =>
      'steps_${DateFormat('yyyy-MM-dd').format(dt)}';

  Future<void> _persistStepState() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _prefKeyForDate(DateTime.now());
    await prefs.setInt(todayKey, _todaySteps);
    await prefs.setInt('pedometer_last_total', _lastTotal);
  }

  Future<void> _maybeSavePreviousDayCount() async {
    final prefs = await SharedPreferences.getInstance();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayKey = _prefKeyForDate(yesterday);
    if (prefs.containsKey(yesterdayKey)) {
      final steps = prefs.getInt(yesterdayKey) ?? 0;
      if (steps > 0 && mounted) {
        await _saveStepsToFirestore(yesterday, steps);
        await prefs.remove(yesterdayKey);
      }
    }
  }

  Future<void> _saveStepsToFirestore(DateTime date, int steps) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('steps')
          .doc(DateFormat('yyyy-MM-dd').format(date))
          .set({'steps': steps, 'timestamp': Timestamp.now()});
      setState(() => _lastSavedSteps = _todaySteps);
      Fluttertoast.showToast(msg: 'Steps saved to cloud');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to save steps');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Health Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
          ),
        ],
      ),
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
            padding: const EdgeInsets.all(16.0),
            children: [
              const SizedBox(height: 20),

              // User Greeting
              Text(
                'Hello, ${FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'User'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              // Step Counter Card
              GlassCard(
                child: StepCounterCard(
                  steps: _todaySteps,
                  goal: _dailyGoal,
                  lastSynced: _lastSavedSteps,
                  onSavePressed:
                      () => _saveStepsToFirestore(DateTime.now(), _todaySteps),
                ),
              ),
              const SizedBox(height: 20),

              // Water Reminder Toggle
              GlassCard(
                child: SwitchListTile(
                  title: const Text(
                    'Water Reminders',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Every $_waterIntervalHours hours'),
                  value: _waterRemindersEnabled,
                  onChanged: _setWaterRemindersEnabled,
                  secondary: const Icon(Icons.water_drop, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 12),

              // Smart Reminder Toggle
              GlassCard(
                child: SwitchListTile(
                  title: const Text(
                    'Smart Hydration',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Adapts to your activity'),
                  value: _smartRemindersEnabled,
                  onChanged: _setSmartRemindersEnabled,
                  secondary: const Icon(Icons.smart_toy, color: Colors.purple),
                ),
              ),
              const SizedBox(height: 20),

              // Exact Alarm Banner (if needed)
              if (!_exactAlarmsPermitted)
                GlassCard(
                  child: ListTile(
                    leading: const Icon(Icons.schedule, color: Colors.orange),
                    title: const Text('Precise alarms not permitted'),
                    subtitle: const Text(
                      'Open settings to enable accurate reminders.',
                    ),
                    trailing: TextButton(
                      onPressed: openAppSettings,
                      child: const Text('Settings'),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Feature Cards
              Row(
                children: [
                  Expanded(
                    child: FeatureCard(
                      icon: Icons.medical_services,
                      title: 'Health Tips',
                      color: Colors.green,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FeatureCard(
                      icon: Icons.local_hospital,
                      title: 'Appointments',
                      color: Colors.redAccent,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Glass-morphic Card
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Feature Card
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// Step Counter Card (unchanged logic, improved visuals)
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
      duration: const Duration(milliseconds: 800),
    );
    _progressAnim = Tween<double>(
      begin: 0.0,
      end: _computeProgress(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  double _computeProgress() =>
      widget.goal > 0 ? (widget.steps / widget.goal).clamp(0.0, 1.0) : 0.0;

  @override
  void didUpdateWidget(covariant StepCounterCard old) {
    super.didUpdateWidget(old);
    final newProgress = _computeProgress();
    _progressAnim = Tween<double>(
      begin: _progressAnim.value,
      end: newProgress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'of goal',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
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
                const Text(
                  "Today's Steps",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.steps.toString(),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Synced: ${widget.lastSynced > 0 ? widget.lastSynced : 'never'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    ElevatedButton(
                      onPressed: widget.onSavePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal,
                      ),
                      child: const Text('Save'),
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
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final bg =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10;
    final fg =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
