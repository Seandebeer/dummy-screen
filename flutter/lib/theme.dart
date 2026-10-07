import 'package:flutter/material.dart';

const kBg = Color(0xFF000000);
const kSurface = Color(0xFF1C1C1E);
const kLine = Color(0xFF2C2C2E);
const kMuted = Color(0xFF8E8E93);
const kAccent = Color(0xFF318DF6);
const kSignal = Color(0xFF30D158);
const kAlert = Color(0xFFFF453A);

const kVfxColors = <String, Color>{
  'green': Color(0xFF00B140),
  'blue': Color(0xFF0047BB),
  'white': Color(0xFFFFFFFF),
  'grey': Color(0xFF8E8E93),
  'red': Color(0xFFFF3B30),
};

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    surface: kSurface,
    primary: kAccent,
    onPrimary: Colors.white,
    secondary: kSignal,
    error: kAlert,
    onSurface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    dividerColor: kLine,
    cardTheme: const CardThemeData(
      color: kSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: kLine),
      ),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: kSurface),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kLine,
      labelStyle: const TextStyle(color: kMuted),
      hintStyle: const TextStyle(color: kMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
