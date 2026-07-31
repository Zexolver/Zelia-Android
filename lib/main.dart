import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'screens/chat_screen.dart';

void main() {
  runApp(const ZeliaApp());
}

class ZeliaApp extends StatelessWidget {
  const ZeliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Falls back to a fixed purple seed (matching the desktop app's
        // accent color) on devices/versions without Material You support.
        const seed = Color(0xFFCBA6F7);
        final lightScheme = lightDynamic ?? ColorScheme.fromSeed(seedColor: seed);
        final darkScheme = darkDynamic ?? ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);

        return MaterialApp(
          title: 'ZELIA',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
          darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
          themeMode: ThemeMode.system,
          home: const ChatScreen(),
        );
      },
    );
  }
}
