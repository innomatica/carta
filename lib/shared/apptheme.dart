import 'package:flutter/material.dart';

import './settings.dart';

class AppTheme {
  static ThemeData lightTheme(ColorScheme? colorScheme) {
    ColorScheme scheme = colorScheme ??
        ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: seedColorLight,
        );
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }

  static ThemeData darkTheme(ColorScheme? colorScheme) {
    ColorScheme scheme = colorScheme ??
        ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: seedColorDark,
        );
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }
}
