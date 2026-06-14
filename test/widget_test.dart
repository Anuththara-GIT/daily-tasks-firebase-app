import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_tasks_app/screens/firebase_setup_screen.dart';

void main() {
  testWidgets('shows Firebase setup guidance', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FirebaseSetupScreen(
          errorMessage: 'Missing google-services.json',
        ),
      ),
    );

    expect(find.text('Connect Firebase to continue'), findsOneWidget);
    expect(find.textContaining('google-services.json'), findsWidgets);
  });
}
