import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'DecryptScreen.dart'; // Assuming DecryptScreen is defined in a separate file

void main() {
  runApp(const AdminDashboard());
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          color: Color(0xFF1E1E1E),
          elevation: 4,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.white, 
            fontSize: 22
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E1E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dataTableTheme: DataTableThemeData(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          dataTextStyle: const TextStyle(color: Colors.white70),
          headingTextStyle: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: const Color(0xFF1E1E1E),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.lock), text: 'Decrypt'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.deepPurpleAccent,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            DataListScreen(),
            DecryptScreen(),
          ],
        ),
      ),
    );
  }
}

class DataListScreen extends StatefulWidget {
  const DataListScreen({super.key});

  @override
  _DataListScreenState createState() => _DataListScreenState();
}

class _DataListScreenState extends State<DataListScreen> {
  List<dynamic> _dataList = [];
  bool _isLoading = true;

  // Track the checkboxes
  Map<int, bool> _checkedItems = {};

  // Fetch data from backend
  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:7080/messages'));

      if (response.statusCode == 200) {
        setState(() {
          _dataList = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error fetching data: $e');
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(
          'Error', 
          style: TextStyle(color: Colors.red.shade300)
        ),
        content: Text(
          message, 
          style: const TextStyle(color: Colors.white70)
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay', style: TextStyle(color: Colors.deepPurpleAccent)),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  // Toggle checkbox
  void _toggleCheckbox(int index, bool? value) {
    setState(() {
      _checkedItems[index] = value!;
    });
  }

  // Build data table with dark theme
  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DataTable(
        columnSpacing: 16.0,
        columns: const [
          DataColumn(label: Text('Done', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('Message', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('Phone', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('Urgency', style: TextStyle(color: Colors.white))),
          DataColumn(label: Text('Location', style: TextStyle(color: Colors.white))),
        ],
        rows: _dataList.asMap().map<int, DataRow>((index, item) {
          bool isChecked = _checkedItems[index] ?? false;

          Color urgencyColor = const Color(0xFF2C2C2C);
          if (item['urgency_color'] == 'red') {
            urgencyColor = Colors.red.shade900;
          } else if (item['urgency_color'] == 'yellow') {
            urgencyColor = Colors.amber.shade900;
          } else if (item['urgency_color'] == 'green') {
            urgencyColor = Colors.green.shade900;
          } else if (item['urgency_color'] == 'blue') {
            urgencyColor = Colors.blue.shade900;
          }


          return MapEntry(
            index,
            DataRow(
              color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                return index.isEven ? const Color(0xFF252525) : null;
              }),

              cells: [
                DataCell(
                  Checkbox(
                    value: isChecked,
                    onChanged: (bool? value) {
                      _toggleCheckbox(index, value);
                    },
                    activeColor: Colors.deepPurpleAccent,
                  ),
                ),
                DataCell(Text(
                  item['message']?.toString() ?? 'No message',
                  style: const TextStyle(color: Colors.white70),
                )),
                DataCell(Text(
                  item['name']?.toString() ?? 'Unknown',
                  style: const TextStyle(color: Colors.white70),
                )),
                DataCell(Text(
                  item['phone']?.toString() ?? 'N/A',
                  style: const TextStyle(color: Colors.white70),
                )),
                DataCell(
                  Container(
                    color: urgencyColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      item['urgency_color']?.toString() ?? 'N/A',
                      style: TextStyle(
                        color: urgencyColor == Colors.red.shade900 ||
                               urgencyColor == Colors.blue.shade900 
                            ? Colors.white 
                            : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                DataCell(Text(
                  item['location']?.toString() ?? 'N/A',
                  style: const TextStyle(color: Colors.white70),
                )),
              ],
            ),
          );
        }).values.toList(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
            ),
          )
        : Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildDataTable(),
                  ),
                ),
              ),
            ),
  );
}
}
