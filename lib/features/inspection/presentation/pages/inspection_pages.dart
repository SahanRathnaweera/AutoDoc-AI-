import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/show_snackbar.dart';
import '../../data/services/inspection_api_service.dart';
import '../../data/services/inspection_report_pdf_service.dart';
import '../../domain/entities/inspection_report.dart';

const _navy = Color(0xff071722);
const _panel = Color(0xff102936);
const _blue = Color(0xff1688f2);
const _cyan = Color(0xff21d2e8);

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _InspectionShell(
      title: 'AutoDoc AI',
      selectedIndex: 0,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
        children: [
          Row(
            children: [
              Text(
                'Good morning',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              const CircleAvatar(
                radius: 17,
                child: Icon(Icons.person_outline, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _HealthCard(score: 70),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: '2019 Tesla Model 3',
            decoration: const InputDecoration(
              labelText: 'Vehicle selected',
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: '2019 Tesla Model 3',
                child: Text('2019 Tesla Model 3'),
              ),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              _ActionTile(
                icon: Icons.center_focus_strong,
                label: '360 Scan',
                accent: true,
                onTap: () => context.push('/dashboard/camera'),
              ),
              _ActionTile(
                icon: Icons.graphic_eq,
                label: 'Check Engine Audio',
                onTap: () => context.push('/dashboard/engine-sound'),
              ),
              _ActionTile(
                icon: Icons.document_scanner_outlined,
                label: 'Scan Odometer',
                onTap: () => context.push('/dashboard/ocr'),
              ),
              _ActionTile(
                icon: Icons.history,
                label: 'View History',
                onTap: () => context.push('/dashboard/report'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Recent scan activity',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const _ActivityRow(
            icon: Icons.check_circle,
            title: 'Exterior scan completed',
            value: '92',
            color: Colors.green,
          ),
          const _ActivityRow(
            icon: Icons.check_circle,
            title: 'Engine audio reviewed',
            value: '86',
            color: Colors.green,
          ),
          const _ActivityRow(
            icon: Icons.warning_amber_rounded,
            title: 'Minor damage detected',
            value: '3',
            color: Colors.orange,
          ),
        ],
      ),
      onDestinationSelected: (index) {
        if (index == 1) context.go('/marketplace');
        if (index == 2) context.go('/dashboard/report');
        if (index == 3) context.go('/profile');
      },
    );
  }
}

class _ScanAngle {
  const _ScanAngle(this.label, this.hint, this.icon, this.flip);
  final String label;
  final String hint;
  final IconData icon;
  final bool flip;
}

class GuidedCameraPage extends StatefulWidget {
  const GuidedCameraPage({super.key});

  @override
  State<GuidedCameraPage> createState() => _GuidedCameraPageState();
}

class _GuidedCameraPageState extends State<GuidedCameraPage>
    with WidgetsBindingObserver {
  static const _angles = [
    _ScanAngle('Front left', 'Stand at the front-left corner of the car',
        Icons.directions_car_filled_rounded, false),
    _ScanAngle('Front right', 'Move to the front-right corner',
        Icons.directions_car_filled_rounded, true),
    _ScanAngle('Rear right', 'Move to the rear-right corner',
        Icons.directions_car_filled_rounded, false),
    _ScanAngle('Rear left', 'Move to the rear-left corner',
        Icons.directions_car_filled_rounded, true),
  ];

  CameraController? _controller;
  Future<void> _cameraOperation = Future<void>.value();
  int _cameraGeneration = 0;
  String? _error;
  bool _capturing = false;
  int _current = 0;
  final Map<int, XFile> _photos = {};
  final Map<int, Uint8List> _photoBytes = {};

  double get _progress => _photos.length / _angles.length;
  bool get _allDone => _photos.length == _angles.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  void _initCamera() {
    final generation = ++_cameraGeneration;
    _cameraOperation = _cameraOperation.then((_) => _openCamera(generation));
  }

  bool _cameraRequestIsCurrent(int generation) =>
      mounted && generation == _cameraGeneration;

  Future<void> _openCamera(int generation) async {
    if (!_cameraRequestIsCurrent(generation) || _controller != null) return;

    CameraController? opening;
    try {
      final cameras = await availableCameras();
      if (!_cameraRequestIsCurrent(generation)) return;
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }

      final back = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      opening = controller;
      await controller.initialize();
      if (!_cameraRequestIsCurrent(generation)) return;

      setState(() {
        _controller = controller;
        _error = null;
      });
      opening = null;
    } on CameraException catch (error) {
      if (!_cameraRequestIsCurrent(generation)) return;
      setState(() {
        _error = error.code.startsWith('CameraAccessDenied')
            ? 'Camera permission denied. Enable it in Settings to scan.'
            : 'Camera error: ${error.description ?? error.code}';
      });
    } catch (error) {
      if (_cameraRequestIsCurrent(generation)) {
        setState(() => _error = 'Could not start camera: $error');
      }
    } finally {
      await _disposeCamera(opening);
    }
  }

  void _releaseCamera() {
    _cameraGeneration++;
    final controller = _controller;
    _controller = null;
    _cameraOperation = _cameraOperation.then((_) => _disposeCamera(controller));
  }

  Future<void> _disposeCamera(CameraController? controller) async {
    try {
      await controller?.dispose();
    } catch (error) {
      debugPrint('Could not release camera: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      setState(_releaseCamera);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _releaseCamera();
    super.dispose();
  }

  int? _nextEmptyIndex() {
    for (var i = 0; i < _angles.length; i++) {
      if (!_photos.containsKey(i)) return i;
    }
    return null;
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _capturing) {
      return;
    }
    final angle = _current;
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted || _controller != controller) return;
      setState(() {
        _photos[angle] = file;
        _photoBytes[angle] = bytes;
        final next = _nextEmptyIndex();
        if (next != null) _current = next;
      });
    } on CameraException catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          'Capture failed: ${e.description ?? e.code}',
        );
      }
    } catch (error) {
      if (mounted) showCustomSnackBar(context, 'Could not read photo: $error');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _retakeAll() {
    setState(() {
      _photos.clear();
      _photoBytes.clear();
      _current = 0;
    });
  }

  void _finish() {
    if (!_allDone || _capturing) return;
    final photos = [for (var i = 0; i < _angles.length; i++) _photos[i]!];
    context.pushReplacement('/dashboard/damage', extra: photos);
  }

  Widget _buildPreview() {
    final captured = _photoBytes[_current];
    if (captured != null) return Image.memory(captured, fit: BoxFit.cover);

    if (_error != null) {
      return Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, size: 48, color: Colors.white54),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                setState(() => _error = null);
                _initCamera();
              },
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.previewSize?.height ?? 1,
        height: controller.value.previewSize?.width ?? 1,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildGuide() {
    final angle = _angles[_current];
    if (_photos.containsKey(_current)) return const SizedBox.shrink();
    return IgnorePointer(
      child: Center(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(angle.flip ? -1.0 : 1.0, 1.0, 1.0),
          child: Icon(
            angle.icon,
            size: 220,
            color: _cyan.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnails() {
    return SizedBox(
      height: 84,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _angles.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _thumb(i),
          ],
        ],
      ),
    );
  }

  Widget _thumb(int index) {
    final photo = _photoBytes[index];
    final selected = index == _current;
    return GestureDetector(
      onTap: () => setState(() => _current = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? _blue
                    : photo != null
                        ? Colors.greenAccent
                        : Colors.white12,
                width: selected ? 3 : 2,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo != null)
                  Image.memory(photo, fit: BoxFit.cover)
                else
                  Icon(
                    Icons.directions_car_outlined,
                    color: selected ? Colors.white : Colors.white38,
                  ),
                if (photo != null)
                  const Positioned(
                    right: 2,
                    top: 2,
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.greenAccent,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _angles[index].label,
            style: TextStyle(
              fontSize: 10,
              color: selected ? Colors.white : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final angle = _angles[_current];
    final reviewing = _photos.containsKey(_current);
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text('Guided 360 scan'),
        backgroundColor: Colors.transparent,
        actions: [
          if (_photos.isNotEmpty)
            TextButton(
              onPressed: _capturing ? null : _retakeAll,
              child: const Text('Reset'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
                backgroundColor: Colors.white12,
                color: _cyan,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _cyan.withValues(alpha: 0.55)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPreview(),
                  _buildGuide(),
                  Positioned(
                    top: 14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _CameraBadge(
                        label:
                            '${angle.label} · ${(_progress * 100).round()}%',
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 12,
                    right: 12,
                    child: Center(
                      child: Text(
                        reviewing
                            ? 'Captured. Tap the shutter to retake.'
                            : angle.hint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildThumbnails(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _allDone
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _controller == null || _capturing
                            ? null
                            : _capture,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retake'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _finish,
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                      ),
                    ],
                  )
                : FloatingActionButton(
                    onPressed:
                        _controller == null || _capturing ? null : _capture,
                    backgroundColor: Colors.white,
                    foregroundColor: _navy,
                    child: _capturing
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_outlined),
                  ),
          ),
        ],
      ),
    );
  }
}

class DiagnosticPage extends StatelessWidget {
  const DiagnosticPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _InspectionScaffold(
      title: 'Engine diagnostic results',
      children: [
        const _HealthCard(score: 80, label: 'Engine health score'),
        const SizedBox(height: 18),
        const _InfoBanner(
          icon: Icons.check_circle,
          text: 'No significant abnormalities detected.',
          color: Colors.green,
        ),
        const SizedBox(height: 18),
        Text(
          'Completed checks',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const _CheckItem(label: 'Engine audio pattern', detail: 'Completed'),
        const _CheckItem(label: 'Idle vibration', detail: 'Completed'),
        const _CheckItem(label: 'Cold start response', detail: 'Completed'),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: () => context.push('/dashboard/report'),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Start inspection & report'),
        ),
      ],
    );
  }
}

class OcrPage extends StatelessWidget {
  const OcrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _InspectionScaffold(
      title: 'On-device OCR scanner',
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: const Color(0xff233a43),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.directions_car_filled_rounded,
                size: 150,
                color: Color(0xff61747a),
              ),
              Container(
                width: 260,
                height: 110,
                decoration: BoxDecoration(
                  border: Border.all(color: _cyan, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const Positioned(
                bottom: 16,
                child: Text('Scan registration or odometer'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _OcrField(label: 'Registration number', value: 'WP CAA-2048'),
        const _OcrField(label: 'Model year', value: '2019'),
        const _OcrField(label: 'Odometer reading', value: '64,320 km'),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.check),
          label: const Text('Confirm extracted data'),
        ),
      ],
    );
  }
}

class InspectionReportPage extends StatefulWidget {
  const InspectionReportPage({super.key, this.photos = const []});

  final List<XFile> photos;

  @override
  State<InspectionReportPage> createState() => _InspectionReportPageState();
}

class _InspectionReportPageState extends State<InspectionReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _registrationController = TextEditingController();
  final _repairAllowanceController = TextEditingController(text: '0');
  final _api = InspectionApiService();
  final _imagePicker = ImagePicker();
  String _vehicleType = 'car';
  bool _isDemoMode = false;
  late List<XFile> _images = List.of(widget.photos);
  PlatformFile? _audio;
  InspectionReport? _report;
  bool _isSubmitting = false;
  bool _isGeneratingPdf = false;

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _registrationController.dispose();
    _repairAllowanceController.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage(imageQuality: 90);
      if (!mounted || images.isEmpty) return;
      if (images.length > 6) {
        showCustomSnackBar(context, 'Select no more than 6 photos.');
        return;
      }
      setState(() => _images = images);
    } catch (error) {
      if (mounted) {
        showCustomSnackBar(context, 'Could not open the photo picker: $error');
      }
    }
  }

  Future<void> _pickAudio() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.audio);
      if (!mounted || file == null) return;
      setState(() => _audio = file);
    } catch (error) {
      if (mounted) {
        showCustomSnackBar(context, 'Could not open the audio picker: $error');
      }
    }
  }

  Future<void> _runInspection() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      showCustomSnackBar(
        context,
        'Select 1 to 6 JPEG or PNG inspection photos.',
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final report = await _api.createReport(
        vehicleType: _vehicleType,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        mileageKm: double.parse(_mileageController.text.trim()),
        reviewedRepairAllowanceLkr:
            double.tryParse(_repairAllowanceController.text.trim()) ?? 0,
        registrationNumber: _registrationController.text.trim(),
        images: _images,
        audio: _audio?.xFile,
      );
      if (!mounted) return;
      setState(() => _report = report);
      showCustomSnackBar(
        context,
        'Inspection report generated from backend results.',
        isError: false,
      );
    } catch (error) {
      if (!mounted) return;
      showCustomSnackBar(context, 'Inspection could not be completed: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _runDemoInspection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final random = Random();
      final baseEstimate = (random.nextInt(19_000_001) + 1_000_000).toDouble();
      final repairAllowance =
          double.tryParse(_repairAllowanceController.text.trim()) ?? 0;
      const audioLabels = [
        'SIMULATED: normal sound',
        'SIMULATED: rough-idle-like sound',
        'SIMULATED: possible knocking-like sound',
        'SIMULATED: possible belt-noise-like sound',
      ];
      final generatedAt = DateTime.now();
      final report = InspectionReport(
        reportId: 'DEMO-${generatedAt.millisecondsSinceEpoch}',
        vehicleName:
            '${_yearController.text.trim()} ${_makeController.text.trim()} '
            '${_modelController.text.trim()}',
        registrationNumber: _registrationController.text.trim(),
        generatedAt: generatedAt,
        currency: 'DEMO LKR',
        baseEstimate: baseEstimate,
        adjustedEstimate: max(0.0, baseEstimate - repairAllowance),
        repairAllowance: repairAllowance,
        photosAnalyzed: 0,
        findings: const [],
        audioLabel: audioLabels[random.nextInt(audioLabels.length)],
        audioNotice:
            'Random demo placeholder only; no recording or audio model was used.',
        valuationNotice:
            'Random demo amount only; it is not a market valuation.',
        voiceSummary:
            'Simulated report for interface and PDF testing. No vehicle '
            'photos or engine audio were analyzed.',
        isSimulated: true,
      );
      if (!mounted) return;
      setState(() => _report = report);
      showCustomSnackBar(
        context,
        'Simulated demo report created. No inspection was performed.',
        isError: false,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sharePdf() async {
    final report = _report;
    if (report == null) return;
    setState(() => _isGeneratingPdf = true);

    try {
      final shared = await InspectionReportPdfService.sharePdf(report);
      if (!mounted) return;
      if (shared) {
        showCustomSnackBar(
          context,
          'PDF report is ready to save or share.',
          isError: false,
        );
      }
    } catch (error) {
      if (!mounted) return;
      showCustomSnackBar(context, 'Could not generate the PDF report: $error');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InspectionScaffold(
      title: 'Automated inspection report',
      useThemeBackground: true,
      children: _report == null
          ? _buildInspectionForm()
          : _buildReport(_report!),
    );
  }

  List<Widget> _buildInspectionForm() => [
    const Text(
      'Vehicle information',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 12),
    Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _vehicleType,
            decoration: const InputDecoration(labelText: 'Vehicle type'),
            items: const [
              DropdownMenuItem(value: 'car', child: Text('Car')),
              DropdownMenuItem(value: 'bike', child: Text('Motorcycle')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _vehicleType = value);
            },
          ),
          const SizedBox(height: 12),
          _textField(_makeController, 'Make', required: true),
          const SizedBox(height: 12),
          _textField(_modelController, 'Model', required: true),
          const SizedBox(height: 12),
          _textField(
            _yearController,
            'Model year',
            keyboardType: TextInputType.number,
            validator: (value) {
              final year = int.tryParse(value?.trim() ?? '');
              if (year == null || year < 1950) {
                return 'Enter a valid model year (1950 or later).';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _textField(
            _mileageController,
            'Odometer (km)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final mileage = double.tryParse(value?.trim() ?? '');
              if (mileage == null || !mileage.isFinite || mileage < 0) {
                return 'Enter a valid odometer reading.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _textField(
            _registrationController,
            'Registration number',
            required: true,
          ),
          const SizedBox(height: 12),
          _textField(
            _repairAllowanceController,
            'Reviewed repair allowance (LKR)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final allowance = double.tryParse(value?.trim() ?? '');
              if (allowance == null || !allowance.isFinite || allowance < 0) {
                return 'Enter zero or a valid non-negative allowance.';
              }
              return null;
            },
          ),
        ],
      ),
    ),
    const SizedBox(height: 12),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Demo mode (simulated output)'),
      subtitle: const Text(
        'Uses a random placeholder amount and audio label. No media or '
        'inspection models are used.',
      ),
      value: _isDemoMode,
      onChanged: _isSubmitting
          ? null
          : (enabled) => setState(() => _isDemoMode = enabled),
    ),
    if (!_isDemoMode) ...[
      const SizedBox(height: 20),
      const Text(
        'Inspection media',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text(
        'Choose 1-6 clear JPEG/PNG vehicle photos. Add a non-silent, unclipped '
        '10-15 second engine recording if available; audio is classified only '
        'when the backend has a compatible model. Unsupported analysis is '
        'reported as unavailable, never replaced with a simulated result.',
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _isSubmitting ? null : _pickImages,
        icon: const Icon(Icons.photo_library_outlined),
        label: Text(
          _images.isEmpty
              ? 'Select vehicle photos'
              : '${_images.length} photos selected',
        ),
      ),
      if (_images.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _images.map((image) => image.name).join(', '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _isSubmitting ? null : _pickAudio,
        icon: const Icon(Icons.audio_file_outlined),
        label: Text(_audio?.name ?? 'Add optional engine audio'),
      ),
    ],
    const SizedBox(height: 20),
    FilledButton.icon(
      onPressed: _isSubmitting
          ? null
          : _isDemoMode
          ? _runDemoInspection
          : _runInspection,
      icon: _isSubmitting
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.document_scanner_outlined),
      label: Text(
        _isSubmitting
            ? 'Generating report...'
            : _isDemoMode
            ? 'Generate simulated report'
            : 'Run inspection',
      ),
    ),
    if (!_isDemoMode) ...[
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _isSubmitting ? null : _runDemoInspection,
        icon: const Icon(Icons.science_outlined),
        label: const Text('Generate simulated demo report'),
      ),
      const SizedBox(height: 4),
      const Text(
        'Use this if inspection models are unavailable. The amount and audio '
        'label are random placeholders, not real results.',
        textAlign: TextAlign.center,
      ),
    ],
  ];

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(labelText: label),
    validator:
        validator ??
        (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return '$label is required.';
          }
          return null;
        },
  );

  List<Widget> _buildReport(InspectionReport report) {
    final palette = AppPalette.of(context);
    return [
      if (report.isSimulated)
        _InfoBanner(
          icon: Icons.warning_amber_rounded,
          textColor: palette.text,
          text:
              'SIMULATED DEMO REPORT — random placeholders only. No photos or '
              'audio were analyzed. Do not use for real decisions.',
          color: Colors.deepOrange,
        ),
      if (report.isSimulated) const SizedBox(height: 12),
      if (!report.isSimulated && report.isPartial)
        _InfoBanner(
          icon: Icons.warning_amber_rounded,
          textColor: palette.text,
          text:
              'Partial live inspection. Unavailable: '
              '${report.unavailableComponents.isEmpty ? 'some analysis components' : report.unavailableComponents.join(', ')}. '
              'No substitute values were generated.',
          color: Colors.orange,
        ),
      if (!report.isSimulated && report.isPartial) const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AutoDoc AI',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: palette.text, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              report.isSimulated
                  ? 'Simulated placeholder output'
                  : report.isPartial
                  ? 'Partial live inspection results'
                  : 'AI-assisted inspection summary',
              style: TextStyle(color: palette.muted),
            ),
            Divider(height: 28, color: palette.line),
            Text(
              report.vehicleName,
              style: TextStyle(color: palette.text, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _ReportLine(label: 'Registration', value: report.registrationNumber),
            _ReportLine(label: 'Report ID', value: report.reportId),
            _ReportLine(label: 'Generated', value: report.generatedDate),
            _ReportLine(
              label: 'Photos analyzed',
              value: '${report.photosAnalyzed}',
            ),
            _ReportLine(label: 'Damage findings', value: report.damageSummary),
            _ReportLine(label: 'Engine audio label', value: report.audioLabel),
            _ReportLine(
              label: 'Base valuation estimate',
              value: report.baseEstimateLabel,
            ),
            _ReportLine(
              label: 'Reviewed repair allowance',
              value: report.repairAllowanceLabel,
            ),
            _ReportLine(
              label: 'Adjusted valuation estimate',
              value: report.adjustedEstimateLabel,
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visual findings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (report.findings.isEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                textColor: palette.text,
                iconColor: palette.muted,
                leading: Icon(
                  report.isSimulated || !report.visualAnalysisAvailable
                      ? Icons.info_outline
                      : Icons.check_circle_outline,
                ),
                title: Text(
                  report.isSimulated
                      ? 'Visual analysis was not performed in demo mode.'
                      : !report.visualAnalysisAvailable
                      ? report.visualNotice
                      : 'No findings returned by the visual analysis.',
                ),
              )
            else
              for (var index = 0; index < report.findings.length; index++)
                _findingTile(report.findings[index], index, palette),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _InfoBanner(
        icon: Icons.graphic_eq,
        textColor: palette.text,
        text: '${report.audioLabel}. ${report.audioNotice}',
        color: Colors.orange,
      ),
      const SizedBox(height: 12),
      _InfoBanner(
        icon: Icons.info_outline,
        textColor: palette.text,
        text: [report.valuationNotice, report.voiceSummary]
            .where((part) => part.trim().isNotEmpty)
            .join('\n\n'),
        color: Colors.blue,
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: _isGeneratingPdf ? null : _sharePdf,
        icon: _isGeneratingPdf
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.picture_as_pdf),
        label: Text(
          _isGeneratingPdf ? 'Preparing PDF...' : 'Download / share PDF report',
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _isSubmitting || _isGeneratingPdf
            ? null
            : () => setState(() => _report = null),
        icon: const Icon(Icons.refresh),
        label: const Text('Start another inspection'),
      ),
    ];
  }

  Widget _findingTile(
    InspectionFinding finding,
    int index,
    AppPalette palette,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
    title: Text(
      '${index + 1}. ${finding.label}',
      style: TextStyle(color: palette.text, fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      'Photo ${finding.imageIndex + 1} · ${finding.confidenceLabel}'
      '${finding.detail == null ? '' : '\n${finding.detail}'}',
      style: TextStyle(color: palette.muted),
    ),
  );
}

class _InspectionShell extends StatelessWidget {
  const _InspectionShell({
    required this.title,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final String title;
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _navy,
    appBar: AppBar(
      title: Text(title),
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          tooltip: 'Settings',
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    ),
    body: body,
    bottomNavigationBar: NavigationBar(
      backgroundColor: _panel,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          label: 'Market',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Reports',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    ),
  );
}

class _InspectionScaffold extends StatelessWidget {
  const _InspectionScaffold({
    required this.title,
    required this.children,
    this.useThemeBackground = false,
  });

  final String title;
  final List<Widget> children;
  final bool useThemeBackground;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: useThemeBackground ? AppPalette.of(context).bg : _navy,
    appBar: AppBar(title: Text(title), backgroundColor: Colors.transparent),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: children,
      ),
    ),
  );
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.score, this.label = 'Vehicle health score'});

  final int score;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 8,
                backgroundColor: Colors.white10,
                color: _blue,
              ),
              Text(
                '$score',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text('Based on visual, engine, and document checks.'),
              const SizedBox(height: 12),
              const Text(
                'Excellent condition',
                style: TextStyle(color: _cyan, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) => Card(
    color: accent ? _blue : _panel,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: color),
    title: Text(title),
    trailing: Text(
      value,
      style: TextStyle(color: color, fontWeight: FontWeight.w700),
    ),
  );
}

class _CameraBadge extends StatelessWidget {
  const _CameraBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(label),
    ),
  );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.text,
    required this.color,
    this.textColor,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: textColor))),
      ],
    ),
  );
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.check_circle, color: Colors.green),
    title: Text(label),
    trailing: Text(detail, style: Theme.of(context).textTheme.bodySmall),
  );
}

class _OcrField extends StatelessWidget {
  const _OcrField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: Theme.of(context).textTheme.bodySmall),
    subtitle: Text(
      value,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
    trailing: const Icon(Icons.check_circle, color: Colors.green),
  );
}

class _ReportLine extends StatelessWidget {
  const _ReportLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: palette.muted)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              softWrap: true,
              style: TextStyle(color: palette.text, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
