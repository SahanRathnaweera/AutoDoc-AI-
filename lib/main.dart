import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

import 'config/injection.dart';
import 'core/firebase/firebase_initializer.dart';
import 'firebase_options.dart';

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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '360 Panorama & AutoDoc AI',

  
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

      home: const PanoramaScreen(),
    );
  }
}

class PanoramaScreen extends StatefulWidget {
  const PanoramaScreen({super.key});

  @override
  State<PanoramaScreen> createState() => _PanoramaScreenState();
}

class _PanoramaScreenState extends State<PanoramaScreen> {
  int resetKey = 0;

  void resetView() {
    setState(() {
      resetKey++;
    });
  }

  void openFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FullscreenPanorama(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('360° Panorama'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: resetView,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset view',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PanoramaViewer(
              key: ValueKey(resetKey),
              child: Image.asset('assets/panorama360.jpg'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.threesixty,
                  size: 35,
                  color: Colors.teal,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explore the world in 360°',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Drag the image to look around.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: openFullscreen,
                    icon: const Icon(Icons.fullscreen),
                    label: const Text('Open Fullscreen'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FullscreenPanorama extends StatelessWidget {
  const FullscreenPanorama({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('360° View'),
      ),
      body: SizedBox.expand(
        child: PanoramaViewer(
          child: Image.asset('assets/panorama360.jpg'),
        ),
      ),
    );
  }
}