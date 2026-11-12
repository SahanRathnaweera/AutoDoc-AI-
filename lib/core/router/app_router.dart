import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ocr_screen.dart';
import '../../features/inspection/presentation/pages/dashboard_page.dart';
import '../../features/inspection/presentation/pages/inspection_pages.dart'
    hide DashboardPage;

import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';

import '../../features/inspection/presentation/pages/settings_page.dart';
import '../../features/marketplace/presentation/pages/damage_overlay_page.dart';
import '../../features/marketplace/presentation/pages/marketplace_home_page.dart';
import '../../features/marketplace/presentation/pages/profile_page.dart';
import '../../features/marketplace/presentation/pages/seller_listing_page.dart';
import '../../features/marketplace/presentation/pages/vehicle_detail_page.dart';
import '../../features/inspection/presentation/pages/engine_sound_recording_page.dart';

GoRouter createAppRouter({
  required bool authAvailable,
  required bool Function() isSignedIn,
  required Listenable authRefresh,
}) => GoRouter(
  initialLocation: '/',
  refreshListenable: authRefresh,
  redirect: (context, state) {
    final path = state.uri.path;
    if (path == '/' || path.startsWith('/auth') || isSignedIn()) return null;
    return '/auth';
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => SplashPage(isSignedIn: isSignedIn),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => AuthPage(
        authAvailable: authAvailable,
        initialEmail: state.extra is String ? state.extra as String : '',
      ),
      routes: [
        GoRoute(
          path: 'signup',
          builder: (context, state) =>
              SignUpPage(authAvailable: authAvailable),
        ),
      ],
    ),
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
        GoRoute(
          path: 'engine-sound',
          builder: (context, state) => const EngineSoundRecordingPage(),
        ),
        GoRoute(path: 'ocr', builder: (context, state) => const OcrScreen()),
        GoRoute(
          path: 'report',
          builder: (context, state) => const InspectionReportPage(),
        ),
        GoRoute(
          path: 'damage',
          builder: (context, state) {
            // 360 scan photos `extra` එකෙන් එනවා
            final photos = state.extra is List<XFile>
                ? state.extra! as List<XFile>
                : const <XFile>[];
            return DamageOverlayPage(photos: photos);
          },
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
    GoRoute(path: '/ocr', builder: (context, state) => const OcrScreen()),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);