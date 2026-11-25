import 'package:flutter/material.dart';
import '../lib/features/inspection/presentation/pages/engine_sound_recording_page.dart';

void main() {
  runApp(const EngineTestApp());
}

class EngineTestApp extends StatelessWidget {
  const EngineTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Engine Sound Test',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const EngineSoundRecordingPage(),
    );
  }
}