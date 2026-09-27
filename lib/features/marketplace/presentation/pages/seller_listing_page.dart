import 'package:flutter/material.dart';

class SellerListingPage extends StatefulWidget {
  const SellerListingPage({super.key});

  @override
  State<SellerListingPage> createState() => _SellerListingPageState();
}

class _SellerListingPageState extends State<SellerListingPage> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _modelController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 1 && !_formKey.currentState!.validate()) return;
    if (_step < 3) {
      setState(() => _step++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing saved for review.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Review scan',
      'Vehicle details',
      'Set your price',
      'Preview listing',
    ];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('List your vehicle'),
        leading: _step == 0
            ? null
            : IconButton(
                onPressed: () => setState(() => _step--),
                icon: const Icon(Icons.arrow_back),
              ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _next,
          child: Text(_step == 3 ? 'Publish listing' : 'Continue'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          children: [
            LinearProgressIndicator(value: (_step + 1) / titles.length),
            const SizedBox(height: 24),
            Text(
              'Step ${_step + 1} of ${titles.length}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              titles[_step],
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            if (_step == 0) const _ScanReview(),
            if (_step == 1) _VehicleDetails(modelController: _modelController),
            if (_step == 2) _PriceStep(controller: _priceController),
            if (_step == 3)
              _ListingPreview(
                model: _modelController.text,
                price: _priceController.text,
              ),
          ],
        ),
      ),
    );
  }
}

class _ScanReview extends StatelessWidget {
  const _ScanReview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xffdbeafe),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            size: 110,
            color: Color(0xff263746),
          ),
        ),
        const SizedBox(height: 18),
        const _CheckRow(label: 'Exterior scan complete'),
        const _CheckRow(label: 'Engine audio reviewed'),
        const _CheckRow(label: 'Damage coordinates mapped'),
        const SizedBox(height: 12),
        Text(
          'Your verified scan will be attached to the listing.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _VehicleDetails extends StatelessWidget {
  const _VehicleDetails({required this.modelController});

  final TextEditingController modelController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: modelController,
          decoration: const InputDecoration(
            labelText: 'Make and model',
            prefixIcon: Icon(Icons.directions_car_outlined),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter the vehicle model' : null,
        ),
        const SizedBox(height: 14),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Year',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Registration number',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
      ],
    );
  }
}

class _PriceStep extends StatelessWidget {
  const _PriceStep({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Asking price',
            prefixText: '\$ ',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
          keyboardType: TextInputType.number,
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter an asking price' : null,
        ),
        const SizedBox(height: 18),
        const Text('Recommended range'),
        const SizedBox(height: 8),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.insights_outlined),
          title: Text('\$24,000 - \$27,000'),
          subtitle: Text('Based on similar verified vehicles'),
        ),
      ],
    );
  }
}

class _ListingPreview extends StatelessWidget {
  const _ListingPreview({required this.model, required this.price});

  final String model;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ScanReview(),
            const Divider(height: 28),
            Text(
              model.isEmpty ? 'Vehicle model' : model,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              price.isEmpty ? 'Price not set' : '\$$price',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const Icon(Icons.check_circle, color: Colors.green),
      title: Text(label),
    );
  }
}
