import 'dart:convert';
import 'package:http/http.dart' as http;

import 'settings_service.dart';

class ZeliaApiException implements Exception {
  final String message;
  ZeliaApiException(this.message);

  @override
  String toString() => message;
}

/// Talks to ZELIA's remote_bridge.py HTTP server (POST /chat, GET /health).
/// Deliberately thin -- one request in, one reply out, matching the same
/// zelia.sock protocol every other ZELIA text client already uses.
class ZeliaApi {
  final SettingsService _settings;
  ZeliaApi(this._settings);

  Future<String> sendMessage(String message) async {
    final serverUrl = await _settings.getServerUrl();
    final token = await _settings.getToken() ?? '';

    if (serverUrl == null || serverUrl.isEmpty) {
      throw ZeliaApiException('Not set up yet -- open Settings and enter your ZELIA server address.');
    }

    final uri = Uri.parse('$serverUrl/chat');
    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 300));
    } catch (e) {
      throw ZeliaApiException("Couldn't reach ZELIA -- check that she's running and Tailscale is connected. ($e)");
    }

    if (response.statusCode == 401) {
      throw ZeliaApiException('Rejected -- check the token in Settings matches config.yaml.');
    }
    if (response.statusCode != 200) {
      throw ZeliaApiException('ZELIA returned an error (HTTP ${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['reply'] as String?) ?? '';
  }

  /// Quick reachability check for the Settings screen -- doesn't need the
  /// token (health is unauthenticated), just confirms the server answers.
  Future<bool> checkHealth(String serverUrl) async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/health')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
