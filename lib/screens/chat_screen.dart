import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/zelia_api.dart';
import 'memories_screen.dart';
import 'settings_screen.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  _ChatMessage({required this.text, required this.isUser, this.isError = false});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _settings = SettingsService();
  late final ZeliaApi _api;
  final _notifications = NotificationService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _api = ZeliaApi(_settings);
    _notifications.init();
    _checkSetup();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
  }

  Future<void> _checkSetup() async {
    // Try fully hands-off setup first (default address reachable -> save
    // it plus the bundled token, no user interaction needed at all).
    // Only fall back to Settings if that doesn't work out.
    final autoConfigured = await _settings.tryAutoConfigure(_api.checkHealth);
    if (autoConfigured) return;

    final configured = await _settings.isConfigured();
    if (!configured && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openSettings());
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _sending = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final reply = await _api.sendMessage(text);
      final replyText = reply.isEmpty ? '(no reply)' : reply;
      setState(() {
        _messages.add(_ChatMessage(text: replyText, isUser: false));
      });
      // Only notify if the app isn't actually in front of the user right
      // now -- they're already looking at the reply in that case, a
      // notification would just be redundant noise. This is specifically
      // for the "replied while I was multitasking on my phone" case.
      if (_lifecycleState != AppLifecycleState.resumed) {
        _notifications.showReply(replyText);
      }
    } on ZeliaApiException catch (e) {
      setState(() {
        _messages.add(_ChatMessage(text: e.message, isUser: false, isError: true));
      });
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZELIA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MemoriesScreen()),
            ),
            tooltip: 'Second Brain',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Say something to ZELIA',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
                  ),
          ),
          if (_sending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(height: 2, child: LinearProgressIndicator()),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: 'Message ZELIA',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    final Color bg;
    final Color fg;
    if (message.isError) {
      bg = colors.errorContainer;
      fg = colors.onErrorContainer;
    } else if (isUser) {
      bg = colors.primaryContainer;
      fg = colors.onPrimaryContainer;
    } else {
      bg = colors.secondaryContainer;
      fg = colors.onSecondaryContainer;
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(message.text, style: TextStyle(color: fg)),
      ),
    );
  }
}
