/// Simple data model no longer tied to Firestore.
class Item {
  final String id;
  final String title;
  final DateTime? createdAt;

  const Item({required this.id, required this.title, this.createdAt});
}
