import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitguide/services/auth_service.dart';
import 'package:fitguide/services/cloud_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'expired API session clears persistence and returns the owner to sign-in',
    () async {
      SharedPreferences.setMockInitialValues({
        'fitguide.cloudSession': 'expired-token',
      });
      var expire = false;
      final api = CloudApi(
        baseUrl: 'http://localhost:3000',
        client: MockClient((request) async {
          if (expire)
            return http.Response(
              jsonEncode({'error': 'Your session expired.'}),
              401,
            );
          return http.Response(
            jsonEncode({
              'ownerName': 'Owner',
              'workspaces': [
                {'id': 'gym-1', 'name': 'Gym'},
              ],
            }),
            200,
          );
        }),
      );
      final auth = AuthService(cloud: api);
      while (auth.loading) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(auth.loggedIn, true);
      expire = true;
      await expectLater(api.call('records'), throwsA(isA<CloudApiException>()));
      expect(auth.loggedIn, false);
      expect(auth.workspaceId, isNull);
      expect(api.token, isNull);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'fitguide.cloudSession',
        ),
        isNull,
      );
      expect(auth.error, isNull);
      auth.dispose();
    },
  );

  test(
    'login rejection without a session does not invoke session expiry',
    () async {
      var expired = false;
      final api = CloudApi(
        baseUrl: 'http://localhost:3000',
        client: MockClient(
          (_) async => http.Response('{"error":"Invalid login"}', 401),
        ),
      );
      api.onSessionExpired = () async {
        expired = true;
      };
      addTearDown(api.close);
      await expectLater(api.call('login'), throwsA(isA<CloudApiException>()));
      expect(expired, false);
    },
  );
}
