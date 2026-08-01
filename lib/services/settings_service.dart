import 'package:shared_preferences/shared_preferences.dart';

/// Persists the connection details for ZELIA's remote_bridge.py server
/// (see zelia repo's src/remote_bridge.py) -- a base URL (Tailscale IP or
/// hostname + port) and the bearer token it requires.
class SettingsService {
  static const _keyServerUrl = 'server_url';
  static const _keyToken = 'token';
  static const _keySpeakReplies = 'speak_replies';
  static const _keyAlwaysListen = 'always_listen_wake_word';

  /// Tailscale MagicDNS name for the one ZELIA machine this app currently
  /// talks to (see `tailscale status --json`'s Self.DNSName) -- stable
  /// regardless of the machine's actual Tailscale IP, so this is what
  /// auto-detection tries first instead of asking the user to type an IP.
  /// Just a hostname, not a secret -- reaching it still requires being on
  /// the same tailnet.
  static const defaultServerUrl = 'http://zexolver-gaming-manjaro.tailc35f4b.ts.net:8899';

  /// TEMPORARY, explicitly user-authorized exception: the real
  /// remote_bridge auth token, baked into this public repo's source so
  /// the app can auto-fill it instead of the user copying it from
  /// config.yaml by hand. Normally a hardcoded secret in public source
  /// would be a real problem (anyone can read it from the repo/its
  /// history, forever, even if this line is later reverted) -- accepted
  /// here on purpose, for convenience while the user is away from the
  /// computer for the weekend and can't do a proper one-time pairing
  /// flow (not built yet). Reaching the bridge at all still requires
  /// being on the same Tailscale tailnet, which bounds the exposure
  /// somewhat, but this should be rotated (generate a new token, update
  /// it in config.yaml, remove this constant or replace with a real
  /// pairing mechanism) once that's no longer the constraint.
  static const bundledToken = 'w5Lqy_R3tI9YtqJ7zU0LUa6uRP5ERfwrhHaJILW_Th0';

  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Attempts fully hands-off setup: if nothing is saved yet and the
  /// default (MagicDNS) address is actually reachable, saves that address
  /// plus the bundled token and returns true -- the chat screen can then
  /// skip Settings entirely. Returns false if already configured or the
  /// default address isn't reachable (different network, tailnet not
  /// connected, etc), leaving the caller to fall back to manual entry.
  Future<bool> tryAutoConfigure(Future<bool> Function(String url) checkHealth) async {
    if (await isConfigured()) return false;
    if (!await checkHealth(defaultServerUrl)) return false;
    await save(serverUrl: defaultServerUrl, token: bundledToken);
    return true;
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

  /// Whether ZELIA's replies should be spoken aloud (flutter_tts) as well
  /// as shown as text -- on by default, matching how a voice assistant is
  /// expected to behave, especially when launched via the assist gesture.
  Future<bool> getSpeakReplies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySpeakReplies) ?? true;
  }

  Future<void> setSpeakReplies(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySpeakReplies, value);
  }

  /// Whether the phone should always listen in the background for "hey
  /// jarvis" (WakeWordService.kt). Off by default -- explicitly opt-in,
  /// since it means a persistent foreground notification and continuous
  /// microphone use. "hey jarvis" is a stopgap until a custom "hey
  /// Zelia" wake word is trained; see CLAUDE.md's wake word plan.
  Future<bool> getAlwaysListen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAlwaysListen) ?? false;
  }

  Future<void> setAlwaysListen(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAlwaysListen, value);
  }
}
