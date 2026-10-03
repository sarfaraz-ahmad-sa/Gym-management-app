class Payment {
  int? id;
  int memberId;
  int? planId; // optional: membership plan ID
  double amount;
  DateTime paymentDate;
  String status; // pending, completed, failed
  String? paymentMethod; // cash, card, online
  String? transactionId;

  Payment({
    this.id,
    required this.memberId,
    this.planId,
    required this.amount,
    required this.paymentDate,
    required this.status,
    this.paymentMethod,
    this.transactionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'plan_id': planId,
      'amount': amount,
      'payment_date': paymentDate.millisecondsSinceEpoch,
      'status': status,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      memberId: map['member_id'],
      planId: map['plan_id'],
      amount: map['amount'],
      paymentDate: DateTime.fromMillisecondsSinceEpoch(map['payment_date']),
      status: map['status'],
      paymentMethod: map['payment_method'],
      transactionId: map['transaction_id'],
    );
  }
}