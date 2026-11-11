import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/injection.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/router/app_router.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  await configureDependencies();
  final firebaseReady = await FirebaseInitializer.initialize();
  if (firebaseReady) await getIt<FirebaseAuth>().signOut();
  await themeController.load();
  runApp(AutoDocApp(auth: firebaseReady ? getIt<FirebaseAuth>() : null));
}

class AutoDocApp extends StatefulWidget {
  const AutoDocApp({super.key, this.auth});

  final FirebaseAuth? auth;

  @override
  State<AutoDocApp> createState() => _AutoDocAppState();
}

class _AutoDocAppState extends State<AutoDocApp> {
  final _authRefresh = ValueNotifier<User?>(null);
  late final _router = createAppRouter(
    authAvailable: widget.auth != null,
    isSignedIn: () => widget.auth?.currentUser != null,
    authRefresh: _authRefresh,
  );
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authRefresh.value = widget.auth?.currentUser;
    _authSubscription = widget.auth?.authStateChanges().listen((user) {
      _authRefresh.value = user;
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _router.dispose();
    _authRefresh.dispose();
    super.dispose();
  }

 @override
 Widget build(BuildContext context) {
  return ValueListenableBuilder<ThemeMode>(
    valueListenable: themeController,
    builder: (context, mode, _) => MaterialApp.router(
      title: 'AutoDoc AI',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
    ),
  );
}
}
