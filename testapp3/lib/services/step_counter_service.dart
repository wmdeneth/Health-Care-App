import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../models/step_data.dart';

class StepCounterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Stream<PedestrianStatus> pedestrianStatusStream;
  late Stream<StepCount> stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  StreamSubscription<StepCount>? _stepCountSubscription;

  int _steps = 0;
  String _status = "unknown";

  /// Initialize step counter - must be called when app starts
  Future<bool> initStepCounter() async {
    try {
      // Request runtime permission on Android 10+
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        debugPrint('Activity recognition permission not granted');
        // Continue init; stream may still work on some devices
      }

      // Listen to step count updates
      stepCountStream = Pedometer.stepCountStream;
      _stepCountSubscription = stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
      );

      // Listen to pedestrian status (walking, running, stopped, etc)
      pedestrianStatusStream = Pedometer.pedestrianStatusStream;
      _pedestrianStatusSubscription = pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: _onPedestrianStatusError,
      );

      debugPrint('Step Counter initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing step counter: $e');
      return false;
    }
  }

  /// Handle step count updates
  void _onStepCount(StepCount event) {
    _steps = event.steps;
    _saveStepsToFirestore(event.steps);
  }

  /// Handle step count errors
  void _onStepCountError(error) {
    debugPrint('Step Count Error: $error');
  }

  /// Handle pedestrian status changes
  void _onPedestrianStatusChanged(PedestrianStatus status) {
    _status = status.status;
    debugPrint('Status: $_status');
  }

  /// Handle pedestrian status errors
  void _onPedestrianStatusError(error) {
    debugPrint('Pedestrian Status Error: $error');
  }

  /// Get current step count
  int getCurrentSteps() => _steps;

  /// Get current activity status
  String getCurrentStatus() => _status;

  /// Save steps to Firestore
  Future<void> _saveStepsToFirestore(int steps) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Save daily step data
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('step_data')
          .doc(dateKey)
          .update({
            'steps': steps,
            'timestamp': DateTime.now().toIso8601String(),
          })
          .catchError((_) {
            // Create if doesn't exist
            return _firestore
                .collection('users')
                .doc(user.uid)
                .collection('step_data')
                .doc(dateKey)
                .set({
                  'date': today.toIso8601String(),
                  'steps': steps,
                  'distance': (steps * 0.762) / 1000,
                  'calories': (steps * 0.04).toInt(),
                  'timestamp': DateTime.now().toIso8601String(),
                });
          });

      // Also save total steps to user's main document for admin panel
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
            'totalSteps': steps,
            'lastStepUpdate': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true))
          .catchError((e) {
            debugPrint('Error updating totalSteps in user document: $e');
          });
    } catch (e) {
      debugPrint('Error saving steps to Firestore: $e');
    }
  }

  /// Get steps for a specific date
  Future<StepData> getStepsForDate(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return StepData(date: date, steps: 0);

      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final doc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('step_data')
              .doc(dateKey)
              .get();

      if (doc.exists) {
        return StepData.fromJson({...doc.data()!, 'date': date});
      } else {
        return StepData(date: date, steps: 0);
      }
    } catch (e) {
      debugPrint('Error getting steps for date: $e');
      return StepData(date: date, steps: 0);
    }
  }

  /// Get steps for a range of dates
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

  /// Get steps for the last 7 days
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

  /// Get total steps today
  Future<int> getTodaySteps() async {
    final stepData = await getStepsForDate(DateTime.now());
    return stepData.steps;
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

  /// Stream of today's steps
  Stream<int> getTodayStepsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();

    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('step_data')
        .doc(dateKey)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return doc.data()?['steps'] ?? 0;
          }
          return 0;
        });
  }

  /// Set daily step goal
  Future<void> setDailyGoal(int goal) async {
    try {
      final user = _auth.currentUser;
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
      final user = _auth.currentUser;
      if (user == null) return 10000; // default

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return doc.data()?['stepGoal'] ?? 10000;
      }
      return 10000;
    } catch (e) {
      debugPrint('Error getting daily goal: $e');
      return 10000;
    }
  }

  /// Cleanup - call when app closes
  void dispose() {
    _pedestrianStatusSubscription?.cancel();
    _stepCountSubscription?.cancel();
  }
}
