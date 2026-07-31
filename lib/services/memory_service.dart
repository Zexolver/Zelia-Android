import 'dart:convert';
import 'package:http/http.dart' as http;

import 'settings_service.dart';
import 'zelia_api.dart';

class Memory {
  final String id;
  final String text;
  final String role;
  final double timestamp;
  Memory({required this.id, required this.text, required this.role, required this.timestamp});

  factory Memory.fromJson(Map<String, dynamic> json) => Memory(
        id: json['id'] as String,
        text: json['text'] as String,
        role: json['role'] as String,
        timestamp: (json['timestamp'] as num).toDouble(),
      );

  DateTime get time => DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).round());
}

/// Talks to ZELIA's remote_bridge.py GET /memories -- browsing ZELIA's
/// second brain, not searching/recalling it (that's an internal-only
/// operation the agent does for itself).
class MemoryService {
  final SettingsService _settings;
  MemoryService(this._settings);

  Future<List<Memory>> fetchRecent() async {
    final serverUrl = await _settings.getServerUrl();
    final token = await _settings.getToken() ?? '';
    if (serverUrl == null || serverUrl.isEmpty) {
      throw ZeliaApiException('Not set up yet -- open Settings first.');
    }

    final http.Response response;
    try {
      response = await http.get(
        Uri.parse('$serverUrl/memories'),
        headers: {if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw ZeliaApiException("Couldn't reach ZELIA. ($e)");
    }

    if (response.statusCode == 401) {
      throw ZeliaApiException('Rejected -- check the token in Settings.');
    }
    if (response.statusCode != 200) {
      throw ZeliaApiException('ZELIA returned an error (HTTP ${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (body['memories'] as List).cast<Map<String, dynamic>>();
    return list.map(Memory.fromJson).toList();
  }
}
