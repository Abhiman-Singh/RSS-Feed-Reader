// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // To hold the current theme mode
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      // Toggle between light and dark theme
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RSS Feed Reader',
      theme: ThemeData.light(), // Light theme
      darkTheme: ThemeData.dark(), // Dark theme
      themeMode: _themeMode, // Set the current theme mode
      home: HomeScreen(onToggleTheme: _toggleTheme), // Pass the toggle function
    );
  }
}
