import 'package:shared_preferences/shared_preferences.dart';

/// Persists the connection details for ZELIA's remote_bridge.py server
/// (see zelia repo's src/remote_bridge.py) -- a base URL (Tailscale IP or
/// hostname + port) and the bearer token it requires. Kept deliberately
/// simple (no backend "pairing"/QR flow yet): the user copies these from
/// their ZELIA machine's config.yaml once.
class SettingsService {
  static const _keyServerUrl = 'server_url';
  static const _keyToken = 'token';

  /// Tailscale MagicDNS name for the one ZELIA machine this app currently
  /// talks to (see `tailscale status --json`'s Self.DNSName) -- stable
  /// regardless of the machine's actual Tailscale IP, so this is what
  /// auto-detection tries first instead of asking the user to type an IP.
  /// Not a secret (just a hostname; reaching it still requires being on
  /// the same tailnet), unlike the token below which must never be baked
  /// into a public repo's source.
  static const defaultServerUrl = 'http://zexolver-gaming-manjaro.tailc35f4b.ts.net:8899';

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
