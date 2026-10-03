class MembershipPlan {
  int? id;
  String name;
  String description;
  double price;
  int durationDays; // duration in days
  String? features; // comma separated

  MembershipPlan({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    this.features,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration_days': durationDays,
      'features': features,
    };
  }

  factory MembershipPlan.fromMap(Map<String, dynamic> map) {
    return MembershipPlan(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'],
      durationDays: map['duration_days'],
      features: map['features'],
    );
  }
}