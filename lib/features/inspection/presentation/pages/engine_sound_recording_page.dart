import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class EngineSoundRecordingPage extends StatefulWidget {
  const EngineSoundRecordingPage({super.key});

  @override
  State<EngineSoundRecordingPage> createState() =>
      _EngineSoundRecordingPageState();
}

class _EngineSoundRecordingPageState extends State<EngineSoundRecordingPage> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _timer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;

  bool _isRecording = false;
  bool _isPlaying = false;
  int _remainingSeconds = 15;

  String? _savedAudioPath;

  final List<double> _waveformBars = List.filled(35, 0.08);

  @override
  void initState() {
    super.initState();

    // Reset Play button when audio finishes.
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;

      setState(() {
        _isPlaying = false;
      });
    });
  }

  Future<void> _startRecording() async {
    try {
      await _audioPlayer.stop();

      final hasPermission = await _recorder.hasPermission();

      if (!hasPermission) {
        _showMessage('Microphone permission was denied.');
        return;
      }

      final directory = await getApplicationDocumentsDirectory();

      final fileName =
          'engine_sound_${DateTime.now().millisecondsSinceEpoch}.wav';

      final filePath = '${directory.path}/$fileName';

      await _amplitudeSubscription?.cancel();

      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amplitude) {
            final level = ((amplitude.current + 60) / 60)
                .clamp(0.08, 1.0)
                .toDouble();

            if (!mounted) return;

            setState(() {
              _waveformBars.removeAt(0);
              _waveformBars.add(level);
            });
          });

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        ),
        path: filePath,
      );

      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _isPlaying = false;
        _remainingSeconds = 15;
        _savedAudioPath = null;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_remainingSeconds <= 1) {
          timer.cancel();
          _stopRecording();
        } else {
          setState(() {
            _remainingSeconds--;
          });
        }
      });
    } catch (e) {
      _showMessage('Recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();

    try {
      final path = await _recorder.stop();

      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;

      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _remainingSeconds = 15;
        _savedAudioPath = path;
      });

      if (path != null) {
        _showMessage('Audio saved successfully!');
      } else {
        _showMessage('No audio file was created.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      _showMessage('Could not stop recording: $e');
    }
  }

  // Play saved audio.
  Future<void> _playAudio() async {
    if (_savedAudioPath == null) return;

    try {
      await _audioPlayer.play(DeviceFileSource(_savedAudioPath!));

      if (!mounted) return;

      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      _showMessage('Could not play audio: $e');
    }
  }

  // Pause audio.
  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();

      if (!mounted) return;

      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      _showMessage('Could not pause audio: $e');
    }
  }

  // Delete saved recording.
  Future<void> _deleteRecording() async {
    if (_savedAudioPath == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recording?'),
        content: const Text('Are you sure you want to delete this audio file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _audioPlayer.stop();

      final file = File(_savedAudioPath!);

      if (await file.exists()) {
        await file.delete();
      }

      if (!mounted) return;

      setState(() {
        _savedAudioPath = null;
        _isPlaying = false;
      });

      _showMessage('Recording deleted successfully!');
    } catch (e) {
      _showMessage('Could not delete recording: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    _playerCompleteSubscription?.cancel();

    unawaited(_recorder.dispose());
    unawaited(_audioPlayer.dispose());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Engine Sound Test')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            const Icon(Icons.graphic_eq, size: 65, color: Colors.blue),

            const SizedBox(height: 16),

            const Text(
              'Acoustic Engine Diagnostics',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            const Text(
              'Record engine sound for 15 seconds. '
              'Keep the environment as quiet as possible.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            Text(
              _isRecording
                  ? '00:${_remainingSeconds.toString().padLeft(2, '0')}'
                  : '00:15',
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            // Live waveform visualizer.
            Container(
              height: 130,
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _waveformBars.map((level) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 4,
                    height: 12 + (level * 85),
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 30),

            // Start and stop recording.
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton.icon(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(
                  _isRecording ? 'Stop Recording' : 'Start Recording',
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Saved audio controls.
            if (_savedAudioPath != null) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 30),

              const Text(
                'Recording saved locally!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _isPlaying ? _pauseAudio : _playAudio,
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Pause' : 'Play Audio'),
                  ),

                  const SizedBox(width: 12),

                  OutlinedButton.icon(
                    onPressed: _deleteRecording,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                _savedAudioPath!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
