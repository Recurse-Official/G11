import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:cross_file/cross_file.dart';

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

  void _uploadImage() {
    if (_imageFile == null) {
      _showErrorDialog('Please select an image first');
      return;
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Confirmation', style: TextStyle(color: Colors.indigo)),
        content: const Text('Image is ready for decryption. Proceed with upload?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Confirm Upload'),
            onPressed: () {
              _performImageUpload();
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          ),
        ],
      ),
    );
  }

  void _performImageUpload() {
    if (_imageFile == null) return;

    // TODO: Implement secure upload logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Decrypted.'),
        backgroundColor: Colors.green,
      ),
    );
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
                              size: 80, 
                              color: Colors.indigo[300]
                            ),
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
                label: const Text('Upload image for decryption', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: _pickImageFromGallery,
              ),
              
              const SizedBox(height: 15),
              
              // Upload Button
              if (_imageBytes != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload for Analysis', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: _uploadImage,
                ),
            ],
          ),
        ),
      ),
    );
  }
}