import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../services/zelia_api.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  late final ZeliaApi _api;
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();

  bool _loading = true;
  bool _testing = false;
  bool _autoDetecting = false;
  bool _speakReplies = true;
  String? _testResult;
  String? _autoDetectResult;

  @override
  void initState() {
    super.initState();
    _api = ZeliaApi(_settings);
    _load();
    _settings.getSpeakReplies().then((value) {
      if (mounted) setState(() => _speakReplies = value);
    });
  }

  Future<void> _load() async {
    final url = await _settings.getServerUrl();
    final token = await _settings.getToken();
    // Falls back to the bundled token (see settings_service.dart) rather
    // than an empty field -- if this screen is showing at all, the chat
    // screen's own auto-configure attempt already failed (couldn't reach
    // the default address), but the token itself is still known.
    _tokenController.text = token ?? SettingsService.bundledToken;

    if (url != null && url.isNotEmpty) {
      _urlController.text = url;
      setState(() => _loading = false);
      return;
    }

    // Nothing saved yet -- try to find ZELIA automatically before falling
    // back to asking the user to type an address. Tailscale doesn't
    // support broadcast-style LAN discovery (it's point-to-point tunnels,
    // not a real shared network segment), but MagicDNS gives every device
    // a stable hostname, so probing that known address is the actual
    // "auto-detect" available here -- not a generic network scan.
    setState(() => _autoDetecting = true);
    final found = await _api.checkHealth(SettingsService.defaultServerUrl);
    setState(() {
      _autoDetecting = false;
      _loading = false;
      if (found) {
        _urlController.text = SettingsService.defaultServerUrl;
        _autoDetectResult = 'Found ZELIA automatically -- just add the token below.';
      } else {
        _urlController.text = 'http://100.';
        _autoDetectResult = "Couldn't auto-detect ZELIA -- enter the address manually "
            "(check Tailscale is connected on both devices).";
      }
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final url = _urlController.text.trim();
    final ok = await _api.checkHealth(url);
    setState(() {
      _testing = false;
      _testResult = ok ? 'Reached ZELIA successfully.' : "Couldn't reach that address.";
    });
  }

  Future<void> _save() async {
    await _settings.save(serverUrl: _urlController.text.trim(), token: _tokenController.text.trim());
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (_autoDetecting) ...[
                const SizedBox(height: 16),
                const Text('Looking for ZELIA...'),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Connect to ZELIA',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              "Address and token are both filled in automatically when "
              "possible -- just confirm Tailscale is connected on both "
              "devices and hit Save.",
            ),
            if (_autoDetectResult != null) ...[
              const SizedBox(height: 12),
              Text(_autoDetectResult!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Server address',
                hintText: 'http://100.x.y.z:8899',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Token',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _testing ? null : _testConnection,
                    child: _testing
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Test connection'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 12),
              Text(_testResult!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 24),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Speak replies aloud'),
              subtitle: const Text('Uses this phone\'s text-to-speech voice, not ZELIA\'s desktop voice.'),
              value: _speakReplies,
              onChanged: (value) {
                setState(() => _speakReplies = value);
                _settings.setSpeakReplies(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
