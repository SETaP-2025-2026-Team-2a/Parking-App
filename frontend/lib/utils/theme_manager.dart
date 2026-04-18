import 'package:flutter/material.dart';

/// Theme Manager for managing dark mode state across the app
class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  bool _isDarkMode = false;
  VoidCallback? _onThemeChanged;

  bool get isDarkMode => _isDarkMode;

  void setOnThemeChanged(VoidCallback callback) {
    _onThemeChanged = callback;
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _onThemeChanged?.call();
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    _onThemeChanged?.call();
    notifyListeners();
  }

  /// Light theme configuration
  ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1),
    );
  }

  /// Dark theme configuration
  ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E), foregroundColor: Colors.white, elevation: 1),
    );
  }
}
