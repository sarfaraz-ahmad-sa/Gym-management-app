import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudApiException extends StateError {
  CloudApiException(this.statusCode, String message) : super(message);
  final int statusCode;
}

class CloudApi {
  CloudApi({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL'),
      _client = client ?? http.Client();
  final http.Client _client;
  void close() => _client.close();
  Future<void> Function()? onSessionExpired;
  String baseUrl;
  String? token;
  bool get enabled => kIsWeb || baseUrl.isNotEmpty;
  Uri get endpoint {
    if (baseUrl.isEmpty && kIsWeb) return Uri.base.resolve('/api/gym');
    final url = Uri.tryParse(baseUrl.trim());
    if (url == null || url.host.isEmpty || url.userInfo.isNotEmpty) {
      throw StateError(
        'Enter a valid FitGuide server address, such as https://your-fitguide.vercel.app.',
      );
    }
    if (url.scheme != 'https' &&
        !(url.scheme == 'http' &&
            (url.host == 'localhost' ||
                url.host == '127.0.0.1' ||
                url.host == '10.0.2.2'))) {
      throw StateError('Use an HTTPS server address.');
    }
    return url.resolve('/api/gym');
  }

  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) async {
    if (!enabled) {
      throw StateError(
        'Enter your published FitGuide server address to connect mobile.',
      );
    }
    final requestToken = token;
    final server = endpoint;
    final body = jsonEncode({'action': action, ...values});
    final http.Response response;
    try {
      response = await _client
          .post(
            server,
            headers: {
              'Content-Type': 'application/json',
              if (requestToken != null) 'Authorization': 'Bearer $requestToken',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw StateError(
        'FitGuide server ${server.host} did not respond in time. Please retry.',
      );
    } catch (e) {
      final detail = e.toString().toLowerCase();
      if (detail.contains('handshake') ||
          detail.contains('certificate') ||
          detail.contains('ssl') ||
          detail.contains('tls')) {
        throw StateError(
          'Could not establish a secure connection to ${server.host}. Check the server HTTPS certificate and the device date/time.',
        );
      }
      throw StateError(
        'Could not connect to FitGuide server ${server.host}. Check your Internet connection and server availability.',
      );
    }
    if (response.statusCode == 401 &&
        requestToken != null &&
        token == requestToken) {
      token = null;
      await onSessionExpired?.call();
    }
    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw StateError(
        'FitGuide server ${server.host} returned an invalid response (HTTP ${response.statusCode}). Check that /api/gym is deployed and accessible.',
      );
    }
    if (response.statusCode >= 400) {
      throw CloudApiException(
        response.statusCode,
        data['error'] is String
            ? data['error'] as String
            : 'Cloud request failed (HTTP ${response.statusCode}).',
      );
    }
    return data;
  }
}
