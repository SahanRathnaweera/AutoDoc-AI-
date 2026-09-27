import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/price_test_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/price-test'),
            child: const Text('Open Price API Test'),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/price-test',
      builder: (context, state) => const PriceTestScreen(),
    ),
  ],
);
