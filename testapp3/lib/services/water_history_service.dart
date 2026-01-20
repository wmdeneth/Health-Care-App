import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/water_log.dart';

class WaterHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final WaterHistoryService instance = WaterHistoryService._();
  WaterHistoryService._();

  String get _today => DateTime.now().toIso8601String().split('T')[0];

  /// Adds water intake for today and updates history
  Future<void> addWater(int ml) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final data = userDoc.data() ?? {};

    final currentIntake = (data['currentIntake'] as num?)?.toInt() ?? 0;
    final dailyGoal = (data['dailyWaterGoal'] as num?)?.toInt() ?? 2000;

    final newTotal = currentIntake + ml;

    // Update daily history
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('water_history')
        .doc(_today)
        .set({
          'date': _today,
          'intake': newTotal,
          'goal': dailyGoal,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    // Update main user document
    await _firestore.collection('users').doc(uid).update({
      'currentIntake': newTotal,
      'lastWaterUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// Streams the water history for the last [days] days
  Stream<List<WaterLog>> getWaterHistoryStream({int days = 7}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('water_history')
        .orderBy('date', descending: true)
        .limit(days)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => WaterLog.fromMap(doc.data())).toList(),
        );
  }
}
