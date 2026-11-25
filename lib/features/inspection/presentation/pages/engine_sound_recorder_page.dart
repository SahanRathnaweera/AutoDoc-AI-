import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:record/record.dart';

import '../../data/services/engine_sound_analysis_service.dart';

class EngineSoundRecorderPage extends StatefulWidget {
  const EngineSoundRecorderPage({super.key});

  @override
  State<EngineSoundRecorderPage> createState() => _EngineSoundRecorderPageState();
}

class _EngineSoundRecorderPageState extends State<EngineSoundRecorderPage> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final EngineSoundAnalysisService _analysisService =
      EngineSoundAnalysisService();

  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isAnalyzing = false;
  bool _exportingPdf = false;
  String? _recordedPath;
  String? _lastSavedPdfPath;
  EngineSoundReportData? _report;
  String? _errorText;

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() {
      _errorText = null;
      _report = null;
      _lastSavedPdfPath = null;
    });

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        setState(() {
          _errorText =
              'Microphone permission is required to record engine sound.';
        });
        return;
      }

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}${Platform.pathSeparator}engine_sound_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: filePath,
      );

      _timer?.cancel();
      setState(() {
        _isRecording = true;
        _secondsElapsed = 0;
        _recordedPath = null;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() => _secondsElapsed++);
        if (_secondsElapsed >= 15) {
          _stopRecording();
        }
      });
    } catch (e) {
      setState(() {
        _isRecording = false;
        _errorText = 'Could not start recording: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    try {
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });
      if (path != null) {
        await _analyzeAudio(path, _secondsElapsed > 0 ? _secondsElapsed : 1);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _errorText = 'Could not stop recording: $e';
      });
    }
  }

  Future<void> _analyzeAudio(String path, int duration) async {
    setState(() {
      _isAnalyzing = true;
      _errorText = null;
    });

    try {
      final report = await _analysisService.analyzeRecording(
        audioPath: path,
        durationSeconds: duration,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorText = 'Analysis failed: $e';
      });
    }
  }

  Future<void> _togglePreview() async {
    final path = _recordedPath;
    if (path == null) return;

    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isPlaying = true);
    await _player.play(DeviceFileSource(path));
    _player.onPlayerComplete.first.then((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<Uint8List> _buildSoundReportPdf(EngineSoundReportData report) async {
    final doc = pw.Document();

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
              'Generated on: ${report.generatedAt.toLocal()}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Divider(height: 20),
            pw.Text(
              'Detected Condition: ${report.conditionLabel}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Severity: ${report.severity}'),
            pw.Text('Dataset Match Confidence: ${report.confidencePercent}%'),
            pw.Text('Recording Duration: ${report.durationSeconds}s'),
            pw.SizedBox(height: 14),
            pw.Text(
              'Observed Characteristics',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            for (final item in report.observedCharacteristics)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('• $item', style: const pw.TextStyle(fontSize: 10)),
              ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Recommended Next Steps',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            for (final rec in report.recommendations)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('• $rec', style: const pw.TextStyle(fontSize: 10)),
              ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  Future<String> _savePdfLocally(Uint8List bytes, String fileName) async {
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

  Future<void> _downloadSoundReportPdf() async {
    final report = _report;
    if (report == null || _exportingPdf || _isAnalyzing) return;

    setState(() => _exportingPdf = true);
    try {
      final bytes = await _buildSoundReportPdf(report);
      final fileName =
          'engine_sound_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedPath = await _savePdfLocally(bytes, fileName);

      if (!mounted) return;
      setState(() {
        _lastSavedPdfPath = savedPath;
        _exportingPdf = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved: $savedPath')),
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _exportingPdf = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Engine Sound Recorder'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    size: 48,
                    color: _isRecording ? Colors.red : theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRecording
                        ? 'Recording engine sound... (${_secondsElapsed}s / 15s)'
                        : 'Tap Record to capture 10–15s of engine audio',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.fiber_manual_record,
                    ),
                    label: Text(
                      _isRecording ? 'Stop Recording' : 'Start Recording',
                    ),
                  ),
                  if (_recordedPath != null && !_isRecording) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _togglePreview,
                          icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                          label: Text(
                            _isPlaying ? 'Stop Audio' : 'Play Recording',
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: _isAnalyzing
                              ? null
                              : () => _analyzeAudio(
                                    _recordedPath!,
                                    _secondsElapsed > 0 ? _secondsElapsed : 1,
                                  ),
                          icon: const Icon(Icons.analytics_outlined),
                          label: const Text('Re-analyze'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _errorText!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          ],
          if (_isAnalyzing) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 8),
            const Center(
              child: Text('Analyzing sound against engine dataset...'),
            ),
          ],
          if (_report != null && !_isAnalyzing) ...[
            const SizedBox(height: 16),
            _buildReportCard(theme, _report!),
          ],
        ],
      ),
    );
  }

  Widget _buildReportCard(ThemeData theme, EngineSoundReportData report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Engine Sound Report',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Detected Condition: ${report.conditionLabel}'),
            Text('Severity: ${report.severity}'),
            Text('Dataset Match Confidence: ${report.confidencePercent}%'),
            Text('Recording Duration: ${report.durationSeconds}s'),
            const SizedBox(height: 12),
            Text(
              'Observed Characteristics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (final item in report.observedCharacteristics)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $item'),
              ),
            const SizedBox(height: 12),
            Text(
              'Recommended Next Steps',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (final rec in report.recommendations)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $rec'),
              ),
            if (_lastSavedPdfPath != null) ...[
              const SizedBox(height: 10),
              Text(
                'Saved PDF: $_lastSavedPdfPath',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _exportingPdf ? null : _downloadSoundReportPdf,
                icon: _exportingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  _exportingPdf ? 'Generating PDF...' : 'Download PDF Report',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}