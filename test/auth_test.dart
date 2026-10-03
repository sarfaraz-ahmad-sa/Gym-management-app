import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitguide/services/auth_service.dart';
import 'package:fitguide/services/db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test(
    'owner setup replaces hardcoded login; password changes invalidate old password',
    () async {
      SharedPreferences.setMockInitialValues({});
      final db = DatabaseService(
        name: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final auth = AuthService(database: db);
      while (auth.loading) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(auth.needsSetup, isTrue);
      await auth.setup(
        name: 'Irfan',
        gymName: 'Test Gym',
        username: 'IRFAN',
        password: 'passphrase-123',
      );
      expect(auth.loggedIn, isTrue);
      final account = (await (await db.database).query('owner_account')).first;
      expect(account['password_hash'], isNot('passphrase-123'));
      await auth.logout();
      expect(await auth.login('admin', 'admin123'), isFalse);
      expect(await auth.login('irfan', 'wrong'), isFalse);
      expect(await auth.login('irfan', 'passphrase-123'), isTrue);
      await auth.changePassword('passphrase-123', 'new-passphrase-123');
      await auth.logout();
      expect(await auth.login('irfan', 'passphrase-123'), isFalse);
      expect(await auth.login('irfan', 'new-passphrase-123'), isTrue);
      expect((await db.exportData()).contains('password_hash'), isFalse);
      auth.dispose();
      await db.close();
    },
  );
}
