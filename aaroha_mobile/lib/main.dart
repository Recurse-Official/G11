// main.dart
import 'package:aaroha_mobile/landingpage.dart';
import 'package:aaroha_mobile/signinscreen.dart';
import 'package:aaroha_mobile/signupscree.dart';
import 'package:flutter/material.dart';
import 'calculatorscreen.dart';  // Import the CalculatorScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LandingPage(),
        '/signin': (context) => SignInScreen(),
        '/signup': (context) => SignUpScreen(),
        '/calculator': (context) => CalculatorScreen(), // Your Calculator screen
      },
    );
  }
}

