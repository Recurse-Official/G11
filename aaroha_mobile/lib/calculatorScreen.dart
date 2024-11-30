import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart'; // Import the HomeScreen
import 'package:math_expressions/math_expressions.dart'; // Add math_expressions package for evaluating calculations

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _output = '0';
  String _currentNumber = '';
  String _expression = '';
  String? _savedPin;

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
