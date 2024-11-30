import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _output = '0';
  String _currentNumber = '';
  double _firstOperand = 0;
  String _operator = '';
  String _expression = '';

  void _handleNumberInput(String value) {
    setState(() {
      if (_currentNumber.length < 10) {
        _currentNumber += value;
        _output = _currentNumber;
        _updateExpression();
      }
    });
  }

  void _handleOperator(String op) {
    setState(() {
      if (_currentNumber.isNotEmpty) {
        _firstOperand = double.parse(_currentNumber);
        _operator = op;
        _currentNumber = '';
        _updateExpression();
      }
    });
  }

  void _calculateResult() {
    setState(() {
      if (_currentNumber.isNotEmpty && _operator.isNotEmpty) {
        double secondOperand = double.parse(_currentNumber);
        double result;
        switch (_operator) {
          case '+':
            result = _firstOperand + secondOperand;
            break;
          case '-':
            result = _firstOperand - secondOperand;
            break;
          case '×':
            result = _firstOperand * secondOperand;
            break;
          case '÷':
            result = _firstOperand / secondOperand;
            break;
          default:
            return;
        }
        _output = result.toString();
        _expression = '$_firstOperand $_operator $secondOperand = $_output';
        _currentNumber = _output;
        _operator = '';
      }
    });
  }

  void _updateExpression() {
    _expression = _firstOperand != 0 
      ? '$_firstOperand $_operator ${_currentNumber.isEmpty ? '' : _currentNumber}' 
      : _currentNumber;
  }

  void _clearCalculator() {
    setState(() {
      _output = '0';
      _currentNumber = '';
      _firstOperand = 0;
      _operator = '';
      _expression = '';
    });
  }

  Widget _buildButton(String text, {bool isOperator = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(5),
        child: ElevatedButton(
          onPressed: () {
            switch (text) {
              case 'C':
                _clearCalculator();
                break;
              case '=':
                _calculateResult();
                break;
              case '+':
              case '-':
              case '×':
              case '÷':
                _handleOperator(text);
                break;
              default:
                _handleNumberInput(text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isOperator ? Colors.deepOrange : Colors.grey[800],
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _expression,
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      _output,
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildButton('7'),
                      _buildButton('8'),
                      _buildButton('9'),
                      _buildButton('÷', isOperator: true),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('4'),
                      _buildButton('5'),
                      _buildButton('6'),
                      _buildButton('×', isOperator: true),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('1'),
                      _buildButton('2'),
                      _buildButton('3'),
                      _buildButton('-', isOperator: true),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('C', isOperator: true),
                      _buildButton('0'),
                      _buildButton('.'),
                      _buildButton('+', isOperator: true),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildButton('=', isOperator: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}