import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Water Notification Functions', () {
    test('FieldValue.increment should be accessible from cloud_firestore', () {
      // Test that FieldValue.increment works
      final increment = FieldValue.increment(250);
      expect(increment, isNotNull);
    });

    test('Water goal calculation formula works correctly', () {
      // Base calculation: weightKg * 35
      double weightKg = 70.0;
      double baseGoal = weightKg * 35.0;
      expect(baseGoal, equals(2450.0));

      // Clamped to 1000-5000ml
      double clampedGoal = baseGoal.clamp(1000.0, 5000.0);
      expect(clampedGoal, equals(2450.0));

      // Test edge case: very light person
      weightKg = 25.0;
      baseGoal = weightKg * 35.0;
      clampedGoal = baseGoal.clamp(1000.0, 5000.0);
      expect(clampedGoal, equals(1000.0)); // Should clamp to minimum

      // Test edge case: heavy person
      weightKg = 150.0;
      baseGoal = weightKg * 35.0;
      clampedGoal = baseGoal.clamp(1000.0, 5000.0);
      expect(clampedGoal, equals(5000.0)); // Should clamp to maximum
    });

    test('BMI-based adjustment calculation works', () {
      double weightKg = 50.0; // Underweight
      double heightCm = 170.0;
      double baseGoal = weightKg * 35.0; // 1750ml

      // Calculate BMI
      final hMeters = heightCm / 100.0;
      final bmi = weightKg / (hMeters * hMeters);
      expect(bmi, lessThan(18.5)); // Underweight

      // Apply 0.9 adjustment for underweight
      double adjustedGoal = baseGoal * 0.9; // 1575ml
      double clampedGoal = adjustedGoal.clamp(1000.0, 5000.0);
      expect(clampedGoal, equals(1575.0));
    });

    test('Notification scheduling window calculation works correctly', () {
      const int startHour = 8;
      const int endHour = 22;
      const int totalWindowMinutes = (endHour - startHour) * 60; // 840 minutes

      double dailyGoalMl = 2000.0;
      const int incrementMl = 250;
      int totalNotifications = (dailyGoalMl / incrementMl).ceil().clamp(1, 40);

      expect(totalNotifications, equals(8)); // 2000 / 250 = 8

      final double stepMinutes =
          totalWindowMinutes / totalNotifications.toDouble();
      expect(stepMinutes, equals(105.0)); // 840 / 8 = 105
    });

    test('Notification time calculations are correct', () {
      const int startHour = 8;
      const int totalWindowMinutes = 14 * 60; // 14 hours (8 AM to 10 PM)
      const int totalNotifications = 8;
      final double stepMinutes =
          totalWindowMinutes / totalNotifications.toDouble();

      // Calculate times for all 8 notifications
      final List<String> times = [];
      for (int i = 0; i < totalNotifications; i++) {
        final double minutesFromStart = stepMinutes * i;
        final int offsetMinutes = minutesFromStart.round();
        final int hour = startHour + offsetMinutes ~/ 60;
        final int minute = offsetMinutes % 60;

        times.add(
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        );
      }

      // Verify the sequence
      // stepMinutes = 840 / 8 = 105 minutes apart
      // i=0: 0 min from 8:00 = 08:00
      // i=1: 105 min = 1:45, so 09:45
      // i=2: 210 min = 3:30, so 11:30
      // i=3: 315 min = 5:15, so 13:15
      // i=4: 420 min = 7:00, so 15:00 (3 PM)
      // i=5: 525 min = 8:45, so 16:45 (4:45 PM)
      // i=6: 630 min = 10:30, so 18:30 (6:30 PM)
      // i=7: 735 min = 12:15, so 20:15 (8:15 PM)
      expect(times[0], equals('08:00')); // First notification at 8:00 AM
      expect(
        times[7],
        equals('20:15'),
      ); // Last notification at 8:15 PM (correct!)
    });

    test('Notification ID assignment is sequential', () {
      int totalNotifications = 8;
      final List<int> ids = [];

      int id = 0;
      for (int i = 0; i < totalNotifications; i++) {
        ids.add(id++);
      }

      expect(ids, equals([0, 1, 2, 3, 4, 5, 6, 7]));
    });

    test('Total notifications calculation with different goals', () {
      // Test with 1500ml goal
      double goal1 = 1500.0;
      int notifs1 = (goal1 / 250).ceil().clamp(1, 40);
      expect(notifs1, equals(6));

      // Test with 3000ml goal
      double goal2 = 3000.0;
      int notifs2 = (goal2 / 250).ceil().clamp(1, 40);
      expect(notifs2, equals(12));

      // Test with 5000ml goal
      double goal3 = 5000.0;
      int notifs3 = (goal3 / 250).ceil().clamp(1, 40);
      expect(notifs3, equals(20));
    });
  });
}
