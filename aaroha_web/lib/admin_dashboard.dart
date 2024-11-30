import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AdminDashboard());
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          color: Colors.indigo[800],
          elevation: 4,
        ),
      ),
      home: const DataListScreen(),
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
          )
        ],
      ),
    );
  }
Widget _buildDataTable() {
  return DataTable(
    columns: const [
      DataColumn(label: Text('Message')),
      DataColumn(label: Text('Name')),
      DataColumn(label: Text('Phone')),
      DataColumn(label: Text('Urgency')),
      DataColumn(label: Text('Location')),
    ],
    rows: _dataList.map<DataRow>((item) {
      
      return DataRow(cells: [
        DataCell(Text(item['message']?.toString() ?? 'No message')),
        DataCell(Text(item['name']?.toString() ?? 'Unknown')),
        DataCell(Text(item['phone']?.toString() ?? 'N/A')),
        DataCell(Text(item['urgency_color']?.toString() ?? 'N/A')),
        DataCell(Text(item['location']?.toString() ?? 'N/A')),
      ]);
    }).toList(),
  );
}


  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildDataTable(),
              ),
            ),
    );
  }
}
