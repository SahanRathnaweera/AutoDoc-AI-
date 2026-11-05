import 'package:flutter/material.dart';

class DamageOverlayPage extends StatefulWidget {
  const DamageOverlayPage({super.key});

  @override
  State<DamageOverlayPage> createState() => _DamageOverlayPageState();
}

class _DamageOverlayPageState extends State<DamageOverlayPage> {
  int _selectedDamage = 0;
  final damages = const [
    ('Front bumper', 'Minor dent', 0.94, Rect.fromLTWH(0.12, 0.48, 0.28, 0.16)),
    ('Left door', 'Paint scratch', 0.87, Rect.fromLTWH(0.50, 0.38, 0.22, 0.22)),
    ('Rear panel', 'Surface mark', 0.78, Rect.fromLTWH(0.70, 0.58, 0.18, 0.15)),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = damages[_selectedDamage];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Damage overlay'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.zoom_in)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 3,
              child: AspectRatio(
                aspectRatio: 0.8,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: const Color(0xffdbeafe),
                        child: Icon(
                          Icons.directions_car_filled_rounded,
                          size: constraints.maxWidth * 0.72,
                          color: const Color(0xff263746),
                        ),
                      ),
                      for (var index = 0; index < damages.length; index++)
                        Positioned(
                          left: damages[index].$4.left * constraints.maxWidth,
                          top: damages[index].$4.top * constraints.maxHeight,
                          width: damages[index].$4.width * constraints.maxWidth,
                          height:
                              damages[index].$4.height * constraints.maxHeight,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedDamage = index),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: index == _selectedDamage
                                      ? Colors.orange
                                      : Colors.red,
                                  width: index == _selectedDamage ? 4 : 2,
                                ),
                                color: Colors.red.withValues(alpha: 0.12),
                              ),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  color: index == _selectedDamage
                                      ? Colors.orange
                                      : Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: const [
                BoxShadow(blurRadius: 12, color: Colors.black12),
              ],
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
                      'Detected damage ${_selectedDamage + 1} of ${damages.length}',
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
      ),
    );
  }
}
