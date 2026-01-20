import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../models/step_data.dart';

class StepCounterService {
  // Singleton instance
  static final StepCounterService _instance = StepCounterService._internal();

  factory StepCounterService() {
    return _instance;
  }

  StepCounterService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  late Stream<PedestrianStatus> pedestrianStatusStream;
  late Stream<StepCount> stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  StreamSubscription<StepCount>? _stepCountSubscription;

  // StreamController to broadcast today's steps to UI
  final _stepController = StreamController<int>.broadcast();

  // Local state
  int _todaySteps = 0;
  int _lastSensorReading = -1; // -1 indicates not initialized
  String _lastSavedDate = '';
  String _status = 'unknown';

  // Keys for SharedPreferences
  static const String _keyTodaySteps = 'today_steps';
  static const String _keyLastSensorReading = 'last_sensor_reading';
  static const String _keyLastSavedDate = 'last_saved_date';

  // Test helpers
  Stream<StepCount>? _stepCountStreamOverride;
  Stream<PedestrianStatus>? _pedestrianStatusStreamOverride;

  @visibleForTesting
  set stepCountStreamOverride(Stream<StepCount> stream) =>
      _stepCountStreamOverride = stream;

  @visibleForTesting
  set pedestrianStatusStreamOverride(Stream<PedestrianStatus> stream) =>
      _pedestrianStatusStreamOverride = stream;

  @visibleForTesting
  Future<void> resetForTesting() async {
    _todaySteps = 0;
    _lastSensorReading = -1;
    _lastSavedDate = '';
    _status = 'unknown';
    await _stepCountSubscription?.cancel();
    await _pedestrianStatusSubscription?.cancel();
    // Clear prefs
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Initialize step counter - must be called when app starts
  Future<bool> initStepCounter() async {
    try {
      debugPrint('Initializing StepCounterService...');

      // Load saved state from local storage
      await _loadLocalState();

      // Check date and reset if needed
      _checkAndResetForNewDay();

      if (_stepCountStreamOverride == null) {
        // Request runtime permission on Android 10+
        final status = await Permission.activityRecognition.request();
        if (!status.isGranted) {
          debugPrint('Activity recognition permission not granted');
        }
      }

      // Listen to step count updates
      stepCountStream = _stepCountStreamOverride ?? Pedometer.stepCountStream;
      _stepCountSubscription = stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
      );

      // Listen to pedestrian status
      pedestrianStatusStream =
          _pedestrianStatusStreamOverride ?? Pedometer.pedestrianStatusStream;
      _pedestrianStatusSubscription = pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: _onPedestrianStatusError,
      );

      debugPrint(
        'Step Counter initialized successfully. Initial steps: $_todaySteps',
      );
      // Emit initial value
      _stepController.add(_todaySteps);

      return true;
    } catch (e) {
      debugPrint('Error initializing step counter: $e');
      return false;
    }
  }

  /// Load state from SharedPreferences
  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    _todaySteps = prefs.getInt(_keyTodaySteps) ?? 0;
    _lastSensorReading = prefs.getInt(_keyLastSensorReading) ?? -1;
    _lastSavedDate = prefs.getString(_keyLastSavedDate) ?? _getTodayDateKey();
  }

  /// Check if it's a new day and reset steps if so
  void _checkAndResetForNewDay() {
    final todayKey = _getTodayDateKey();
    if (_lastSavedDate != todayKey) {
      debugPrint(
        'New day detected. Resetting steps. Old date: $_lastSavedDate, New date: $todayKey',
      );
      _todaySteps = 0;
      _lastSavedDate = todayKey;
      _saveLocalState();
    }
  }

  /// Save state to SharedPreferences
  Future<void> _saveLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTodaySteps, _todaySteps);
    await prefs.setInt(_keyLastSensorReading, _lastSensorReading);
    await prefs.setString(_keyLastSavedDate, _lastSavedDate);
  }

  /// Handle step count updates
  void _onStepCount(StepCount event) async {
    final int reading = event.steps;
    debugPrint('Sensor reading: $reading');

    // First reading determination
    if (_lastSensorReading == -1) {
      // First time app is running or state cleared.
      // We don't add steps this first time, just establish baseline.
      _lastSensorReading = reading;
      _saveLocalState();
      return;
    }

    _checkAndResetForNewDay();

    // Calculate delta
    int delta = reading - _lastSensorReading;

    // Handle Reboot (Sensor resets to 0)
    // If reading < lastSensorReading, it means the phone rebooted and sensor reset.
    // In this case, the 'reading' itself is the steps taken since reboot (assuming 0 start).
    if (reading < _lastSensorReading) {
      debugPrint(
        'Reboot detected! Sensor resetted. Reading: $reading, Last: $_lastSensorReading',
      );
      delta = reading;
    }

    // Sanity check for negative delta (shouldn't happen with reboot logic above, but safety first)
    if (delta < 0) {
      delta = 0;
    }

    // Update local state
    if (delta > 0) {
      _todaySteps += delta;
      _lastSensorReading = reading;

      // Save and Broadcast
      await _saveLocalState();
      _stepController.add(_todaySteps);
      debugPrint('Steps updated: $_todaySteps (+$delta)');

      // Sync to cloud (optional/best-effort)
      _saveStepsToFirestore(_todaySteps);
    }
  }

  /// Create a key for today's date (YYYY-MM-DD)
  String _getTodayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _onStepCountError(error) {
    debugPrint('Step Count Error: $error');
  }

  void _onPedestrianStatusChanged(PedestrianStatus status) {
    _status = status.status;
    debugPrint('Status: $_status');
  }

  void _onPedestrianStatusError(error) {
    debugPrint('Pedestrian Status Error: $error');
  }

  // --- Public Getters ---

  int getCurrentSteps() => _todaySteps;

  String getCurrentStatus() => _status;

  /// Stream of today's steps for UI
  Stream<int> getTodayStepsStream() {
    // Return the broadcast stream.
    // Also add current value immediately for new listeners if we have it?
    // BehaviorSubject equivalent would be nice, but simple stream + initial data in builder is fine.
    // But we can just use the controller's stream.
    return _stepController.stream;
  }

  // --- Firestore Sync (Secondary) ---

  Future<void> _saveStepsToFirestore(int steps) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final dateKey = _getTodayDateKey();

      // Fire and forget - don't await this to avoid blocking UI or offline issues
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('step_data')
          .doc(dateKey)
          .set({
            'steps': steps,
            'date': DateTime.now().toIso8601String(),
            'timestamp': DateTime.now().toIso8601String(),
            'distance': (steps * 0.762) / 1000,
            'calories': (steps * 0.04).toInt(),
          }, SetOptions(merge: true))
          .catchError(
            (e) => debugPrint('Firestore sync error (expected if offline): $e'),
          );

      // Also update total steps
      _firestore.collection('users').doc(user.uid).set({
        'totalSteps':
            steps, // Note: this is actually "today's steps", field name might be misleading but keeping legacy structure
        'lastStepUpdate': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Create a silent failure for offline mode
      // debugPrint('Error saving steps to Firestore: $e');
    }
  }

  // --- Legacy helpers if needed ---
  // Keeping these basic implementations to avoid breaking other parts of the app if they rely on it

  // --- Legacy / Extended functionality helpers ---

  /// Get total steps today (Future version for one-off checks)
  Future<int> getTodaySteps() async {
    return _todaySteps;
  }

  /// Get steps for the last 7 days
  /// Warning: This relies on Firestore connectivity for history in this MVP.
  /// A full offline implementation would need a local database (e.g. Hive/Sqlite) for history.
  Future<List<StepData>> getLast7DaysSteps() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    return getStepsForDateRange(sevenDaysAgo, now);
  }

  /// Get steps for the last 30 days
  Future<List<StepData>> getLast30DaysSteps() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return getStepsForDateRange(thirtyDaysAgo, now);
  }

  /// Get average steps for a period
  Future<double> getAverageSteps(int days) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final stepsList = await getStepsForDateRange(startDate, now);

    if (stepsList.isEmpty) return 0;

    final total = stepsList.fold<int>(0, (acc, data) => acc + data.steps);
    return total / stepsList.length;
  }

  /// Set daily step goal
  Future<void> setDailyGoal(int goal) async {
    try {
      final user = _auth.currentUser;
      // Also save to prefs for offline
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('step_goal', goal);

      if (user == null) return;
      await _firestore.collection('users').doc(user.uid).set({
        'stepGoal': goal,
        'stepGoalSetDate': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error setting daily goal: $e');
    }
  }

  /// Get daily step goal
  Future<int> getDailyGoal() async {
    try {
      // Try local first
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('step_goal')) {
        return prefs.getInt('step_goal')!;
      }

      final user = _auth.currentUser;
      if (user == null) return 10000; // default

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final goal = doc.data()?['stepGoal'] ?? 10000;
        // Save to local
        await prefs.setInt('step_goal', goal);
        return goal;
      }
      return 10000;
    } catch (e) {
      debugPrint('Error getting daily goal: $e');
      return 10000;
    }
  }

  /// Get steps for a range of dates (Firestore fallback)
  Future<List<StepData>> getStepsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final docs =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('step_data')
              .where(
                'date',
                isGreaterThanOrEqualTo: startDate.toIso8601String(),
              )
              .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
              .orderBy('date', descending: true)
              .get();

      return docs.docs.map((doc) => StepData.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting steps for date range: $e');
      return [];
    }
  }

  Future<StepData> getStepsForDate(DateTime date) async {
    // If it's today, return local data
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (dateKey == _getTodayDateKey()) {
      return StepData(date: date, steps: _todaySteps);
    }
    // Else try firestore
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('step_data')
                .doc(dateKey)
                .get();
        if (doc.exists)
          return StepData.fromJson({
            ...doc.data()!,
            'date': date.toIso8601String(),
          });
      }
    } catch (_) {}
    return StepData(date: date, steps: 0);
  }

  void dispose() {
    _pedestrianStatusSubscription?.cancel();
    _stepCountSubscription?.cancel();
    _stepController.close();
  }
}
