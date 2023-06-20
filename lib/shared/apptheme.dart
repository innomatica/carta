import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme(ColorScheme? lightColorScheme) {
    // debugPrint('lightColorScheme: $lightColorScheme');
    ColorScheme scheme = lightColorScheme ??
        ColorScheme.fromSeed(seedColor: Colors.deepOrangeAccent);
    return ThemeData(colorScheme: scheme);
  }

  static ThemeData darkTheme(ColorScheme? darkColorScheme) {
    // debugPrint('darkColorScheme: $darkColorScheme');
    ColorScheme scheme = darkColorScheme ??
        ColorScheme.fromSeed(seedColor: Colors.deepOrangeAccent);
    return ThemeData(colorScheme: scheme);
  }
}
