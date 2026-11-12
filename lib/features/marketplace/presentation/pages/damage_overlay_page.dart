import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../inspection/data/services/damage_analysis_service.dart';

class DamageOverlayPage extends StatefulWidget {
  const DamageOverlayPage({super.key, this.photos = const []});

  /// 360 scan එකේ photos (marketplace එකෙන් open කරන විට හිස්).
  final List<XFile> photos;

  @override
  State<DamageOverlayPage> createState() => _DamageOverlayPageState();
}

class _DamageOverlayPageState extends State<DamageOverlayPage> {
  static const _labels = [
    'Front left',
    'Front right',
    'Rear right',
    'Rear left',
  ];

  static const _demoDamages = [
    ('Front bumper', 'Minor dent', 0.94, Rect.fromLTWH(0.12, 0.48, 0.28, 0.16)),
    ('Left door', 'Paint scratch', 0.87, Rect.fromLTWH(0.50, 0.38, 0.22, 0.22)),
    ('Rear panel', 'Surface mark', 0.78, Rect.fromLTWH(0.70, 0.58, 0.18, 0.15)),
  ];

  final _api = DamageAnalysisService();
  final _pageController = PageController();
  List<PhotoDamageResult>? _results;
  String? _error;
  bool _loading = false;
  int _page = 0;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    if (widget.photos.isNotEmpty) _analyze();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _api.analyzeDamage(widget.photos);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  PhotoDamageResult? _resultFor(int photoIndex) {
    final results = _results;
    if (results == null) return null;
    for (final r in results) {
      if (r.imageIndex == photoIndex) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Damage overlay')),
      body: widget.photos.isEmpty ? _demo(theme) : _content(theme),
    );
  }

  // Demo view (photos නැති විට)
  Widget _demo(ThemeData theme) {
    final sel = _selected.clamp(0, _demoDamages.length - 1);
    final selected = _demoDamages[sel];

    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 3,
            child: AspectRatio(
              aspectRatio: 0.8,
              child: LayoutBuilder(
                builder: (context, c) => Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: const Color(0xffdbeafe),
                      child: Icon(
                        Icons.directions_car_filled_rounded,
                        size: c.maxWidth * 0.72,
                        color: const Color(0xff263746),
                      ),
                    ),
                    for (var i = 0; i < _demoDamages.length; i++)
                      _box(
                        [
                          _demoDamages[i].$4.left,
                          _demoDamages[i].$4.top,
                          _demoDamages[i].$4.width,
                          _demoDamages[i].$4.height,
                        ],
                        c,
                        i == sel,
                        i,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black12)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Detected damage ${sel + 1} of ${_demoDamages.length}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${selected.$1} - ${selected.$2}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${(selected.$3 * 100).round()}% AI confidence · Tap another box to inspect it.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Real view (360 scan photos)
  Widget _content(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() {
              _page = i;
              _selected = 0;
            }),
            itemBuilder: (_, i) => _photoView(i),
          ),
        ),
        _indicator(),
        _detailsCard(theme),
      ],
    );
  }

  Widget _photoView(int index) {
    final result = _resultFor(index);
    final detections = result?.detections ?? const <DamageDetection>[];
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(widget.photos[index].path),
                  fit: BoxFit.contain,
                ),
                for (var i = 0; i < detections.length; i++)
                  if (detections[i].box != null)
                    _box(
                      detections[i].box!,
                      c,
                      i == _selected && index == _page,
                      i,
                    ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              index < _labels.length ? _labels[index] : 'Photo ${index + 1}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        if (_loading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _box(List<double> b, BoxConstraints c, bool selected, int i) {
    final color = selected ? Colors.orange : Colors.red;
    return Positioned(
      left: b[0] * c.maxWidth,
      top: b[1] * c.maxHeight,
      width: b[2] * c.maxWidth,
      height: b[3] * c.maxHeight,
      child: GestureDetector(
        onTap: () => setState(() => _selected = i),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: selected ? 4 : 2),
            color: color.withValues(alpha: 0.12),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              color: color,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _indicator() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < widget.photos.length; i++)
          Container(
            width: i == _page ? 20 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i == _page ? Colors.cyan : Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    ),
  );

  Widget _detailsCard(ThemeData theme) {
    Widget body;
    if (_loading) {
      body = const Text('Analyzing photos...');
    } else if (_error != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis unavailable',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(_error!, maxLines: 4, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _analyze,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      );
    } else {
      final result = _resultFor(_page);
      if (result == null) {
        body = const Text('No analysis result for this photo.');
      } else if (!result.available) {
        body = Text(
          result.notice ?? 'Visual analysis is not available for this photo.',
        );
      } else if (result.detections.isEmpty) {
        body = const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('No damage detected in this photo.')),
          ],
        );
      } else {
        final sel = _selected.clamp(0, result.detections.length - 1);
        final d = result.detections[sel];
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Detected damage ${sel + 1} of ${result.detections.length}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              d.detail == null ? d.label : '${d.label} - ${d.detail}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              d.confidence == null
                  ? 'Confidence not provided'
                  : '${(d.confidence! * 100).round()}% AI confidence',
            ),
            if (result.detections.length > 1) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < result.detections.length; i++)
                    ChoiceChip(
                      label: Text('${i + 1}'),
                      selected: i == sel,
                      onSelected: (_) => setState(() => _selected = i),
                    ),
                ],
              ),
            ],
          ],
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26)],
      ),
      child: body,
    );
  }
}