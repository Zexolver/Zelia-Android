import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zelia/main.dart';

void main() {
  testWidgets('App launches to the chat screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ZeliaApp());
    await tester.pump();

    expect(find.text('ZELIA'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
