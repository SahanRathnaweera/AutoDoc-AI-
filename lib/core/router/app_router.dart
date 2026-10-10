import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../ocr_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('AutoDoc AI Base Setup Ready')),
      ),
    ),
    GoRoute(
      path: '/ocr',
      builder: (context, state) => const OcrScreen(),
    ),
  ],
);