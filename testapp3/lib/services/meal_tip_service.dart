import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/meal_tip.dart';

class MealTipService {
  MealTipService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<MealTip>> streamMealTips() {
    final query = _db
        .collection('mealTips')
        .orderBy('createdAt', descending: false);

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map((doc) => MealTip.fromMap(doc.id, doc.data()))
              .toList(),
    );
  }
}
