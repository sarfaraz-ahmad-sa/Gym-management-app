class InventoryItem {
  int? id;
  String name;
  String category; // e.g., cardio, strength, accessories
  int quantity;
  String? condition; // good, fair, poor
  double? purchasePrice;
  DateTime? purchaseDate;
  String? notes;

  InventoryItem({
    this.id,
    required this.name,
    required this.category,
    required this.quantity,
    this.condition,
    this.purchasePrice,
    this.purchaseDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'condition': condition,
      'purchase_price': purchasePrice,
      'purchase_date': purchaseDate?.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      quantity: map['quantity'],
      condition: map['condition'],
      purchasePrice: map['purchase_price'],
      purchaseDate: map['purchase_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['purchase_date'])
          : null,
      notes: map['notes'],
    );
  }
}