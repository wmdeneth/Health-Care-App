import 'dart:async';

import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedometer/pedometer.dart';

import 'notification_service.dart';

/// SmartWaterReminder
///
/// - Uses step count and time-of-day to schedule adaptive water reminders.
/// - Persists enabled state in SharedPreferences under key `smart_water_enabled`.
/// - Schedules single notifications (IDs 6000+) so the service can reschedule
///   the next reminder based on updated context when a new step event arrives.
class SmartWaterReminder {
  SmartWaterReminder._private();
  static final SmartWaterReminder instance = SmartWaterReminder._private();

  StreamSubscription<StepCount>? _stepSub;
  int _todaySteps = 0;
  bool _enabled = false;

  // thresholds and tuning parameters (tweakable)
  final int baseIntervalMinutes = 120; // default base interval (2 hours)
  final int activeIntervalMinutes = 60; // when active, remind every 60 minutes
  final int stepActiveThreshold =
      1000; // steps in last period considered "active"
  final int nightStartHour = 22; // 10 PM
  final int nightEndHour = 6; // 6 AM

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('smart_water_enabled') ?? false;

    // read last saved today's steps if available
    final todayKey = _prefKeyForDate(DateTime.now());
    _todaySteps = prefs.getInt(todayKey) ?? 0;

    if (_enabled) {
      _startListeningSteps();
      // schedule an initial reminder
      await _scheduleNextReminder(reason: 'initial');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = enabled;
    await prefs.setBool('smart_water_enabled', enabled);
    if (enabled) {
      _startListeningSteps();
      await _scheduleNextReminder(reason: 'enabled');
    } else {
      await NotificationService.instance.cancelSmartReminders();
      await NotificationService.instance.cancelWaterReminders();
      _stopListeningSteps();
    }
  }

  bool get enabled => _enabled;

  String _prefKeyForDate(DateTime dt) =>
      'steps_${dt.toIso8601String().split('T').first}';

  void _startListeningSteps() {
    try {
      _stepSub ??= Pedometer.stepCountStream.listen(
        (event) async {
          // each pedometer event contains a monotonically increasing total
          // steps value; we persist and compute deltas in the HomeScreen already,
          // but this service also keeps a simple internal counter to react quickly.
          final prefs = await SharedPreferences.getInstance();
          final lastTotalKey = 'pedometer_last_total';
          final int lastTotal = prefs.getInt(lastTotalKey) ?? 0;
          final int newTotal = event.steps;
          int delta = newTotal - lastTotal;
          if (delta < 0) delta = newTotal;
          if (delta > 0) {
            _todaySteps += delta;
            final todayKey = _prefKeyForDate(DateTime.now());
            await prefs.setInt(todayKey, _todaySteps);
            await prefs.setInt(lastTotalKey, newTotal);

            // If user is active, reschedule to a shorter interval
            await _onActiveUpdate(delta);
          }
        },
        onError: (e) {
          // ignore errors; pedometer may not be available on all devices
        },
      );
    } catch (e) {
      // pedometer subscription failed
    }
  }

  void _stopListeningSteps() {
    _stepSub?.cancel();
    _stepSub = null;
  }

  Future<void> _onActiveUpdate(int deltaSteps) async {
    // If a burst of steps arrived, schedule the next reminder earlier
    if (!_enabled) return;
    if (deltaSteps >= stepActiveThreshold) {
      // schedule sooner (active interval)
      await _scheduleNextReminder(
        reason: 'active',
        preferMinutes: activeIntervalMinutes,
      );
    } else {
      // otherwise ensure we have a baseline reminder
      await _scheduleNextReminder(reason: 'tick');
    }
  }

  bool _isNightHour(DateTime now) {
    final h = now.hour;
    if (nightStartHour > nightEndHour) {
      // e.g., 22..6
      return h >= nightStartHour || h < nightEndHour;
    } else {
      return h >= nightStartHour && h < nightEndHour;
    }
  }

  Future<void> _scheduleNextReminder({
    String reason = '',
    int? preferMinutes,
  }) async {
    if (!_enabled) return;

    final now = DateTime.now();

    // Skip scheduling during night hours
    if (_isNightHour(now)) {
      return; // don't schedule at night
    }

    // decide interval: if user active recently, use preferMinutes or active interval
    int intervalMinutes = preferMinutes ?? baseIntervalMinutes;

    // if the user has already walked a lot today, nudge shorter
    if (_todaySteps >= 5000) {
      intervalMinutes = min(intervalMinutes, activeIntervalMinutes);
    }

    final scheduled = now.add(Duration(minutes: intervalMinutes));

    // choose message dynamically
    String title = '💧 Time to drink water';
    String body = 'Stay hydrated — take a sip now.';
    if (_todaySteps > 0) {
      if (_todaySteps >= 5000) {
        title = '💧 You\'ve been active today! Don\'t forget to rehydrate.';
        body = 'You\'ve taken $_todaySteps steps. Time for a drink.';
      } else if (_todaySteps >= 1000) {
        title = '🚶 You\'re moving — hydrate!';
        body = 'You\'ve taken $_todaySteps steps. A sip would help.';
      }
    }

    // Use id=6000 for the next scheduled smart notification; each schedule replaces
    // the previous single notification so the id remains stable.
    await NotificationService.instance.cancelSmartReminders();
    await NotificationService.instance.scheduleSingleNotification(
      id: 6000,
      title: title,
      body: body,
      scheduledDateTime: scheduled,
    );
  }
}
