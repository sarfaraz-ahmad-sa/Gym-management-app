import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudApi {
  CloudApi({String? baseUrl})
    : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL');
  String baseUrl;
  String? token;
  bool get enabled => kIsWeb || baseUrl.isNotEmpty;
  Uri get endpoint {
    if (baseUrl.isEmpty && kIsWeb) return Uri.base.resolve('/api/gym');
    final url = Uri.parse(baseUrl);
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
    final response = await http
        .post(
          endpoint,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'action': action, ...values}),
        )
        .timeout(const Duration(seconds: 60));
    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw StateError(
        'The server returned an invalid response. Check your FitGuide deployment address.',
      );
    }
    if (response.statusCode >= 400) {
      throw StateError(data['error'] as String? ?? 'Cloud request failed.');
    }
    return data;
  }
}
