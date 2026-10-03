class Trainer {
  int? id;
  String name;
  String phone;
  String? email;
  String? specialization;
  DateTime? hireDate;
  String? status; // active, inactive

  Trainer({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    this.specialization,
    this.hireDate,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'specialization': specialization,
      'hire_date': hireDate?.millisecondsSinceEpoch,
      'status': status,
    };
  }

  factory Trainer.fromMap(Map<String, dynamic> map) {
    return Trainer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      specialization: map['specialization'],
      hireDate: map['hire_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['hire_date'])
          : null,
      status: map['status'],
    );
  }
}