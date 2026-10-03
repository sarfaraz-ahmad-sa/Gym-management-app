import 'package:intl/intl.dart';

typedef RecordData = Map<String, Object?>;
DateTime? asDate(Object? value) =>
    value is num ? DateTime.fromMillisecondsSinceEpoch(value.toInt()) : null;
String dateLabel(Object? value, [String format = 'd MMM yyyy']) =>
    asDate(value) == null ? '—' : DateFormat(format).format(asDate(value)!);
String money(Object? value, [String currency = 'PKR']) =>
    '$currency ${NumberFormat('#,##0').format((value as num?) ?? 0)}';
String titleCase(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}')
    .join(' ');
String initials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .take(2)
    .map((s) => s.isEmpty ? '' : s[0].toUpperCase())
    .join();
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
