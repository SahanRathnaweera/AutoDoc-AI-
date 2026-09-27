import 'package:flutter/material.dart';
import '../../services/price_api_service.dart';

class PriceTestScreen extends StatefulWidget {
  const PriceTestScreen({super.key});

  @override
  State<PriceTestScreen> createState() => _PriceTestScreenState();
}

class _PriceTestScreenState extends State<PriceTestScreen> {
  bool isLoading = false;
  String resultText = 'Choose a vehicle to test the price API.';

  Future<void> _runPrediction({
    required bool isBike,
  }) async {
    setState(() {
      isLoading = true;
      resultText = 'Connecting to API...';
    });

    try {
      final result = isBike
          ? await PriceApiService.predictBikePrice()
          : await PriceApiService.predictCarPrice();

      if (!mounted) return;

      setState(() {
        resultText =
            'Vehicle: ${result['vehicle_type']}\n'
            'Predicted price: ${result['predicted_price']}\n\n'
            '${result['voice_summary']}';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        resultText = 'API error:\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price API Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () => _runPrediction(isBike: false),
                child: const Text('Test Car Price API'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () => _runPrediction(isBike: true),
                child: const Text('Test Bike Price API'),
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                resultText,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}