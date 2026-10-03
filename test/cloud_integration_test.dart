import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitguide/services/cloud_api.dart';
import 'package:fitguide/services/auth_service.dart';
import 'package:fitguide/core/gym_store.dart';
import 'package:fitguide/core/message_templates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  test(
    'Flutter owner and cloud store complete a shared workspace fee flow through the real Node API',
    () async {
      SharedPreferences.setMockInitialValues({});
      final dir = await Directory.systemTemp.createTemp('fitguide-cloud-');
      final probe = await ServerSocket.bind('127.0.0.1', 0);
      final port = probe.port;
      await probe.close();
      final server = await Process.start(
        'node',
        ['server/dev.js'],
        workingDirectory: Directory.current.path,
        environment: {
          'TURSO_DATABASE_URL': 'file:${dir.path}/cloud.db',
          'SETUP_CODE': 'private-test-code',
          'PORT': '$port',
        },
      );
      final errors = <String>[];
      server.stderr.transform(utf8.decoder).listen(errors.add);
      GymStore? store;
      AuthService? auth;
      try {
        await server.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .firstWhere((line) => line.contains('listening'))
            .timeout(const Duration(seconds: 15));
        final api = CloudApi(baseUrl: 'http://localhost:$port');
        auth = AuthService(cloud: api);
        while (auth.loading) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        await auth.setup(
          name: 'Owner',
          gymName: 'My Strong Gym',
          username: 'owner.test',
          password: 'SecurePassword123!',
          setupCode: 'private-test-code',
        );
        expect(auth.loggedIn, isTrue);
        expect(auth.db.isCloud, isTrue);
        store = GymStore(auth.db);
        await store.load();
        expect(store.error, isNull);
        expect(store.gymName, 'My Strong Gym');
        await store.save('membership_plans', {
          'name': 'Monthly',
          'price': 5000.0,
          'duration_days': 30,
        });
        await store.save('members', {
          'name': 'Sarfaraz',
          'phone': '03001234567',
          'join_date': DateTime.now().millisecondsSinceEpoch,
          'plan_id': store.rows('membership_plans').first['id'],
          'status': 'active',
        });
        expect(await store.generateFees('2026-10', DateTime(2026, 10, 1)), 1);
        expect(await store.generateFees('2026-10', DateTime(2026, 10, 1)), 0);
        final member = store.rows('members').first,
            invoice = store.rows('fee_invoices').first,
            id = member['id'] as int;
        await store.save('payments', {
          'member_id': id,
          'invoice_id': invoice['id'],
          'amount': 2000.0,
          'payment_date': DateTime(2026, 10, 2).millisecondsSinceEpoch,
          'status': 'completed',
        }, operationId: 'integration-payment-one');
        expect(store.memberDue(id), 3000);
        final message = memberMessage(store, member, 'payment');
        expect(message, contains('Sarfaraz'));
        expect(message, contains('3,000'));
        expect(message, contains('2,000'));
        expect(message, contains('October 2026'));
        expect(message, contains('Regards,\nMy Strong Gym'));
        final backup = await store.db.exportData();
        expect(backup, contains('fee_invoices'));
        expect(backup, isNot(contains('password_hash')));
        final originalWorkspace = auth.workspaceId;
        await auth.createWorkspace('Second Gym');
        expect(auth.workspaceId, isNot(originalWorkspace));
        final second = GymStore(auth.db);
        await second.load();
        expect(second.rows('members'), isEmpty);
        await second.db.importData(backup);
        await second.load();
        expect(
          second.memberDue(second.rows('members').first['id'] as int),
          3000,
        );
        second.dispose();
        await auth.selectWorkspace(originalWorkspace!);
        await store.load();
        expect(store.rows('members').length, 1);
        await auth.logout();
        expect(auth.loggedIn, isFalse);
        expect(errors, isEmpty);
      } finally {
        store?.dispose();
        auth?.dispose();
        server.kill();
        await server.exitCode;
        await dir.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
