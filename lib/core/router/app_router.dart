import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/inspection/presentation/pages/inspection_pages.dart';
import '../../features/inspection/presentation/pages/settings_page.dart';
import '../../features/marketplace/presentation/pages/damage_overlay_page.dart';
import '../../features/marketplace/presentation/pages/marketplace_home_page.dart';
import '../../features/marketplace/presentation/pages/profile_page.dart';
import '../../features/marketplace/presentation/pages/seller_listing_page.dart';
import '../../features/marketplace/presentation/pages/vehicle_detail_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
      routes: [
        GoRoute(
          path: 'camera',
          builder: (context, state) => const GuidedCameraPage(),
        ),
        GoRoute(
          path: 'diagnostics',
          builder: (context, state) => const DiagnosticPage(),
        ),
        GoRoute(path: 'ocr', builder: (context, state) => const OcrPage()),
        GoRoute(
          path: 'report',
          builder: (context, state) => const InspectionReportPage(),
        ),
        GoRoute(
          path: 'damage',
          builder: (context, state) => const DamageOverlayPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/marketplace',
      builder: (context, state) => const MarketplaceHomePage(),
      routes: [
        GoRoute(
          path: 'vehicle/:vehicleId',
          builder: (context, state) =>
              VehicleDetailPage(vehicleId: state.pathParameters['vehicleId']!),
          routes: [
            GoRoute(
              path: 'damage',
              builder: (context, state) => const DamageOverlayPage(),
            ),
          ],
        ),
        GoRoute(
          path: 'sell',
          builder: (context, state) => const SellerListingPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const ProfilePage(),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
