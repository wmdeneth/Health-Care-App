import 'dart:math';
import 'package:flutter/services.dart'; // for PlatformException
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  NotificationService._private();
  static final NotificationService instance = NotificationService._private();

  bool _initialized = false;

  // initialize plugin (call once in main)
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          macOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        // handle notification tapped logic here if needed
      },
    );
    _initialized = true;
  }

  Future<void> scheduleWaterReminders({
    required int intervalHours,
    int days = 7,
  }) async {
    if (!_initialized) {
      try {
        await initialize();
      } catch (_) {
        // ignore init errors and continue — schedule() will handle fallbacks
      }
    }
    // cancel previous water reminders (simple approach)
    await cancelWaterReminders();

    final now = tz.TZDateTime.now(tz.local);
    // To avoid scheduling a very large number of notifications during
    // startup, only schedule the next 24 hours worth of reminders here.
    // The app may schedule the remaining reminders later in a background
    // task if needed.
    final totalHours = min(24, days * 24);
    final totalReminders = (totalHours / intervalHours).ceil();

    for (int i = 0; i < totalReminders; i++) {
      final scheduled = now.add(Duration(hours: i * intervalHours));
      final id = 5000 + i; // water reminder ids start at 5000
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        '💧 Time to drink water!',
        'Stay hydrated — take a sip now.',
        tz.TZDateTime.from(scheduled, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'water_channel_id',
            'Water Reminders',
            channelDescription: 'Reminds user to drink water',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // use androidScheduleMode if available in the plugin; fall back to
        // androidAllowWhileIdle to maintain compatibility with older versions.
        // The analyzer may flag androidAllowWhileIdle as deprecated in newer
        // plugin versions; keeping both here is a safe compromise.
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // Schedule remaining reminders (if days > 1) in the background to
    // avoid performing many plugin calls synchronously during startup.
    final maxImmediate = totalReminders;
    final overallReminders = (days * 24 / intervalHours).ceil();
    if (overallReminders > maxImmediate) {
      Future(() async {
        for (int i = maxImmediate; i < overallReminders; i++) {
          try {
            final scheduled = now.add(Duration(hours: i * intervalHours));
            final id = 5000 + i;
            await Future.delayed(const Duration(milliseconds: 60));
            await flutterLocalNotificationsPlugin.zonedSchedule(
              id,
              '💧 Time to drink water!',
              'Stay hydrated — take a sip now.',
              tz.TZDateTime.from(scheduled, tz.local),
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'water_channel_id',
                  'Water Reminders',
                  channelDescription: 'Reminds user to drink water',
                  importance: Importance.max,
                  priority: Priority.high,
                  playSound: true,
                ),
                iOS: DarwinNotificationDetails(),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
          } catch (e) {
            debugPrint('Background schedule failed for reminder $i: $e');
          }
        }
      });
    }
  }

  Future<void> cancelWaterReminders() async {
    // cancel ids 5000..(5000+1000) reasonably large range
    for (int i = 0; i < 2000; i++) {
      await flutterLocalNotificationsPlugin.cancel(5000 + i);
    }
  }

  // Schedule a single notification at a specific time (used by SmartWaterReminder)
  Future<void> scheduleSingleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
  }) async {
    if (!_initialized) {
      try {
        await initialize();
      } catch (_) {
        // ignore
      }
    }
    final tz.TZDateTime scheduled = tz.TZDateTime.from(
      scheduledDateTime,
      tz.local,
    );

    try {
      // First attempt: prefer exact/allow while idle (best effort)
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'water_channel_id',
            'Water Reminders',
            channelDescription: 'Reminds user to drink water',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      // If we reached here, scheduling with exact alarms succeeded — record
      // that exact alarms are permitted so the UI need not show a warning.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('exact_alarms_permitted', true);
      } catch (_) {
        // ignore
      }
      return;
    } on PlatformException catch (e) {
      // Handle the "exact_alarms_not_permitted" error gracefully and retry with inexact scheduling
      if (e.code == 'exact_alarms_not_permitted' ||
          (e.message?.toLowerCase().contains('exact alarm') ?? false)) {
        // Persist that exact alarms are not permitted so the UI can inform the user
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('exact_alarms_permitted', false);
        } catch (_) {
          // ignore
        }
        // Fallback option 1: schedule without exact allowance (may be inexact)
        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            scheduled,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'water_channel_id',
                'Water Reminders',
                channelDescription: 'Reminds user to drink water',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
                playSound: true,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            // Do not request exact alarms; let OS schedule it inexactly
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (_) {
          // Final fallback: use zonedSchedule with an inexact schedule mode
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            scheduled,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'water_channel_id',
                'Water Reminders',
                channelDescription: 'Reminds user to drink water',
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      } else {
        // Re-throw/propagate other platform exceptions
        rethrow;
      }
    }
  }

  // Cancel smart (adaptive) reminder(s) - use IDs in the 6000..6999 range
  Future<void> cancelSmartReminders() async {
    for (int i = 0; i < 1000; i++) {
      await flutterLocalNotificationsPlugin.cancel(6000 + i);
    }
  }
}
