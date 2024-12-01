// main.dart
import 'package:aaroha_mobile/landingpage.dart';
import 'package:aaroha_mobile/signin_screen.dart';
import 'package:aaroha_mobile/signup_screen.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calculatorscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        '/calculator': (context) => CalculatorScreen(),
      },
    );
  }
}

