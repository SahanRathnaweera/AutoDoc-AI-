import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'config/injection.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseInitialized = await FirebaseInitializer.initialize(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!firebaseInitialized) {
    throw StateError(
      'Firebase initialization failed. Run `flutterfire configure` and '
      'verify the Firebase settings for this platform.',
    );
  }

  await configureDependencies();
  runApp(const AutoDocApp());
}

class AutoDocApp extends StatelessWidget {
  const AutoDocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AutoDoc AI',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xff1479e8),
        brightness: Brightness.light,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xff1479e8),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
    );
  }
}
