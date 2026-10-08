import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fitguide/services/cloud_api.dart';

void main() {
  Future<void> expectMessage(CloudApi api, String text) async {
    addTearDown(api.close);
    await expectLater(
      api.call('login'),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', contains(text)),
      ),
    );
  }

  test(
    'unreachable server shows connection error instead of save error',
    () async {
      await expectMessage(
        CloudApi(
          baseUrl: 'https://gym.example.com',
          client: MockClient(
            (_) async => throw http.ClientException('Connection refused'),
          ),
        ),
        'Could not connect to FitGuide server gym.example.com',
      );
    },
  );

  test('HTTPS failure explains certificate check', () async {
    await expectMessage(
      CloudApi(
        baseUrl: 'https://gym.example.com',
        client: MockClient(
          (_) async => throw http.ClientException(
            'HandshakeException: CERTIFICATE_VERIFY_FAILED',
          ),
        ),
      ),
      'Check the server HTTPS certificate',
    );
  });

  test('timeout explains retry without changing credentials', () async {
    await expectMessage(
      CloudApi(
        baseUrl: 'https://gym.example.com',
        client: MockClient((_) async => throw TimeoutException('timeout')),
      ),
      'did not respond in time',
    );
  });

  test('non API response includes HTTP status', () async {
    await expectMessage(
      CloudApi(
        baseUrl: 'https://gym.example.com',
        client: MockClient(
          (_) async => http.Response('<html>Not Found</html>', 404),
        ),
      ),
      'HTTP 404',
    );
  });

  test('missing host fails before any request', () async {
    await expectMessage(
      CloudApi(
        baseUrl: 'https:',
        client: MockClient((_) async => throw StateError('must not request')),
      ),
      'Enter a valid FitGuide server address',
    );
  });

  test('API login rejection preserves credential error', () async {
    await expectMessage(
      CloudApi(
        baseUrl: 'https://gym.example.com',
        client: MockClient((request) async {
          expect(request.url.toString(), 'https://gym.example.com/api/gym');
          return http.Response(
            '{"error":"Invalid username or password."}',
            401,
          );
        }),
      ),
      'Invalid username or password.',
    );
  });

  test('structured server error remains a usable HTTP error', () async {
    await expectMessage(
      CloudApi(
        baseUrl: 'https://gym.example.com',
        client: MockClient(
          (_) async => http.Response('{"error":{"message":"failure"}}', 500),
        ),
      ),
      'HTTP 500',
    );
  });
}
