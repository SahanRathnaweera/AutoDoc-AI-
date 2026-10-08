import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/vehicle.dart';
import 'profile_page.dart';
import 'saved_vehicles_page.dart';
import '../widgets/vehicle_card.dart';

class MarketplaceHomePage extends StatefulWidget {
  const MarketplaceHomePage({super.key});

  @override
  State<MarketplaceHomePage> createState() => _MarketplaceHomePageState();
}

class _MarketplaceHomePageState extends State<MarketplaceHomePage> {
  String _query = '';
  String _healthFilter = 'Any health score';
  int _selectedIndex = 0;
  RangeValues _priceRange = const RangeValues(10000, 40000);

  List<Vehicle> get _filteredVehicles {
    return demoVehicles.where((vehicle) {
      final matchesQuery = vehicle.name.toLowerCase().contains(
        _query.toLowerCase(),
      );
      final matchesHealth =
          _healthFilter == 'Any health score' ||
          (_healthFilter == '90+' && vehicle.healthScore >= 90) ||
          (_healthFilter == '80+' && vehicle.healthScore >= 80);
      final matchesPrice =
          vehicle.price >= _priceRange.start &&
          vehicle.price <= _priceRange.end;
      return matchesQuery && matchesHealth && matchesPrice;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Home dashboard',
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.home_outlined),
        ),
        title: Text(
          ['Marketplace', 'Saved vehicles', 'Profile'][_selectedIndex],
        ),
        actions: _selectedIndex == 0
            ? [
                IconButton(
                  tooltip: 'Create listing',
                  onPressed: () => context.push('/marketplace/sell'),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ]
            : null,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/marketplace/sell'),
              icon: const Icon(Icons.sell_outlined),
              label: const Text('Sell vehicle'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    onSearchChanged: (value) => setState(() => _query = value),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FilterBar(
                    onFilterChanged: (filter) =>
                        setState(() => _healthFilter = filter),
                    onPriceChanged: (range) =>
                        setState(() => _priceRange = range),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  sliver: _filteredVehicles.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(
                            child: Text('No vehicles match these filters.'),
                          ),
                        )
                      : SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.crossAxisExtent > 700
                                ? 3
                                : constraints.crossAxisExtent > 430
                                ? 2
                                : 1;
                            return SliverGrid.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: columns == 1 ? 0.8 : 0.67,
                                  ),
                              itemCount: _filteredVehicles.length,
                              itemBuilder: (context, index) {
                                final vehicle = _filteredVehicles[index];
                                return VehicleCard(
                                  vehicle: vehicle,
                                  onTap: () => context.push(
                                    '/marketplace/vehicle/${vehicle.id}',
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          const SavedVehiclesPage(),
          const ProfilePage(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSearchChanged});

  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verified vehicles',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            'Find your next car with an AI-backed health score.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search make or model',
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.tune),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.onFilterChanged,
    required this.onPriceChanged,
  });

  final ValueChanged<String> onFilterChanged;
  final ValueChanged<RangeValues> onPriceChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(
            label: const Text('Any health score'),
            selected: true,
            onSelected: (_) => onFilterChanged('Any health score'),
          ),
          FilterChip(
            label: const Text('90+ score'),
            onSelected: (_) => onFilterChanged('90+'),
          ),
          FilterChip(
            label: const Text('80+ score'),
            onSelected: (_) => onFilterChanged('80+'),
          ),
          ActionChip(
            avatar: const Icon(Icons.price_change_outlined, size: 17),
            label: const Text('Price'),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (context) => _PriceSheet(onChanged: onPriceChanged),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceSheet extends StatefulWidget {
  const _PriceSheet({required this.onChanged});

  final ValueChanged<RangeValues> onChanged;

  @override
  State<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends State<_PriceSheet> {
  RangeValues range = const RangeValues(10000, 40000);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Price range', style: Theme.of(context).textTheme.titleLarge),
          RangeSlider(
            values: range,
            min: 10000,
            max: 40000,
            divisions: 6,
            labels: RangeLabels(
              '\$${range.start.round()}',
              '\$${range.end.round()}',
            ),
            onChanged: (value) => setState(() => range = value),
          ),
          FilledButton(
            onPressed: () {
              widget.onChanged(range);
              Navigator.pop(context);
            },
            child: const Text('Apply price filter'),
          ),
        ],
      ),
    );
  }
}
