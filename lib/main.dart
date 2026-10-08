import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/injection.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  await configureDependencies();
  await FirebaseInitializer.initialize();
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