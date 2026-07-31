import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Posts a local notification when ZELIA replies, so it's noticeable
/// while multitasking on the phone (the whole reason the user asked for
/// this) instead of only visible by having the chat screen open.
class NotificationService {
  static const _channelId = 'zelia_replies';
  static const _channelName = 'ZELIA replies';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _nextId = 0;

  Future<void> init() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidSettings));

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: "Notifies you when ZELIA replies to a message you sent",
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await Permission.notification.request();
    _initialized = true;
  }

  Future<void> showReply(String text) async {
    if (!_initialized) await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(''),
      ),
    );
    await _plugin.show(
      _nextId++,
      'ZELIA',
      text,
      details,
    );
  }
}
