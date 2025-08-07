import 'package:flutter/material.dart';
import 'screens/memory_game_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        scaffoldBackgroundColor: Colors.green.shade100, // Light green background
      ),
      home: const MemoryGameScreen(),
    );
  }
}
