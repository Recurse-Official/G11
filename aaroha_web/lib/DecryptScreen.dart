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
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          color: Colors.indigo[800],
          elevation: 4,
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Roboto',
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
  bool _isUploading = false; // Added to manage upload status

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

void _showSuccessDialog(Map<String, dynamic> data) {
  final location = data['location'] ?? {};
  final city = location is Map ? location['city'] ?? 'N/A' : 'N/A';
  final region = location is Map ? location['region'] ?? 'N/A' : 'N/A';
  final country = location is Map ? location['country'] ?? 'N/A' : 'N/A';

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Decryption Successful', style: TextStyle(color: Colors.green)),
      // content: Text(
      //   'Message: ${data['message'] ?? 'N/A'}\n'
      //   'Name: ${data['name'] ?? 'N/A'}\n'
      //   'Phone: ${data['phone'] ?? 'N/A'}\n'
      //   'Urgency: ${data['urgency_color'] ?? 'N/A'}\n'
      //   'Location: $city, $region, $country',
      // ),
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
      appBar: AppBar(
        title: const Text('Decryption Screen', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
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
                  border: Border.all(color: Colors.indigo[200]!, width: 2),
                  borderRadius: BorderRadius.circular(8),
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
                                size: 80, color: Colors.indigo[300]),
                            const SizedBox(height: 10),
                            Text(
                              'Select Image for Decryption',
                              style: TextStyle(
                                color: Colors.indigo[600],
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
                  backgroundColor: Colors.indigo,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
                    backgroundColor: Colors.green[700],
                    padding:
                        const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
