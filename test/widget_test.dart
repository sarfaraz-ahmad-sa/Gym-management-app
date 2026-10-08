import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitguide/core/gym_store.dart';
import 'package:fitguide/core/theme.dart';
import 'package:fitguide/core/entities.dart';
import 'package:fitguide/services/auth_service.dart';
import 'package:fitguide/services/db_service.dart';
import 'package:fitguide/screens/app_shell.dart';
import 'package:fitguide/widgets/record_editor.dart';
import 'package:fitguide/screens/fees_screen.dart';
import 'package:fitguide/screens/settings_screen.dart';
import 'package:fitguide/screens/messages_screen.dart';
import 'package:fitguide/screens/attendance_screen.dart';
import 'package:fitguide/screens/records_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late DatabaseService db;
  late GymStore store;
  late AuthService auth;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = DatabaseService(
      name: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    store = GymStore(db, demo: true);
    await store.initialize();
    auth = AuthService(database: db);
    while (auth.loading) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    auth.enterDemo();
  });
  tearDown(() async {
    store.dispose();
    auth.dispose();
    await db.close();
  });
  Widget harness(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: store),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider(create: (_) => ThemeController()),
    ],
    child: MaterialApp(theme: AppTheme.build(false), home: child),
  );

  for (final size in [
    const Size(1440, 1000),
    const Size(390, 844),
    const Size(320, 740),
    const Size(768, 1024),
    const Size(834, 1194),
    const Size(1024, 768),
  ]) {
    testWidgets(
      'responsive workspace ${size.width.toInt()}px has working navigation',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(harness(const AppShell()));
        await tester.pumpAndSettle();
        expect(find.text('Welcome to ${store.gymName}'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (size.width < 720) {
          await tester.tap(find.byType(NavigationDestination).at(1));
        } else {
          if (size.width < 1180) {
            await tester.tap(find.byTooltip('Members'));
          } else {
            await tester.tap(find.text('Members').first);
          }
        }
        await tester.pumpAndSettle();
        expect(find.text('Add member'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Add member'));
        await tester.pumpAndSettle();
        expect(find.byType(RecordEditor), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Save member'));
        await tester.pumpAndSettle();
        expect(find.text('Enter full name'), findsOneWidget);
      },
    );
  }
  testWidgets('member form saves to SQLite', (tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      harness(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => editRecord(context, store, entities['members']!),
              child: const Text('Open form'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'New Member');
    await tester.enterText(find.byType(TextFormField).at(1), '03001239876');
    // Native SQLite completes outside the widget test's fake clock.
    await tester.runAsync(() async {
      await tester.tap(find.text('Save member'));
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (!store.rows('members').any((m) => m['name'] == 'New Member')) {
        if (DateTime.now().isAfter(deadline)) {
          throw StateError('Member save did not finish.');
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    expect(store.rows('members').any((m) => m['name'] == 'New Member'), isTrue);
    expect(find.byType(RecordEditor), findsNothing);
  });
  for (final screen in [
    const FeesScreen(),
    const SettingsScreen(),
    const MessagesScreen(),
    const AttendanceScreen(),
    ...[
      'members',
      'payments',
      'membership_plans',
      'trainers',
      'workout_plans',
      'inventory_items',
    ].map((table) => RecordsScreen(table: table)),
  ]) {
    testWidgets('${screen.runtimeType} is usable on a 390px phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        harness(
          Scaffold(
            body: SingleChildScrollView(
              child: Padding(padding: const EdgeInsets.all(18), child: screen),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
