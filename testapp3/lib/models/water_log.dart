class WaterLog {
  final String date; // YYYY-MM-DD
  final int intake;
  final int goal;

  WaterLog({required this.date, required this.intake, required this.goal});

  Map<String, dynamic> toMap() {
    return {'date': date, 'intake': intake, 'goal': goal};
  }

  factory WaterLog.fromMap(Map<String, dynamic> map) {
    return WaterLog(
      date: map['date'] as String? ?? '',
      intake: (map['intake'] as num?)?.toInt() ?? 0,
      goal: (map['goal'] as num?)?.toInt() ?? 2000,
    );
  }
}
