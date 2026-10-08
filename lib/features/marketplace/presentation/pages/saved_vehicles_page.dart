import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/vehicle.dart';
import '../widgets/vehicle_card.dart';

class SavedVehiclesPage extends StatelessWidget {
  const SavedVehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Saved vehicles',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 420,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: 1,
            itemBuilder: (context, index) {
              final vehicle = demoVehicles.first;
              return VehicleCard(
                vehicle: vehicle,
                onTap: () => context.push('/marketplace/vehicle/${vehicle.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
