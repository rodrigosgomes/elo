// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:elo/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(const {});
    await Supabase.initialize(
      url: 'https://hqitwoutbiasulgaxpoa.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhxaXR3b3V0Ymlhc3VsZ2F4cG9hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ1NTI4MTIsImV4cCI6MjA4MDEyODgxMn0.pWVKcGK1v_ZPOOdK2YFN42AFCf-RpLZ-fxPOaNjgvXY',
    );
  });

  testWidgets('shows login screen when no session is available',
      (WidgetTester tester) async {
    await tester.pumpWidget(const EloApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Elo'), findsWidgets);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
