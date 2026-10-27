import 'package:flutter/material.dart';

import '../../domain/entities/vehicle.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({required this.vehicle, required this.onTap, super.key});

  final Vehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = vehicle.healthScore >= 90
        ? Colors.green
        : theme.colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VehicleThumbnail(vehicle: vehicle),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${vehicle.year} ${vehicle.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(Icons.verified, color: scoreColor, size: 18),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${vehicle.price.toStringAsFixed(0)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Icon(
                        Icons.health_and_safety,
                        color: scoreColor,
                        size: 17,
                      ),
                      Text('${vehicle.healthScore} health score'),
                      Icon(
                        Icons.location_on_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      Text(
                        vehicle.location,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
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

class _VehicleThumbnail extends StatelessWidget {
  const _VehicleThumbnail({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.35,
      child: Container(
        color: Color(vehicle.color.value),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.directions_car_filled_rounded,
              size: 92,
              color: Colors.black.withValues(alpha: 0.68),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.auto_awesome, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
