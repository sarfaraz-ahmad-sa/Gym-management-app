import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db_service.dart';
import 'cloud_api.dart';

import 'package:sqflite/sqflite.dart';

class AuthService extends ChangeNotifier {
  AuthService({DatabaseService? database, CloudApi? cloud})
    : api = cloud ?? CloudApi(),
      _localDb = database ?? DatabaseService.instance,
      cloudMode = database == null {
    api.onSessionExpired = _expireCloudSession;
    initialize();
  }
  final DatabaseService _localDb;
  final bool cloudMode;
  final CloudApi api;
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    api.onSessionExpired = null;
    api.close();
    super.dispose();
  }

  Future<void> _expireCloudSession() async {
    loggedIn = false;
    demo = false;
    needsSetup = false;
    error = null;
    workspaces = [];
    workspaceId = null;
    notifyListeners();
    await (await SharedPreferences.getInstance()).remove(
      'fitguide.cloudSession',
    );
  }

  List<Map<String, dynamic>> workspaces = [];
  String? workspaceId;
  DatabaseService get db => cloudMode && workspaceId != null
      ? DatabaseService(cloud: api, workspaceId: workspaceId)
      : _localDb;
  bool get needsServerAddress => cloudMode && !kIsWeb;
  void showSetup(bool value) {
    needsSetup = value;
    notifyListeners();
  }

  Future<void> setServerAddress(String value) async {
    final next = value.trim().replaceAll(RegExp(r'/+$'), '');
    if (next == api.baseUrl) return;
    api.baseUrl = next;
    api.endpoint; // Validate HTTPS before saving.
    api.token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fitguide.apiUrl', next);
    await prefs.remove('fitguide.cloudSession');
  }

  Future<void> _acceptCloudSession(Map<String, dynamic> result) async {
    if (result['token'] != null) {
      api.token = result['token'] as String;
      await (await SharedPreferences.getInstance()).setString(
        'fitguide.cloudSession',
        api.token!,
      );
    }
    ownerName = result['ownerName'] as String;
    workspaces = (result['workspaces'] as List)
        .map((w) => Map<String, dynamic>.from(w as Map))
        .toList();
    if (workspaces.isEmpty) {
      throw StateError('No workspace is available for this owner.');
    }
    if (!workspaces.any((w) => w['id'] == workspaceId)) {
      workspaceId = workspaces.first['id'] as String;
    }
    await (await SharedPreferences.getInstance()).setString(
      'fitguide.workspaceId',
      workspaceId!,
    );
    demo = false;
    loggedIn = true;
    needsSetup = false;
    notifyListeners();
  }

  Future<void> selectWorkspace(String id) async {
    if (!workspaces.any((w) => w['id'] == id)) {
      throw StateError('Workspace access denied.');
    }
    workspaceId = id;
    await (await SharedPreferences.getInstance()).setString(
      'fitguide.workspaceId',
      id,
    );
    notifyListeners();
  }

  Future<void> createWorkspace(String name) async {
    final result = await api.call('createWorkspace', {'name': name});
    workspaces.add(result);
    await selectWorkspace(result['id'] as String);
  }

  bool loading = true, loggedIn = false, demo = false, needsSetup = false;
  String? error;
  String ownerName = 'Owner';
  final _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  Future<String> _hash(String password, List<int> salt) async {
    final key = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return base64Encode(await key.extractBytes());
  }

  List<int> _random() => List.generate(32, (_) => Random.secure().nextInt(256));
  Future<String> _tokenHash(String token) async =>
      base64Encode((await Sha256().hash(utf8.encode(token))).bytes);

  Future<void> initialize() async {
    loading = true;
    error = null;
    notifyListeners();
    if (cloudMode) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (api.baseUrl.isEmpty && !kIsWeb) {
          api.baseUrl = prefs.getString('fitguide.apiUrl') ?? '';
        }
        workspaceId = prefs.getString('fitguide.workspaceId');
        api.token = prefs.getString('fitguide.cloudSession');
        if (api.token != null && api.enabled) {
          try {
            await _acceptCloudSession(await api.call('session'));
          } catch (_) {
            loggedIn = false;
          }
        }
      } catch (_) {
        error = 'Sign-in settings could not load. Please retry.';
      }
      loading = false;
      notifyListeners();
      return;
    }
    try {
      final database = await db.database;
      final accounts = await database.query('owner_account');
      needsSetup = accounts.isEmpty;
      if (!needsSetup) {
        ownerName = accounts.first['name'] as String;
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('fitguide.session');
        if (token != null) {
          final sessions = await database.query(
            'sessions',
            where: 'token_hash = ? AND expires_at > ?',
            whereArgs: [
              await _tokenHash(token),
              DateTime.now().millisecondsSinceEpoch,
            ],
          );
          loggedIn = sessions.isNotEmpty;
        }
      }
    } catch (_) {
      error = 'The workspace could not open. Please retry.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> setup({
    required String name,
    required String gymName,
    required String username,
    required String password,
    String setupCode = '',
  }) async {
    if (cloudMode) {
      await _acceptCloudSession(
        await api.call('signup', {
          'name': name,
          'gymName': gymName,
          'username': username,
          'password': password,
          'setupCode': setupCode,
        }),
      );
      return;
    }
    final database = await db.database;
    if ((await database.query('owner_account')).isNotEmpty) {
      throw StateError('This workspace already has an owner. Please sign in.');
    }
    final salt = _random();
    final hash = await _hash(password, salt);
    await database.transaction((tx) async {
      await tx.insert('owner_account', {
        'id': 1,
        'name': name,
        'username': username.toLowerCase(),
        'password_hash': hash,
        'salt': base64Encode(salt),
      });
      await tx.insert('settings', {
        'key': 'gym_name',
        'value': gymName,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
    ownerName = name;
    needsSetup = false;
    await _startSession();
  }

  Future<bool> login(String username, String password) async {
    if (cloudMode) {
      await _acceptCloudSession(
        await api.call('login', {
          'username': username.trim(),
          'password': password,
        }),
      );
      return true;
    }
    final database = await db.database;
    final rows = await database.query(
      'owner_account',
      where: 'username = ?',
      whereArgs: [username.trim().toLowerCase()],
    );
    if (rows.isEmpty) return false;
    final row = rows.first;
    final expected = row['password_hash'] as String;
    final actual = await _hash(password, base64Decode(row['salt'] as String));
    var difference = actual.length ^ expected.length;
    for (var i = 0; i < actual.length && i < expected.length; i++) {
      difference |= actual.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    if (difference != 0) return false;
    ownerName = row['name'] as String;
    await _startSession();
    return true;
  }

  Future<void> _startSession() async {
    final token = base64UrlEncode(_random());
    final database = await db.database;
    await database.delete('sessions');
    await database.insert('sessions', {
      'token_hash': await _tokenHash(token),
      'expires_at': DateTime.now()
          .add(const Duration(days: 7))
          .millisecondsSinceEpoch,
    });
    await (await SharedPreferences.getInstance()).setString(
      'fitguide.session',
      token,
    );
    demo = false;
    loggedIn = true;
    notifyListeners();
  }

  void enterDemo() {
    demo = true;
    loggedIn = true;
    ownerName = 'Alex';
    notifyListeners();
  }

  Future<void> changePassword(String current, String next) async {
    if (cloudMode && !demo) {
      await _acceptCloudSession(
        await api.call('password', {'current': current, 'next': next}),
      );
      return;
    }
    final database = await db.database;
    final account = (await database.query('owner_account')).first;
    if (await _hash(current, base64Decode(account['salt'] as String)) !=
        account['password_hash']) {
      throw StateError('Current password is incorrect.');
    }
    final salt = _random();
    await database.update('owner_account', {
      'salt': base64Encode(salt),
      'password_hash': await _hash(next, salt),
    }, where: 'id = 1');
    await _startSession();
  }

  Future<void> logout() async {
    if (cloudMode) {
      if (!demo && api.token != null) {
        try {
          await api.call('logout');
        } catch (_) {
          /* Local token is removed even when the network is down. */
        }
      }
      if (!demo) {
        api.token = null;
        await (await SharedPreferences.getInstance()).remove(
          'fitguide.cloudSession',
        );
      }
      loggedIn = false;
      demo = false;
      notifyListeners();
      return;
    }
    if (!demo) {
      await (await db.database).delete('sessions');
      await (await SharedPreferences.getInstance()).remove('fitguide.session');
    }
    loggedIn = false;
    demo = false;
    notifyListeners();
  }
}
