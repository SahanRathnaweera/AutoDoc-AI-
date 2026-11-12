import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/widgets/stencil_hero.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = AppPalette.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting,
                        style: text.titleSmall?.copyWith(color: p.muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Inspect a vehicle',
                        style: text.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StencilHero(onStart: () => context.push('/dashboard/camera')),
            const SizedBox(height: 28),
            Text(
              'Tools',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _ToolRow(
              icon: Icons.document_scanner_outlined,
              title: 'Scan license',
              subtitle: 'Fill in vehicle details from the revenue license',
              onTap: () => context.push('/dashboard/ocr'),
            ),
            _ToolRow(
              icon: Icons.graphic_eq,
              title: 'Check engine sound',
              subtitle: '10 to 15 seconds, in a quiet place',
              onTap: () => context.push('/dashboard/diagnostics'),
            ),
            _ToolRow(
              icon: Icons.car_crash_outlined,
              title: 'View damage',
              subtitle: 'Scratches, dents and rust found in your photos',
              onTap: () => context.push('/dashboard/damage'),
            ),
            _ToolRow(
              icon: Icons.description_outlined,
              title: 'Inspection report',
              subtitle: 'Create a PDF you can share',
              onTap: () => context.push('/dashboard/report'),
            ),
            _ToolRow(
              icon: Icons.storefront_outlined,
              title: 'Marketplace',
              subtitle: 'Browse or list vehicles with verified reports',
              onTap: () => context.go('/marketplace'),
              isLast: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) context.go('/marketplace');
          if (index == 2) context.go('/dashboard/report');
          if (index == 3) context.go('/profile');
        },
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
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = AppPalette.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: p.line)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26, color: p.text),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(color: p.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.muted),
          ],
        ),
      ),
    );
  }
}