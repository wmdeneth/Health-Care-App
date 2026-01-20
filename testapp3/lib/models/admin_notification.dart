import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String type; // 'global' or 'user'

  AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
  });

  factory AdminNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'global',
    );
  }
}
