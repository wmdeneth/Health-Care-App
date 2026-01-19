class StepData {
  final DateTime date;
  final int steps;
  final double distance; // in kilometers
  final int calories; // estimated calories burned
  final String? notes;

  StepData({
    required this.date,
    required this.steps,
    this.distance = 0,
    this.calories = 0,
    this.notes,
  });

  factory StepData.fromJson(Map<String, dynamic> json) {
    return StepData(
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      steps: json['steps'] ?? 0,
      distance: (json['distance'] ?? 0).toDouble(),
      calories: json['calories'] ?? 0,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'steps': steps,
      'distance': distance,
      'calories': calories,
      'notes': notes,
    };
  }

  // Calculate distance based on average step length (0.762m per step)
  double calculateDistance() {
    return (steps * 0.762) / 1000; // convert to km
  }

  // Calculate calories (rough estimate: ~0.04 calories per step)
  int calculateCalories() {
    return (steps * 0.04).toInt();
  }
}

class StepGoal {
  final int dailyGoal;
  final DateTime startDate;
  final String? notes;

  StepGoal({required this.dailyGoal, required this.startDate, this.notes});

  factory StepGoal.fromJson(Map<String, dynamic> json) {
    return StepGoal(
      dailyGoal: json['dailyGoal'] ?? 10000,
      startDate:
          json['startDate'] != null
              ? DateTime.parse(json['startDate'])
              : DateTime.now(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyGoal': dailyGoal,
      'startDate': startDate.toIso8601String(),
      'notes': notes,
    };
  }
}
