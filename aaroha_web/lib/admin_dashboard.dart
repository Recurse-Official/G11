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
    _tabController = TabController(length: 2, vsync: this); // Two tabs: Dashboard and Decrypt
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose the controller when the widget is removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        appBarTheme: const AppBarTheme(
          color: Colors.indigo, // Keep top bar consistent with the theme
          elevation: 4,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87), // Updated from bodyText2
          headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22), // Updated from headline6
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.lock), text: 'Decrypt'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            DataListScreen(), // Dashboard screen
            DecryptScreen(), // Decrypt screen
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
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
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

  // Build data table with borders and better colors
  Widget _buildDataTable() {
    return DataTable(
      columnSpacing: 16.0,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      columns: const [
        DataColumn(label: Text('Done')),
        DataColumn(label: Text('Message')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Phone')),
        DataColumn(label: Text('Urgency')),
        DataColumn(label: Text('Location')),
      ],
      rows: _dataList.asMap().map<int, DataRow>((index, item) {
        bool isChecked = _checkedItems[index] ?? false;

        Color urgencyColor = Colors.white;
        if (item['urgency_color'] == 'red') {
          urgencyColor = Colors.red.shade100;
        } else if (item['urgency_color'] == 'yellow') {
          urgencyColor = Colors.yellow.shade100;
        } else if (item['urgency_color'] == 'green') {
          urgencyColor = Colors.green.shade100;
        }

        return MapEntry(
          index,
          DataRow(
            cells: [
              DataCell(
                Checkbox(
                  value: isChecked,
                  onChanged: (bool? value) {
                    _toggleCheckbox(index, value);
                  },
                ),
              ),
              DataCell(Text(item['message']?.toString() ?? 'No message')),
              DataCell(Text(item['name']?.toString() ?? 'Unknown')),
              DataCell(Text(item['phone']?.toString() ?? 'N/A')),
              DataCell(
                Container(
                  color: urgencyColor, // Apply color to the cell
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    item['urgency_color']?.toString() ?? 'N/A',
                    style: TextStyle(
                      color: urgencyColor == Colors.red.shade100 ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              DataCell(Text(item['location']?.toString() ?? 'N/A')),
            ],
          ),
        );
      }).values.toList(),
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
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
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
            ),
          );
  }
}
