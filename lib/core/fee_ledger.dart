import 'format.dart';

class FeeLedger {
  FeeLedger(List<RecordData> invoices, List<RecordData> payments) {
    final allocated = <int, double>{};
    void dueDate(int member, Object? value) {
      final date = asDate(value);
      if (date != null &&
          (since[member] == null || date.isBefore(since[member]!))) {
        since[member] = date;
      }
    }

    for (final p in payments) {
      final member = p['member_id'] as int;
      if (p['status'] == 'completed') {
        final previous = last[member];
        if (previous == null ||
            (p['payment_date'] as int) > (previous['payment_date'] as int)) {
          last[member] = p;
        }
        final invoice = p['invoice_id'] as int?;
        if (invoice != null) {
          allocated[invoice] =
              (allocated[invoice] ?? 0) + (p['amount'] as num).toDouble();
        }
      } else if (p['status'] == 'pending' && p['invoice_id'] == null) {
        dues[member] = (dues[member] ?? 0) + (p['amount'] as num).toDouble();
        dueDate(member, p['payment_date']);
      }
    }
    for (final i in invoices) {
      final id = i['id'] as int, member = i['member_id'] as int;
      final balance = i['status'] == 'void'
          ? 0.0
          : ((i['amount'] as num).toDouble() - (allocated[id] ?? 0))
                .clamp(0, double.infinity)
                .toDouble();
      balances[id] = balance;
      dues[member] = (dues[member] ?? 0) + balance;
      if (balance > 0) dueDate(member, i['due_date']);
    }
  }
  final balances = <int, double>{}, dues = <int, double>{};
  final last = <int, RecordData>{};
  final since = <int, DateTime>{};
}
