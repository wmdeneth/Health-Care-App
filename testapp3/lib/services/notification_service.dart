import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'water_history_service.dart';

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

  // Start listening for admin broadcasts from web panel
  listenToAdminNotifications();
}

// --- Admin Notification Listener ---
void listenToAdminNotifications() {
  final now = DateTime.now();
  FirebaseFirestore.instance
      .collection('adminNotifications')
      .where('createdAt', isGreaterThan: Timestamp.fromDate(now))
      .snapshots()
      .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data != null) {
              _showAdminBroadcast(
                data['title'] ?? 'New Update',
                data['message'] ?? '',
              );
            }
          }
        }
      });
}

Future<void> _showAdminBroadcast(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'admin_updates',
        'Admin Updates',
        channelDescription: 'Notifications sent by administrators',
        importance: Importance.max,
        priority: Priority.high,
      );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );
  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecond, // Unique ID
    title,
    body,
    platformChannelSpecifics,
  );
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

  // Fetch user settings from Firestore
  int startHour = 8;
  int endHour = 22;
  double dailyGoalMl = 2000;

  try {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = doc.data() ?? <String, dynamic>{};

    bool waterEnabled = data['waterEnabled'] as bool? ?? false;
    if (!waterEnabled) {
      debugPrint('Water reminders are disabled for this user.');
      return;
    }

    // Load Admin/User preferences
    if (data['waterStartHour'] != null) {
      startHour = (data['waterStartHour'] as num).toInt();
    }
    if (data['waterEndHour'] != null) {
      endHour = (data['waterEndHour'] as num).toInt();
    }

    // Check if goal is already set (Admin override or previously calculated)
    if (data['dailyWaterGoal'] != null && (data['dailyWaterGoal'] as num) > 0) {
      dailyGoalMl = (data['dailyWaterGoal'] as num).toDouble();
    } else {
      // Calculate based on weight if not set
      final weightKg = (data['weightKg'] as num?)?.toDouble();
      final heightCm = (data['heightCm'] as num?)?.toDouble();

      if (weightKg != null && weightKg > 0) {
        double baseGoal = weightKg * 35.0;

        // Optional BMI-based adjustment
        if (heightCm != null && heightCm > 0) {
          final hMeters = heightCm / 100.0;
          final bmi = weightKg / (hMeters * hMeters);

          if (bmi < 18.5) {
            baseGoal *= 0.9;
          } else if (bmi > 30) {
            baseGoal *= 1.1;
          }
        }

        dailyGoalMl = baseGoal.clamp(1000.0, 5000.0);

        // Persist the calculated goal
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'dailyWaterGoal': dailyGoalMl.round(),
        }, SetOptions(merge: true));
      }
    }
  } catch (e) {
    debugPrint("Error loading user settings for water schedule: $e");
    // Continue with defaults
  }

  // Divide the goal into 250ml increments and schedule evenly
  const int incrementMl = 250;
  final int totalNotifications = (dailyGoalMl / incrementMl).ceil().clamp(
    1,
    40,
  ); // sane upper bound

  final int totalWindowMinutes = (endHour - startHour) * 60;

  // If window is invalid (e.g. start > end), default to 8-22
  if (totalWindowMinutes <= 0) {
    debugPrint("Invalid time window ($startHour-$endHour), using default.");
    await scheduleWaterReminder(0, 8, 0); // Scheduling just one as fallback
    return;
  }

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
            AndroidNotificationAction('drink_250ml', 'Accept / Drink 250ml'),
            AndroidNotificationAction('reject_water', 'Reject / Skip'),
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
  } else if (response.actionId == 'reject_water') {
    // Just dismiss (default behavior) or log rejection if needed
    debugPrint('User rejected water notification');
  }
}

Future<void> _handleDrinkWaterAction(int notificationId) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Use WaterHistoryService to update both main doc and daily history
    await WaterHistoryService.instance.addWater(250);

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
