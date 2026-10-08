import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                onTap: () => context.push('/dashboard/diagnostics'),
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

class GuidedCameraPage extends StatelessWidget {
  const GuidedCameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        title: const Text('Guided 360 scan'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xff1b303a),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _cyan.withValues(alpha: 0.55)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.directions_car_filled_rounded,
                    size: 210,
                    color: Color(0xff39505a),
                  ),
                  Positioned(
                    top: 18,
                    child: _CameraBadge(label: 'Front left · 25%'),
                  ),
                  Positioned(
                    bottom: 26,
                    child: Text(
                      'Align the vehicle inside the guide',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      border: Border.all(color: _cyan, width: 2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) => Container(
                width: 68,
                decoration: BoxDecoration(
                  color: index == 1 ? _blue : _panel,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_car_outlined),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: FloatingActionButton(
              onPressed: () => context.push('/dashboard/damage'),
              backgroundColor: Colors.white,
              foregroundColor: _navy,
              child: const Icon(Icons.camera_alt_outlined),
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
          label: const Text('Generate full report'),
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

class InspectionReportPage extends StatelessWidget {
  const InspectionReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _InspectionScaffold(
      title: 'AI valuation & report',
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AutoDoc AI',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: _navy, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Vehicle health certificate',
                style: TextStyle(color: Colors.black54),
              ),
              const Divider(height: 28),
              const Center(child: _ReportScore()),
              const SizedBox(height: 18),
              const Text(
                '2019 Tesla Model 3',
                style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const _ReportLine(
                label: 'AI valuation',
                value: '\$25,500 - \$27,000',
              ),
              const _ReportLine(
                label: 'Verified checks',
                value: '18 completed',
              ),
              const _ReportLine(
                label: 'Damage findings',
                value: '3 minor areas',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Download PDF certificate'),
        ),
      ],
    );
  }
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
  const _InspectionScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _navy,
    appBar: AppBar(title: Text(title), backgroundColor: Colors.transparent),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: children,
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
  });

  final IconData icon;
  final String text;
  final Color color;

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
        Expanded(child: Text(text)),
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

class _ReportScore extends StatelessWidget {
  const _ReportScore();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 92,
    height: 92,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CircularProgressIndicator(value: 0.8, strokeWidth: 8, color: _blue),
        Text(
          '80',
          style: TextStyle(
            color: _navy,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _ReportLine extends StatelessWidget {
  const _ReportLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
