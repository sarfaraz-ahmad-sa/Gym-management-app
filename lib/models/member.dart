class Member {
  int? id;
  String name;
  String phone;
  String? email;
  String? address;
  DateTime? joinDate;
  int? planId; // Membership plan ID
  String? status; // active, inactive, suspended

  Member({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.joinDate,
    this.planId,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'join_date': joinDate?.millisecondsSinceEpoch,
      'plan_id': planId,
      'status': status,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      joinDate: map['join_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['join_date'])
          : null,
      planId: map['plan_id'],
      status: map['status'],
    );
  }
}