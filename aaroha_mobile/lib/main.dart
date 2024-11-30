// main.dart
import 'package:flutter/material.dart';
import 'calculatorscreen.dart';  // Import the CalculatorScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: CalculatorScreen(),  // Set CalculatorScreen as the home screen
    );
  }
}
