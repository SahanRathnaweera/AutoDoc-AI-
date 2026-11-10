import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/vehicle.dart';

class VehicleDetailPage extends StatelessWidget {
  const VehicleDetailPage({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final vehicle = demoVehicles.firstWhere(
      (item) => item.id == vehicleId,
      orElse: () => demoVehicles.first,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle details'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Contact seller'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _DetailImage(vehicle: vehicle),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${vehicle.year} ${vehicle.name}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '\$${vehicle.price}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 4),
                    Text(vehicle.location),
                    const Spacer(),
                    const Icon(Icons.verified, color: Colors.green, size: 18),
                    const SizedBox(width: 4),
                    const Text('Verified listing'),
                  ],
                ),
                const SizedBox(height: 22),
                _HealthScore(score: vehicle.healthScore),
                const SizedBox(height: 24),
                Text(
                  'AI inspection report',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.center_focus_strong,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: const Text('Damage overlay available'),
                  subtitle: const Text(
                    'Review detected areas on the vehicle image.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push('/marketplace/vehicle/${vehicle.id}/damage'),
                ),
                const Divider(height: 28),
                Text(
                  'Seller',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Icon(Icons.person)),
                  title: Text('Kasun Perera'),
                  subtitle: Text('Verified seller · Member since 2024'),
                  trailing: Icon(Icons.verified, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  const _DetailImage({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 245,
      color: Color(vehicle.color.value),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.directions_car_filled_rounded,
            size: 170,
            color: Colors.black.withValues(alpha: 0.7),
          ),
          Positioned(
            bottom: 14,
            child: Row(
              children: List.generate(
                3,
                (index) => Container(
                  width: 52,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.directions_car, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthScore extends StatelessWidget {
  const _HealthScore({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: score / 100, strokeWidth: 7),
                Text(
                  '$score',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Excellent health score',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text('Based on completed visual and diagnostic checks.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
