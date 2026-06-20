// lib/main.dart - FINAL SIMPLIFIED VERSION

import 'package:flutter/material.dart';
import 'package:pageflow/screens/home_screen.dart';
import 'package:pageflow/theme_provider.dart';

// No platform-specific webview imports are needed here anymore.

void main() {
  // Manual platform setup is no longer needed for modern webview_flutter.
  // We can remove the async, WidgetsFlutterBinding, and platform checks.
  runApp(const PageflowApp());
}

// The PageflowApp class and everything below remains UNCHANGED.
// I am including it here for absolute certainty.

class PageflowApp extends StatefulWidget {
  const PageflowApp({super.key});

  @override
  State<PageflowApp> createState() => _PageflowAppState();
}

class _PageflowAppState extends State<PageflowApp> {
  @override
  void initState() {
    super.initState();
    themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PageFlow',
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: HomeScreen(
        isDarkMode: themeProvider.isDarkMode,
        onThemeToggle: themeProvider.toggleTheme,
      ),
    );
  }

  final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
  );

  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
