import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../core/gym_store.dart';
import '../core/format.dart';
import '../core/fee_ledger.dart';
import 'db_service.dart';
import 'export_service.dart';

String csvCell(Object? value) {
  var text = (value ?? '').toString();
  if (RegExp(r'^[=+@\-\t\r]').hasMatch(text)) text = "'$text";
  return '"${text.replaceAll('"', '""')}"';
}

Future<void> exportWorkspace(GymStore store) async {
  final json = await store.db.exportData();
  final backup = jsonDecode(json) as Map;
  final tables = backup['tables'] as Map;
  final archive = Archive();
  void add(String filename, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(filename, bytes.length, bytes));
  }

  add('workspace-backup.json', json);
  add(
    'README.txt',
    '${store.gymName}\nExported: ${backup['exported_at']}\nContains all workspace records and settings. Owner passwords and sessions are excluded. Cloud CSV exports are read in pages; pause edits during export if a single point-in-time copy is required.\n',
  );
  for (final table in [...dataTables, 'settings']) {
    final rows = (tables[table] as List)
        .map((r) => Map<String, Object?>.from(r as Map))
        .toList();
    final keys = rows.isEmpty
        ? <String>['id']
        : rows.expand((r) => r.keys).toSet().toList();
    add(
      '$table.csv',
      [
        keys.map(csvCell).join(','),
        ...rows.map((r) => keys.map((k) => csvCell(r[k])).join(',')),
      ].join('\r\n'),
    );
  }
  // Human-friendly balance report resolves member names from the exported data.
  final members = (tables['members'] as List).map(
    (r) => Map<String, Object?>.from(r as Map),
  );
  final receipts = (tables['payments'] as List)
      .map((r) => Map<String, Object?>.from(r as Map))
      .toList();
  final invoices = (tables['fee_invoices'] as List)
      .map((r) => Map<String, Object?>.from(r as Map))
      .toList();
  final lines = <List<Object?>>[
    [
      'Member',
      'Phone',
      'Pending amount',
      'Currency',
      'Last payment amount',
      'Last payment date',
    ],
  ];
  final ledger = FeeLedger(invoices, receipts);
  for (final m in members) {
    final id = m['id'] as int, last = ledger.last[id];
    lines.add([
      m['name'],
      m['phone'],
      ledger.dues[id] ?? 0,
      store.currency,
      last?['amount'] ?? '',
      last == null ? '' : dateLabel(last['payment_date']),
    ]);
  }
  add(
    'member-balances.csv',
    lines.map((r) => r.map(csvCell).join(',')).join('\r\n'),
  );
  final encoded = ZipEncoder().encode(archive)!;
  await downloadBytes(
    'fitguide-workspace-${DateTime.now().toIso8601String().substring(0, 10)}.zip',
    Uint8List.fromList(encoded),
    'application/zip',
  );
}
