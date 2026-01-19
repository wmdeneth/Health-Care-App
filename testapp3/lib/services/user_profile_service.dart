import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

class UserProfileService {
  UserProfileService._();

  static final UserProfileService instance = UserProfileService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  String? get _uid => _auth.currentUser?.uid;

  Future<UserProfile> loadProfile() async {
    final uid = _uid;
    if (uid == null) {
      return UserProfile.empty();
    }

    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) {
      return UserProfile.empty();
    }

    return UserProfile.fromMap(doc.data() ?? <String, dynamic>{});
  }

  Future<void> saveProfile(UserProfile profile) async {
    final uid = _uid;
    if (uid == null) return;

    // Calculate daily water goal based on weight
    int dailyWaterGoal = 2000; // Default goal
    if (profile.weightKg != null && profile.weightKg! > 0) {
      // Formula: weightKg × 35ml
      double baseGoal = profile.weightKg! * 35.0;

      // BMI-based adjustment if height is available
      if (profile.heightCm != null && profile.heightCm! > 0) {
        final hMeters = profile.heightCm! / 100.0;
        final bmi = profile.weightKg! / (hMeters * hMeters);

        if (bmi < 18.5) {
          // Underweight – reduce by 10%
          baseGoal *= 0.9;
        } else if (bmi > 30) {
          // Obese – increase by 10%
          baseGoal *= 1.1;
        }
      }

      // Clamp to safe range: 1000ml - 5000ml
      dailyWaterGoal = baseGoal.clamp(1000.0, 5000.0).round();
    }

    // Save profile with calculated water goal
    final profileData = profile.toMap();
    profileData['dailyWaterGoal'] = dailyWaterGoal;

    await _usersCollection.doc(uid).set(profileData, SetOptions(merge: true));
  }
}
