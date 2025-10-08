// lib/providers/theme_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode? _themeMode = ThemeMode.light;
  bool _isDarkMode = false;

  ThemeMode? get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _themeMode = (_isDarkMode ? ThemeMode.dark : ThemeMode.light)!;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    _themeMode = (isDark ? ThemeMode.dark : ThemeMode.light)!;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);

    notifyListeners();
  }
}

class ThemeMode {
  static ThemeMode? get dark => null;

  static ThemeMode? get light => null;
}