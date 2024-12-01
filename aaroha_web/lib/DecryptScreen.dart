import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const DecryptScreen());
}

class DecryptScreen extends StatelessWidget {
  const DecryptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Decryption Screen',
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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const ImageUploadPage(),
    );
  }
}

class ImageUploadPage extends StatefulWidget {
  const ImageUploadPage({super.key});

  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  XFile? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        setState(() {
          _imageFile = pickedFile;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorDialog('Failed to select image');
    }
  }

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
          )
        ],
      ),
    );
  }

void _showSuccessDialog(Map<String, dynamic> responseData) {
    // Add debugging print statements
    print('Full Response Data: $responseData');
    print('Data Key: ${responseData['data']}');

    // Safely access the nested data
    final data = responseData['data'] ?? {};
    
    // Extract name and urgency color with explicit type checking
    final name = data['name'] is String ? data['name'] : 'N/A';
    final urgencyColor = data['urgency_color'] is String ? data['urgency_color'] : 'N/A';

    print('Name: $name');
    print('Urgency Color: $urgencyColor');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(
          'Decryption Successful', 
          style: TextStyle(color: Colors.green.shade300)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: $name',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Urgency Color: $urgencyColor',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay', style: TextStyle(color: Colors.deepPurpleAccent)),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      _showErrorDialog('Please select an image first');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:7080/extract'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          await _imageFile!.readAsBytes(),
          filename: _imageFile!.name,
        ),
      );

      // Sending the request
      final response = await request.send();

      // Logging raw response details for debugging
      print('Response Status Code: ${response.statusCode}');
      final responseBody = await response.stream.bytesToString();
      print('Raw Response Body: $responseBody');

      // Handling the response
      if (response.statusCode == 201) {
        try {
          final responseData = jsonDecode(responseBody);
          print('Parsed Response Data: $responseData');

          setState(() {
            _isUploading = false;
          });
          _showSuccessDialog(responseData);
        } catch (e) {
          print('Response Parsing Error: $e');
          setState(() {
            _isUploading = false;
          });
          _showErrorDialog('Failed to parse the server response.');
        }
      } else {
        try {
          final errorData = jsonDecode(responseBody);
          print('Error Response Data: $errorData');

          setState(() {
            _isUploading = false;
          });
          _showErrorDialog(errorData['error'] ?? 'An unknown error occurred.');
        } catch (e) {
          print('Error Response Parsing Failed: $e');
          setState(() {
            _isUploading = false;
          });
          _showErrorDialog('Server returned an unexpected response.');
        }
      }
    } catch (e) {
      print('Request Sending Error: $e');
      setState(() {
        _isUploading = false;
      });
      _showErrorDialog('Failed to connect to the backend. Please check your network or server.');
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Center(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(20),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Image Preview Area
            Container(
              height: 300,
              width: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple.shade700, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF252525),
              ),
              child: _imageBytes != null
                  ? Image.memory(
                      _imageBytes!,
                      fit: BoxFit.contain,
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_search,
                              size: 80, color: Colors.deepPurple.shade300),
                          const SizedBox(height: 10),
                          Text(
                            'Select Image for Decryption',
                            style: TextStyle(
                              color: Colors.deepPurple.shade200,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // Gallery Selection Button
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Upload image for decryption',
                  style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: _pickImageFromGallery,
            ),

            const SizedBox(height: 15),

            // Upload Button
            if (_imageBytes != null)
              ElevatedButton.icon(
                icon: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.upload_file),
                label: const Text('Upload for Analysis',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: _isUploading ? null : _uploadImage,
              ),
          ],
        ),
      ),
    ),
  );
}

}
