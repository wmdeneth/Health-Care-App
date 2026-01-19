import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_history.dart';

class NotificationHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Log a notification when it's triggered
  Future<void> logNotification(
    int notificationId,
    String title,
    String message,
    int incrementMl,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final notificationHistory = NotificationHistory(
        id: notificationId.toString(),
        notificationTime: DateTime.now(),
        title: title,
        message: message,
        drank: false,
        incrementMl: incrementMl,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notification_history')
          .doc(notificationId.toString())
          .set(notificationHistory.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error logging notification: $e');
    }
  }

  // Mark a notification as drank
  Future<void> markAsDrank(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notification_history')
          .doc(notificationId)
          .update({
            'drank': true,
            'drankTime': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      debugPrint('Error marking as drank: $e');
    }
  }

  // Get past notifications (history)
  Future<List<NotificationHistory>> getPastNotifications({int days = 7}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notification_history')
              .where(
                'notificationTime',
                isLessThanOrEqualTo: DateTime.now().toIso8601String(),
              )
              .orderBy('notificationTime', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => NotificationHistory.fromJson(doc.data()))
          .where(
            (notification) => notification.notificationTime.isAfter(cutoffDate),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting past notifications: $e');
      return [];
    }
  }

  // Get future notifications (scheduled)
  Future<List<Map<String, dynamic>>> getFutureNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // This will be populated by the scheduling logic
      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('scheduled_notifications')
              .where(
                'scheduledTime',
                isGreaterThan: DateTime.now().toIso8601String(),
              )
              .orderBy('scheduledTime', descending: false)
              .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting future notifications: $e');
      return [];
    }
  }

  // Get today's notifications (for dashboard view)
  Future<List<NotificationHistory>> getTodayNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notification_history')
              .where(
                'notificationTime',
                isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
              )
              .where('notificationTime', isLessThan: endOfDay.toIso8601String())
              .orderBy('notificationTime', descending: false)
              .get();

      return snapshot.docs
          .map((doc) => NotificationHistory.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting today notifications: $e');
      return [];
    }
  }

  // Stream of past notifications for real-time updates
  Stream<List<NotificationHistory>> getPastNotificationsStream({int days = 7}) {
    try {
      final user = _auth.currentUser;
      if (user == null) return Stream.empty();

      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notification_history')
          .orderBy('notificationTime', descending: true)
          .snapshots()
          .map((snapshot) {
            final cutoffDate = DateTime.now().subtract(Duration(days: days));
            return snapshot.docs
                .map((doc) => NotificationHistory.fromJson(doc.data()))
                .where(
                  (notification) =>
                      notification.notificationTime.isAfter(cutoffDate),
                )
                .toList();
          });
    } catch (e) {
      debugPrint('Error getting notifications stream: $e');
      return Stream.empty();
    }
  }
}
