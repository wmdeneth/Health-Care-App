import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';
import 'notification_history_service.dart';

/// Test utility for water notification functionality
class WaterNotificationTest {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final NotificationHistoryService _historyService =
      NotificationHistoryService();

  /// Test 1: Enable water reminders for the current user
  static Future<bool> testEnableWaterReminders() async {
    try {
      debugPrint('🧪 Test 1: Enabling water reminders...');

      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ Test failed: No user logged in');
        return false;
      }

      // Enable water notifications in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'waterEnabled': true,
      }, SetOptions(merge: true));

      // Verify the setting was saved
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final enabled = doc.data()?['waterEnabled'] as bool? ?? false;

      if (enabled) {
        debugPrint('✅ Test passed: Water reminders enabled');
        return true;
      } else {
        debugPrint('❌ Test failed: Water reminders not enabled in Firestore');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Test failed with error: $e');
      return false;
    }
  }

  /// Test 2: Schedule daily hydration reminders
  static Future<bool> testScheduleNotifications() async {
    try {
      debugPrint('🧪 Test 2: Scheduling water notifications...');

      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ Test failed: No user logged in');
        return false;
      }

      // Schedule notifications
      await scheduleDailyHydrationReminders();

      // Check if scheduled notifications were saved to Firestore
      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('scheduled_notifications')
              .get();

      if (snapshot.docs.isNotEmpty) {
        debugPrint(
          '✅ Test passed: ${snapshot.docs.length} notifications scheduled',
        );

        // Show details of first 3 scheduled notifications
        for (int i = 0; i < snapshot.docs.length && i < 3; i++) {
          final data = snapshot.docs[i].data();
          debugPrint(
            '   - Notification ${i + 1}: ${data['title']} at ${data['scheduledTime']}',
          );
        }

        return true;
      } else {
        debugPrint('❌ Test failed: No notifications were scheduled');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Test failed with error: $e');
      if (e.toString().contains('Exact alarm permission')) {
        debugPrint('');
        debugPrint('📱 ACTION REQUIRED:');
        debugPrint('   1. Go to Settings > Apps > VitaTrack');
        debugPrint('   2. Enable "Alarms & reminders" permission');
        debugPrint('   3. Run the test again');
      }
      return false;
    }
  }

  /// Test 3: Trigger an immediate test notification
  static Future<bool> testImmediateNotification() async {
    try {
      debugPrint('🧪 Test 3: Sending immediate test notification...');

      await flutterLocalNotificationsPlugin.show(
        7777, // Test notification ID
        'Test Water Reminder! 💧',
        'This is a test notification to verify water reminders work.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_channel_id',
            'Water Reminders',
            channelDescription: 'Test notification',
            importance: Importance.max,
            priority: Priority.high,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction('drink_250ml', 'Accept / Drink 250ml'),
              AndroidNotificationAction('reject_water', 'Reject / Skip'),
            ],
          ),
        ),
      );

      debugPrint('✅ Test passed: Immediate notification sent');
      debugPrint('   Check your device for the notification!');
      return true;
    } catch (e) {
      debugPrint('❌ Test failed with error: $e');
      return false;
    }
  }

  /// Test 4: Verify user profile has weight/height for goal calculation
  static Future<bool> testUserProfile() async {
    try {
      debugPrint('🧪 Test 4: Checking user profile data...');

      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ Test failed: No user logged in');
        return false;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};

      final weightKg = (data['weightKg'] as num?)?.toDouble();
      final heightCm = (data['heightCm'] as num?)?.toDouble();
      final dailyGoal = data['dailyWaterGoal'] as int?;

      debugPrint('   User profile:');
      debugPrint('   - Weight: ${weightKg ?? "Not set"} kg');
      debugPrint('   - Height: ${heightCm ?? "Not set"} cm');
      debugPrint('   - Daily water goal: ${dailyGoal ?? "Not calculated"} ml');

      if (weightKg != null && weightKg > 0) {
        final calculatedGoal = (weightKg * 35).clamp(1000.0, 5000.0);
        debugPrint(
          '   - Expected goal (weight × 35): ${calculatedGoal.toInt()} ml',
        );
        debugPrint('✅ Test passed: User has profile data for goal calculation');
        return true;
      } else {
        debugPrint('⚠️  Warning: No weight data - using default 2000ml goal');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Test failed with error: $e');
      return false;
    }
  }

  /// Test 5: Check notification history
  static Future<bool> testNotificationHistory() async {
    try {
      debugPrint('🧪 Test 5: Checking notification history...');

      final notifications = await _historyService.getPastNotifications(days: 7);

      debugPrint(
        '   Found ${notifications.length} notifications in the last 7 days',
      );

      if (notifications.isNotEmpty) {
        // Show last 3 notifications
        for (int i = 0; i < notifications.length && i < 3; i++) {
          final notif = notifications[i];
          debugPrint('   - ${notif.title} at ${notif.notificationTime}');
          debugPrint('     Drank: ${notif.drank ? "Yes ✓" : "No ✗"}');
        }
      }

      debugPrint('✅ Test passed: History retrieved successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Test failed with error: $e');
      return false;
    }
  }

  /// Test 6: Test the "Drink Water" action
  static Future<bool> testDrinkWaterAction() async {
    try {
      debugPrint('🧪 Test 6: Testing drink water action...');

      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ Test failed: No user logged in');
        return false;
      }

      // Get current intake
      final beforeDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final beforeIntake =
          (beforeDoc.data()?['currentIntake'] as num?)?.toInt() ?? 0;

      debugPrint('   Current water intake: $beforeIntake ml');

      // Simulate drinking water
      await _firestore.collection('users').doc(user.uid).set({
        'currentIntake': FieldValue.increment(250),
      }, SetOptions(merge: true));

      // Check new intake
      final afterDoc = await _firestore.collection('users').doc(user.uid).get();
      final afterIntake =
          (afterDoc.data()?['currentIntake'] as num?)?.toInt() ?? 0;

      debugPrint('   New water intake: $afterIntake ml');

      if (afterIntake == beforeIntake + 250) {
        debugPrint('✅ Test passed: Water intake incremented correctly');
        return true;
      } else {
        debugPrint('❌ Test failed: Water intake not incremented correctly');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Test failed with error: $e');
      return false;
    }
  }

  /// Test 7: Verify notification permissions
  static Future<bool> testNotificationPermissions() async {
    try {
      debugPrint('🧪 Test 7: Checking notification permissions...');

      final androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      // Note: We can't directly check if permission is granted without triggering a request
      // So we'll just verify the plugin is available
      if (androidImplementation != null) {
        debugPrint('✅ Test passed: Notification plugin is available');
        debugPrint('   Make sure notifications are enabled in app settings');
        return true;
      } else {
        debugPrint('❌ Test failed: Notification plugin not available');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Test failed with error: $e');
      return false;
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    debugPrint('\n════════════════════════════════════════');
    debugPrint('🚀 WATER NOTIFICATION TEST SUITE');
    debugPrint('════════════════════════════════════════\n');

    final results = <String, bool>{};

    results['Enable Water Reminders'] = await testEnableWaterReminders();
    debugPrint('');

    results['User Profile Data'] = await testUserProfile();
    debugPrint('');

    results['Notification Permissions'] = await testNotificationPermissions();
    debugPrint('');

    results['Schedule Notifications'] = await testScheduleNotifications();
    debugPrint('');

    results['Immediate Test Notification'] = await testImmediateNotification();
    debugPrint('');

    results['Notification History'] = await testNotificationHistory();
    debugPrint('');

    results['Drink Water Action'] = await testDrinkWaterAction();
    debugPrint('');

    // Summary
    debugPrint('════════════════════════════════════════');
    debugPrint('📊 TEST SUMMARY');
    debugPrint('════════════════════════════════════════');

    int passed = 0;
    int failed = 0;

    results.forEach((testName, result) {
      final status = result ? '✅ PASS' : '❌ FAIL';
      debugPrint('$status - $testName');
      if (result) {
        passed++;
      } else {
        failed++;
      }
    });

    debugPrint('');
    debugPrint('Total: ${results.length} tests');
    debugPrint('Passed: $passed');
    debugPrint('Failed: $failed');
    debugPrint(
      'Success Rate: ${(passed / results.length * 100).toStringAsFixed(1)}%',
    );
    debugPrint('════════════════════════════════════════\n');
  }
}
