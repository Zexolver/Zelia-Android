import 'package:shared_preferences/shared_preferences.dart';

/// Persists the connection details for ZELIA's remote_bridge.py server
/// (see zelia repo's src/remote_bridge.py) -- a base URL (Tailscale IP or
/// hostname + port) and the bearer token it requires. Kept deliberately
/// simple (no backend "pairing"/QR flow yet): the user copies these from
/// their ZELIA machine's config.yaml once.
class SettingsService {
  static const _keyServerUrl = 'server_url';
  static const _keyToken = 'token';

  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<void> save({required String serverUrl, required String token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, serverUrl.trim());
    await prefs.setString(_keyToken, token.trim());
  }

  Future<bool> isConfigured() async {
    final url = await getServerUrl();
    return url != null && url.isNotEmpty;
  }
}
