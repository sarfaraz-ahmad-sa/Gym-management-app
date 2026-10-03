class Attendance {
  int? id;
  int memberId;
  DateTime checkIn;
  DateTime? checkOut;
  String? notes;

  Attendance({
    this.id,
    required this.memberId,
    required this.checkIn,
    this.checkOut,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'check_in': checkIn.millisecondsSinceEpoch,
      'check_out': checkOut?.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      memberId: map['member_id'],
      checkIn: DateTime.fromMillisecondsSinceEpoch(map['check_in']),
      checkOut: map['check_out'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['check_out'])
          : null,
      notes: map['notes'],
    );
  }
}