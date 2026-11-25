import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../inspection/data/services/damage_analysis_service.dart';

class AutoInspectionReportPage extends StatefulWidget {
  const AutoInspectionReportPage({
    super.key,
    required this.photos,
    required this.results,
    required this.angleLabels,
  });

  final List<XFile> photos;
  final List<PhotoDamageResult> results;
  final List<String> angleLabels;

  @override
  State<AutoInspectionReportPage> createState() =>
      _AutoInspectionReportPageState();
}

class _AutoInspectionReportPageState extends State<AutoInspectionReportPage> {
  final Map<int, Uint8List> _loadedBytes = {};
  bool _loadingPhotos = true;
  bool _exportingPdf = false;
  String? _lastSavedPath;

  @override
  void initState() {
    super.initState();
    _loadPhotoBytes();
  }

  Future<void> _loadPhotoBytes() async {
    final map = <int, Uint8List>{};
    for (var i = 0; i < widget.photos.length; i++) {
      try {
        map[i] = await widget.photos[i].readAsBytes();
      } catch (_) {
        // Skip unreadable photo bytes gracefully.
      }
    }
    if (!mounted) return;
    setState(() {
      _loadedBytes.addAll(map);
      _loadingPhotos = false;
    });
  }

  String _angleName(int index) {
    if (index >= 0 && index < widget.angleLabels.length) {
      return widget.angleLabels[index];
    }
    return 'Photo ${index + 1}';
  }

  int get _totalDamagesCount {
    var count = 0;
    for (final r in widget.results) {
      if (r.available) {
        count += r.detections.length;
      }
    }
    return count;
  }

  String get _severitySummary {
    final total = _totalDamagesCount;
    if (total == 0) return 'No damage detected';
    if (total == 1) return 'Minor / 1 damage item found';
    if (total <= 3) return 'Moderate ($total damage items found)';
    return 'Multiple damages ($total items found)';
  }

  String _formatDetection(int number, DamageDetection d) {
    final labelText = d.detail == null ? d.label : '${d.label} (${d.detail})';
    final confText = d.confidence == null
        ? 'confidence N/A'
        : '${(d.confidence! * 100).round()}% confidence';
    return '#$number: $labelText - $confText';
  }

  Future<Uint8List> _buildPdfBytes() async {
    final doc = pw.Document();
    final generatedAt = DateTime.now().toLocal().toString();
    final totalDamages = _totalDamagesCount;

    final angleWidgets = <pw.Widget>[];
    for (var i = 0; i < widget.photos.length; i++) {
      final angle = _angleName(i);
      final result = _resultForPhoto(i);
      final bytes = _loadedBytes[i];
      final detections = (result != null && result.available)
          ? result.detections
          : const <DamageDetection>[];

      final lines = <String>[];
      if (result == null) {
        lines.add('No analysis data available for this angle.');
      } else if (!result.available) {
        lines.add(result.notice ?? 'Visual analysis unavailable.');
      } else if (detections.isEmpty) {
        lines.add('No damage recognized in this angle.');
      } else {
        for (var dIdx = 0; dIdx < detections.length; dIdx++) {
          lines.add(_formatDetection(dIdx + 1, detections[dIdx]));
        }
      }

      angleWidgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 14),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                angle,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              if (bytes != null) ...[
                pw.Container(
                  height: 120,
                  width: double.infinity,
                  alignment: pw.Alignment.center,
                  child: pw.Image(
                    pw.MemoryImage(bytes),
                    fit: pw.BoxFit.contain,
                  ),
                ),
                pw.SizedBox(height: 6),
              ],
              for (final line in lines)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Text(
                    '• $line',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'AutoDoc AI - Inspection Report',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Generated on: $generatedAt',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Inspected photos: ${widget.photos.length}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Total detected damages: $totalDamages',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Assessment status: $_severitySummary',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Divider(height: 20),
          pw.Text(
            'Recognized Damages by Angle',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...angleWidgets,
        ],
      ),
    );

    return doc.save();
  }

  Future<String> _savePdfToDevice(Uint8List bytes, String fileName) async {
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

  Future<void> _downloadPdfReport() async {
    if (_exportingPdf || _loadingPhotos) return;
    setState(() => _exportingPdf = true);

    try {
      final pdfBytes = await _buildPdfBytes();
      final fileName =
          'inspection_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedPath = await _savePdfToDevice(pdfBytes, fileName);

      if (!mounted) return;
      setState(() => _lastSavedPath = savedPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved: $savedPath')),
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalDamages = _totalDamagesCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Inspection Report'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Automatic Damage Summary',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Inspected photos: ${widget.photos.length}'),
                  Text('Total detected damages: $totalDamages'),
                  Text('Assessment status: $_severitySummary'),
                  Text('Generated on: ${DateTime.now().toLocal()}'),
                  if (_lastSavedPath != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Saved file: $_lastSavedPath',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Recognized Damages by Angle',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingPhotos)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            for (var i = 0; i < widget.photos.length; i++)
              _buildAngleCard(context, i, _resultForPhoto(i)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: (_exportingPdf || _loadingPhotos) ? null : _downloadPdfReport,
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
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Back to Damage Overlay'),
          ),
        ],
      ),
    );
  }

  PhotoDamageResult? _resultForPhoto(int photoIndex) {
    for (final r in widget.results) {
      if (r.imageIndex == photoIndex) return r;
    }
    if (photoIndex < widget.results.length) {
      return widget.results[photoIndex];
    }
    return null;
  }

  Widget _buildAngleCard(
    BuildContext context,
    int index,
    PhotoDamageResult? result,
  ) {
    final angle = _angleName(index);
    final bytes = _loadedBytes[index];
    final detections = (result != null && result.available)
        ? result.detections
        : const <DamageDetection>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              angle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (bytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  bytes,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 10),
            if (result == null)
              const Text('No analysis data available for this angle.')
            else if (!result.available)
              Text(result.notice ?? 'Visual analysis unavailable.')
            else if (detections.isEmpty)
              const Text('No damage recognized in this angle.')
            else
              for (var dIdx = 0; dIdx < detections.length; dIdx++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(
                        child: Text(
                          _formatDetection(dIdx + 1, detections[dIdx]),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}