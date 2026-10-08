// models/promo_model.dart
class Promo {
  String? id;
  String restaurantId;
  String title;
  String description;
  List<String> terms;
  List<String> menuItems; // empty for "Semua Menu"
  double discount;
  DateTime startDate;
  DateTime endDate;
  bool isActive;
  DateTime createdAt;

  Promo({
    this.id,
    required this.restaurantId,
    required this.title,
    required this.description,
    required this.terms,
    required this.menuItems,
    required this.discount,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.createdAt,
  });

  factory Promo.fromMap(Map<String, dynamic> map) {
    return Promo(
      id: map['id'],
      restaurantId: map['restaurantId'],
      title: map['title'],
      description: map['description'],
      terms: List<String>.from(map['terms']),
      menuItems: map['menuItems'] != null
          ? List<String>.from(map['menuItems'])
          : [],
      discount: map['discount'].toDouble(),
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      isActive: map['isActive'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'title': title,
      'description': description,
      'terms': terms,
      'menuItems': menuItems,
      'discount': discount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
