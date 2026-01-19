class MealTip {
  final String id;
  final String title;
  final String subtitle;
  final String colorHex;

  const MealTip({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.colorHex,
  });

  factory MealTip.fromMap(String id, Map<String, dynamic> data) {
    return MealTip(
      id: id,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      colorHex: data['colorHex'] as String? ?? '#FF8A65',
    );
  }
}
