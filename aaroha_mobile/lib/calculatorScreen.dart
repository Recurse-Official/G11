import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

import 'home_screen.dart'; // Import the HomeScreen

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _output = '0';
  String _currentNumber = '';
  String _expression = '';
  String? _savedPin;
  final String emergencyPin = '9999'; // Define the emergency PIN

  @override
  void initState() {
    super.initState();
    _getSavedPin(); // Fetch saved PIN when the screen is initialized
  }

  // Function to get the saved PIN from SharedPreferences
  Future<void> _getSavedPin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Fetch the current PIN stored during sign-in
    _savedPin = prefs.getString('currentPin');
    print('Retrieved PIN: $_savedPin'); // Print the fetched PIN for debugging
  }

  // Function to handle the button presses in the calculator
  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "=") {
        // Evaluate the expression
        _evaluateExpression();
      } else if (buttonText == "C") {
        // Clear the calculator
        _clearCalculator();
      } else {
        // Add numbers or operators to the current expression
        _currentNumber += buttonText;
        _output = _currentNumber;
      }
    });
  }

  // Function to evaluate the current expression
  void _evaluateExpression() {
    try {
      // Parse and evaluate the expression
      Parser parser = Parser();
      Expression exp = parser.parse(_currentNumber);
      ContextModel cm = ContextModel();
      double evalResult = exp.evaluate(EvaluationType.REAL, cm);

      // Convert the result to an integer
      int evalResultInt = evalResult.toInt();

      // Compare the evaluated result with the saved PIN (as integer)
      if (_savedPin != null && evalResultInt.toString() == _savedPin) {
        // If the result matches the PIN, navigate to the HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else if (_currentNumber == emergencyPin) {
        // If the entered PIN matches the emergency PIN, send data to MongoDB
        _sendDataToMongoDB();
      } else {
        // Otherwise, display the result normally
        _output = evalResultInt.toString();
      }
    } catch (e) {
      // Handle any errors in the expression evaluation
      _output = 'Error';
    }
    _currentNumber = ''; // Clear the current expression
  }

  // Function to clear the calculator
  void _clearCalculator() {
    setState(() {
      _output = '0';
      _currentNumber = '';
    });
  }

  // Function to send emergency data to MongoDB
  Future<void> _sendDataToMongoDB() async {
    try {
      // Fetch user phone from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userPhone = prefs.getString('userPhone');

      // Default location data
      Map<String, dynamic> locationData = {
        'latitude': 'Unknown',
        'longitude': 'Unknown'
      };

      try {
        // Attempt to get current location
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.best);
            locationData = {
              'latitude': position.latitude,
              'longitude': position.longitude
            };
          }
        }
      } catch (e) {
        print('Location fetch error: $e');
        // Keep default location data if fetch fails
      }

      // Prepare default user data
      Map<String, dynamic> userData = {
        'name': userPhone ?? 'Unknown User',
        'phoneNumber': userPhone ?? 'Unknown Phone',
        'message': 'Emergency Alert Triggered via Calculator',
        'urgency_color': 'red',
        'location': locationData
      };

      // Replace with your actual Flask server endpoint
      final String apiUrl = '${Config.ipaddress}/emergency_pin';

      // Send data with emergency PIN
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'pin': emergencyPin, ...userData}),
      );

      if (response.statusCode == 200) {
        print('Emergency data sent successfully');
        setState(() {
          // _output = 'Emergency alert sent!';
        });
      } else {
         print('Failed to send data: ${response.body}');
        setState(() {
          // _output = 'Error sending emergency alert';
        });
      }
    } catch (e) {
      print('Error sending emergency data: $e');
      setState(() {
        // _output = 'Error sending alert';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Calculator output area
            Text(
              _output,
              style: TextStyle(color: Colors.white, fontSize: 48),
            ),
            Divider(color: Colors.white),
            // Basic Calculator UI (buttons)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton('7'),
                _buildButton('8'),
                _buildButton('9'),
                _buildButton('/'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton('4'),
                _buildButton('5'),
                _buildButton('6'),
                _buildButton('*'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton('1'),
                _buildButton('2'),
                _buildButton('3'),
                _buildButton('-'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton('C'),
                _buildButton('0'),
                _buildButton('='),
                _buildButton('+'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Function to create a calculator button
  Widget _buildButton(String buttonText) {
    return ElevatedButton(
      onPressed: () => _buttonPressed(buttonText),
      child: Text(
        buttonText,
        style: TextStyle(fontSize: 24),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(80, 80),
        foregroundColor: Colors.grey[850],
        backgroundColor: Colors.white,
      ),
    );
  }
}
