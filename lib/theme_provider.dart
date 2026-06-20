import 'package:flutter/material.dart';

// Global theme state management
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

// Global instance
final themeProvider = ThemeProvider(); 