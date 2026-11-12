
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
 

class AppColors {
  static const ink = Color(0xFF0B1F33);
  static const paper = Color(0xFFEEF1F4);
  static const surface = Color(0xFFFFFFFF);
  static const steel = Color(0xFF6B7C8C);
  static const line = Color(0xFFD5DCE3);
  static const signal = Color(0xFF1F5BFF);
  static const pass = Color(0xFF1E9E6A);
  static const warn = Color(0xFFE08A00);
  static const fail = Color(0xFFD8392B);
}
 

class AppPalette {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.text,
    required this.muted,
    required this.line,
    required this.strong,
    required this.onStrong,
    required this.accent,
  });
 
  final Color bg; 
  final Color surface; 
  final Color text; 
  final Color muted; 
  final Color line; 
  final Color strong;
  final Color onStrong;
  final Color accent;
 
  static const light = AppPalette(
    bg: AppColors.paper,
    surface: AppColors.surface,
    text: AppColors.ink,
    muted: AppColors.steel,
    line: AppColors.line,
    strong: AppColors.ink,
    onStrong: Colors.white,
    accent: AppColors.signal,
  );
 
  static const dark = AppPalette(
    bg: Color(0xFF071722),
    surface: Color(0xFF102936),
    text: Color(0xFFEAF2F7),
    muted: Color(0xFF8FA3B0),
    line: Color(0xFF24414F),
    strong: Color(0xFF1688F2),
    onStrong: Colors.white,
    accent: Color(0xFF3B9CFF),
  );
 
  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
 
class AppTheme {
  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);
 
  static ThemeData _build(AppPalette p, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
      scaffoldBackgroundColor: p.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.signal,
        brightness: brightness,
        surface: p.surface,
      ),
    );
 
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: p.text,
        displayColor: p.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.strong,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? p.onStrong : p.muted,
          ),
        ),
      ),
    );
  }
}
 

