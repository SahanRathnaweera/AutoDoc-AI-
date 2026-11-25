import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:record/record.dart';

class EngineSoundRecordingPage extends StatefulWidget {
  const EngineSoundRecordingPage({
    super.key,
    this.baseUrl = 'http://10.0.2.2:8000',
  });

  final String baseUrl;

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

  bool _isAnalyzing = false;
  bool _isExportingPdf = false;

  String _vehicleType = 'car';
  String? _prediction;
  String? _analysisError;
  String? _savedAudioPath;
  String? _lastSavedPdfPath;

  final List<double> _waveformBars = List.filled(35, 0.08);

  @override
  void initState() {
    super.initState();

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
      });
    });
  }

  Uri _audioEndpointUri() {
    final normalizedBase = widget.baseUrl.endsWith('/')
        ? widget.baseUrl.substring(0, widget.baseUrl.length - 1)
        : widget.baseUrl;
    return Uri.parse('$normalizedBase/api/v1/audio');
  }

  Future<void> _analyzeEngineSound() async {
    if (_savedAudioPath == null) {
      _showMessage('Please record engine sound first.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _prediction = null;
      _analysisError = null;
      _lastSavedPdfPath = null;
    });

    try {
      final request = http.MultipartRequest('POST', _audioEndpointUri());
      request.fields['vehicle_type'] = _vehicleType;
      request.files.add(
        await http.MultipartFile.fromPath('audio', _savedAudioPath!),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final label = data is Map<String, dynamic>
            ? data['predicted_label']?.toString()
            : null;
        if (label == null || label.trim().isEmpty) {
          throw Exception('Missing predicted_label in server response.');
        }
        if (!mounted) return;
        setState(() {
          _prediction = label.trim();
        });
      } else {
        final detail = data is Map<String, dynamic>
            ? data['detail']?.toString()
            : null;
        throw Exception(detail ?? 'Audio analysis failed.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _analysisError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<Uint8List> _buildReportPdfBytes(String predictionLabel) async {
    final doc = pw.Document();
    final generatedAt = DateTime.now().toLocal().toString();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'AutoDoc AI - Engine Sound Report',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated on: $generatedAt',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Divider(height: 20),
            pw.Text('Vehicle Type: ${_vehicleType.toUpperCase()}'),
            pw.SizedBox(height: 6),
            pw.Text(
              'Predicted Result: $predictionLabel',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (_savedAudioPath != null) ...[
              pw.SizedBox(height: 12),
              pw.Text(
                'Audio File: $_savedAudioPath',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ],
        ),
      ),
    );

    return doc.save();
  }

  Future<String> _savePdfFile(Uint8List bytes, String fileName) async {
    Directory? dir;
    if (Platform.isAndroid) {
      final externalDirs = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      if (externalDirs != null && externalDirs.isNotEmpty) {
        dir = externalDirs.first;
      }
    }
    dir ??= await getApplicationDocumentsDirectory();

    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _downloadReportPdf() async {
    final label = _prediction;
    if (label == null || _isExportingPdf) return;

    setState(() => _isExportingPdf = true);
    try {
      final bytes = await _buildReportPdfBytes(label);
      final fileName =
          'engine_sound_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedPath = await _savePdfFile(bytes, fileName);

      if (!mounted) return;
      setState(() {
        _lastSavedPdfPath = savedPath;
        _isExportingPdf = false;
      });

      _showMessage('PDF saved: $savedPath');
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExportingPdf = false);
      _showMessage('Could not export PDF: $e');
    }
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
        _prediction = null;
        _analysisError = null;
        _lastSavedPdfPath = null;
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

      if (path == null) {
        setState(() {
          _isRecording = false;
          _remainingSeconds = 15;
        });
        _showMessage('Recording failed: no audio file created.');
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        setState(() {
          _isRecording = false;
          _remainingSeconds = 15;
        });
        _showMessage('Recording file does not exist.');
        return;
      }

      final fileSize = await file.length();
      if (fileSize <= 44) {
        setState(() {
          _isRecording = false;
          _remainingSeconds = 15;
        });
        _showMessage('Recording is empty or contains no audio data.');
        return;
      }

      setState(() {
        _isRecording = false;
        _remainingSeconds = 15;
        _savedAudioPath = path;
      });

      _showMessage('Recording saved! File size: $fileSize bytes');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _remainingSeconds = 15;
      });
      _showMessage('Could not stop recording: $e');
    }
  }

  Future<void> _playAudio() async {
    if (_savedAudioPath == null) {
      _showMessage('No recording available.');
      return;
    }

    try {
      final file = File(_savedAudioPath!);
      if (!await file.exists()) {
        _showMessage('Audio file not found.');
        return;
      }

      final fileSize = await file.length();
      if (fileSize <= 44) {
        _showMessage('Audio file is empty.');
        return;
      }

      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(DeviceFileSource(_savedAudioPath!));

      if (!mounted) return;
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      _showMessage('Playback error: $e');
    }
  }

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
        _prediction = null;
        _analysisError = null;
        _lastSavedPdfPath = null;
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
      body: SingleChildScrollView(
        child: Padding(
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
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
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
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _vehicleType,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'car', child: Text('Car')),
                    DropdownMenuItem(value: 'bike', child: Text('Bike')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _vehicleType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeEngineSound,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.analytics),
                    label: Text(
                      _isAnalyzing ? 'Analyzing...' : 'Analyze Engine Sound',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_prediction != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Engine Sound Report',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Vehicle Type: ${_vehicleType.toUpperCase()}'),
                          const SizedBox(height: 4),
                          Text(
                            'Predicted Result: $_prediction',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          if (_lastSavedPdfPath != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Saved PDF: $_lastSavedPdfPath',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  _isExportingPdf ? null : _downloadReportPdf,
                              icon: _isExportingPdf
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.download),
                              label: Text(
                                _isExportingPdf
                                    ? 'Generating PDF...'
                                    : 'Download PDF Report',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_analysisError != null)
                  Text(
                    'Analysis Error: $_analysisError',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                Text(
                  _savedAudioPath!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}