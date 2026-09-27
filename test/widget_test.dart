// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autodoc_ai/main.dart';
import 'package:autodoc_ai/features/auth/domain/entities/demo_credentials.dart';

void main() {
  testWidgets('splash opens the login screen', (tester) async {
    await tester.pumpWidget(const AutoDocApp());

    expect(find.text('Guided. Diagnostic. Trusted.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2800));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
  });

  testWidgets('user can switch to registration', (tester) async {
    await tester.pumpWidget(const AutoDocApp());
    await tester.pump(const Duration(milliseconds: 2800));

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('login opens dashboard and marketplace tabs', (tester) async {
    await tester.pumpWidget(const AutoDocApp());
    await tester.pump(const Duration(milliseconds: 2800));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), DemoCredentials.email);
    await tester.enterText(fields.at(1), DemoCredentials.password);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Log in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('AutoDoc AI'), findsOneWidget);
    expect(find.text('Vehicle health score'), findsOneWidget);

    await tester.tap(find.text('Market'));
    await tester.pumpAndSettle();
    expect(find.text('Verified vehicles'), findsOneWidget);

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Saved vehicles'), findsWidgets);
    expect(find.text('2019 Tesla Model 3'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Demo User'), findsOneWidget);
    expect(find.text('test@autodoc.ai'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Log out'));
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
