import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_notification.dart';

class AdminNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AdminNotification>> getAdminNotificationsStream() {
    return _firestore.collection('adminNotifications').snapshots().map((
      snapshot,
    ) {
      final list =
          snapshot.docs
              .map((doc) => AdminNotification.fromFirestore(doc))
              .toList();
      // Sort in memory to avoid index requirements
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
