import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotificationService() async {
  // Initialize timezone data
  tzdata.initializeTimeZones();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: _onNotificationResponse,
  );

  // On Android 13+ you must request notification permission at runtime
  final androidImplementation =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
  await androidImplementation?.requestNotificationsPermission();

  // Request SCHEDULE_EXACT_ALARM permission for scheduling at specific times
  await androidImplementation?.requestExactAlarmsPermission();
}

Future<void> scheduleDailyHydrationReminders() async {
  // Cancel any existing scheduled hydration notifications to avoid duplicates
  await flutterLocalNotificationsPlugin.cancelAll();

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    // No authenticated user: nothing to schedule.
    return;
  }

  // Clear existing scheduled notifications from Firestore
  try {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scheduled_notifications')
            .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  } catch (e) {
    debugPrint('Error clearing scheduled notifications from Firestore: $e');
    throw Exception('Failed to clear scheduled notifications: $e');
  }

  // Fixed notification window between 08:00 and 22:00.
  const int startHour = 8;
  const int endHour = 22;

  // Derive goal from user's profile:
  //   dailyWaterGoal(ml) = weightKg * 35
  // and
  double dailyGoalMl = 2000; // fallback
  try {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = doc.data() ?? <String, dynamic>{};
    final weightKg = (data['weightKg'] as num?)?.toDouble();
    final heightCm = (data['heightCm'] as num?)?.toDouble();

    if (weightKg != null && weightKg > 0) {
      double baseGoal = weightKg * 35.0;

      // Optional BMI-based adjustment: keep the logic simple and conservative.
      if (heightCm != null && heightCm > 0) {
        final hMeters = heightCm / 100.0;
        final bmi = weightKg / (hMeters * hMeters);

        if (bmi < 18.5) {
          // Underweight – slightly reduce target to avoid over-hydration.
          baseGoal *= 0.9;
        } else if (bmi > 30) {
          // Obese – slightly increase target within a safe margin.
          baseGoal *= 1.1;
        }
      }

      dailyGoalMl = baseGoal.clamp(1000.0, 5000.0);
    }

    // Persist the calculated goal on the user document so the Admin
    // dashboard can read it directly.
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'dailyWaterGoal': dailyGoalMl.round(),
    }, SetOptions(merge: true));
  } catch (_) {
    // If user data cannot be loaded, keep fallback goal.
  }

  // Divide the goal into 250ml increments and schedule evenly
  // between 08:00 and 22:00.
  const int incrementMl = 250;
  final int totalNotifications = (dailyGoalMl / incrementMl).ceil().clamp(
    1,
    40,
  ); // sane upper bound

  final int totalWindowMinutes = (endHour - startHour) * 60; // 14h = 840min
  final double stepMinutes = totalWindowMinutes / totalNotifications.toDouble();

  int id = 0;
  for (int i = 0; i < totalNotifications; i++) {
    final double minutesFromStart = stepMinutes * i;
    final int offsetMinutes = minutesFromStart.round();
    final int hour = startHour + offsetMinutes ~/ 60;
    final int minute = offsetMinutes % 60;

    await scheduleWaterReminder(id++, hour.clamp(0, 23), minute.clamp(0, 59));
  }
}

Future<void> cancelHydrationReminders() async {
  await flutterLocalNotificationsPlugin.cancelAll();
}

Future<void> scheduleWaterReminder(int id, int hour, int minute) async {
  final scheduledTime = _nextInstanceOfTime(hour, minute);

  try {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Time to Hydrate! 💧',
      'Drink 250ml of water to stay on track.',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_channel_id',
          'Water Reminders',
          importance: Importance.max,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction('drink_250ml', 'I Drank 250ml'),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  } catch (e) {
    debugPrint('Error scheduling notification: $e');
    throw Exception(
      'Failed to schedule notification. Please enable "Alarms & reminders" permission in Settings > Apps > VitaTrack.',
    );
  }

  // Save to Firestore for future notifications list
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('scheduled_notifications')
        .doc(id.toString())
        .set({
          'id': id,
          'title': 'Time to Hydrate! 💧',
          'message': 'Drink 250ml of water to stay on track.',
          'scheduledTime': scheduledTime.toIso8601String(),
          'incrementMl': 250,
        }, SetOptions(merge: true));
  } catch (e) {
    debugPrint('Error saving scheduled notification to Firestore: $e');
    throw Exception('Failed to save notification to Firestore: $e');
  }
}

void _onNotificationResponse(NotificationResponse response) {
  if (response.actionId == 'drink_250ml') {
    final notificationId = int.tryParse((response.id).toString()) ?? 0;
    _handleDrinkWaterAction(notificationId);
  }
}

Future<void> _handleDrinkWaterAction(int notificationId) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Atomically increment the currentIntake field by 250ml.
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'currentIntake': FieldValue.increment(250),
    }, SetOptions(merge: true));

    // Mark notification as drank in history
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notification_history')
        .doc(notificationId.toString())
        .update({'drank': true, 'drankTime': DateTime.now().toIso8601String()})
        .catchError((_) {
          // If notification doesn't exist in history, create it
          return FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('notification_history')
              .doc(notificationId.toString())
              .set({
                'id': notificationId.toString(),
                'notificationTime': DateTime.now().toIso8601String(),
                'title': 'Time to Hydrate! 💧',
                'message': 'Drink 250ml of water to stay on track.',
                'drank': true,
                'drankTime': DateTime.now().toIso8601String(),
                'incrementMl': 250,
              });
        });
  } catch (e) {
    debugPrint('Error handling drink water action: $e');
  }
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );

  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }

  return scheduledDate;
}

// Test notification - shows when app opens
Future<void> showAppLaunchNotification() async {
  try {
    await flutterLocalNotificationsPlugin.show(
      9999, // Unique ID for app launch notification
      'Welcome Back! 🎉',
      'Your app is now open. Ready to stay hydrated?',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'app_launch_channel',
          'App Launch Notifications',
          channelDescription: 'Notifications shown when app opens',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  } catch (e) {
    debugPrint('Error showing app launch notification: $e');
  }
}
