// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autodoc_ai/main.dart';
import 'package:mocktail/mocktail.dart';

import 'package:autodoc_ai/config/injection.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/user_entity.dart';
import 'package:autodoc_ai/features/authentication/domain/repositories/auth_repository.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/login_user.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/logout_user.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockFirebaseUser extends Mock implements User {}

class _MockAuthRepository extends Mock implements AuthRepository {}

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
    const email = 'driver@example.com';
    const password = 'ExamplePassword123';
    const account = UserEntity(
      uid: 'test-user',
      email: email,
      displayName: 'Test Driver',
    );
    final auth = _MockFirebaseAuth();
    final firebaseUser = _MockFirebaseUser();
    final repository = _MockAuthRepository();
    User? currentUser;

    when(() => auth.currentUser).thenAnswer((_) => currentUser);
    when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(null));
    when(() => firebaseUser.displayName).thenReturn(account.displayName);
    when(() => firebaseUser.email).thenReturn(email);
    when(() => firebaseUser.emailVerified).thenReturn(false);
    when(
      () => repository.loginWithEmailAndPassword(
        email: email,
        password: password,
      ),
    ).thenAnswer((_) async {
      currentUser = firebaseUser;
      return const Right(account);
    });
    when(() => repository.logout()).thenAnswer((_) async {
      currentUser = null;
      return const Right(null);
    });
    getIt.registerSingleton<FirebaseAuth>(auth);
    getIt.registerSingleton<LoginUser>(LoginUser(repository));
    getIt.registerSingleton<LogoutUser>(LogoutUser(repository));
    addTearDown(() => getIt.reset());

    await tester.pumpWidget(AutoDocApp(auth: auth));
    await tester.pump(const Duration(milliseconds: 2800));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), password);
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
    expect(find.text('Test Driver'), findsOneWidget);
    expect(find.text(email), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Log out'));
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
