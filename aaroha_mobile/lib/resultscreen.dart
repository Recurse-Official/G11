import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io' show File, Directory, Platform;
import 'config.dart';

class ResultScreen extends StatefulWidget {
  final String message;
  final Color? selectedColor;
  final String? selectedImage;

  const ResultScreen(
      {Key? key, required this.message, this.selectedColor, this.selectedImage})
      : super(key: key);

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // Location and user data variables
  Map<String, dynamic>? locationData;
  Map<String, String> userData = {
    'name': 'Error: Unable to fetch name',
    'phoneNumber': 'Error: Unable to fetch phone number'
  };

  // State management variables
  bool _isLoading = true;
  String? _uploadResult;
  bool _isUploading = false;
  String? _downloadedImagePath;

  // Helper method to convert color to readable string
  String _getColorName(Color? color) {
    if (color == const Color(0xFFFF6B6B)) return 'red';
    if (color == const Color(0xFFFCA311)) return 'yellow';
    if (color == const Color(0xFF4ECDC4)) return 'green';
    return 'unknown';
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
    _fetchUserData();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userPhone = prefs.getString('userPhone');

      if (userPhone != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userPhone)
            .get();

        if (userDoc.exists) {
          setState(() {
            userData = {
              'name': userDoc['name'] ?? 'Name not found',
              'phoneNumber': userPhone
            };
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            userData = {'name': 'User not found', 'phoneNumber': userPhone};
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          userData = {
            'name': 'No user logged in',
            'phoneNumber': 'No user logged in'
          };
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
        userData = {
          'name': 'Error fetching name',
          'phoneNumber': 'Error fetching phone number'
        };
      });
    }
  }

  Future<void> _downloadImage() async {
    if (_downloadedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No image available to download'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Get the source file
      File sourceFile = File(_downloadedImagePath!);

      // Determine download directory based on platform
      Directory? downloadDirectory;
      if (Platform.isAndroid) {
        downloadDirectory = Directory('/storage/emulated/0/Download');
        if (!await downloadDirectory.exists()) {
          downloadDirectory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadDirectory = await getApplicationDocumentsDirectory();
      } else {
        downloadDirectory = await getDownloadsDirectory();
      }

      if (downloadDirectory == null) {
        throw Exception('Could not find download directory');
      }

      // Create a unique filename
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'downloaded_image_$timestamp.png';
      File destinationFile = File('${downloadDirectory.path}/$fileName');

      // Copy the file
      await sourceFile.copy(destinationFile.path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image downloaded to: ${destinationFile.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Get user location
  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationData = {
          'latitude': 'Location services disabled',
          'longitude': 'Location services disabled'
        };
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          locationData = {
            'latitude': 'Location permissions denied',
            'longitude': 'Location permissions denied'
          };
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationData = {
          'latitude': 'Location permissions permanently denied',
          'longitude': 'Location permissions permanently denied'
        };
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);

      setState(() {
        locationData = {
          'latitude': position.latitude,
          'longitude': position.longitude
        };
      });
    } catch (e) {
      setState(() {
        locationData = {
          'latitude': 'Error fetching location',
          'longitude': 'Error fetching location'
        };
      });
    }
  }

  // Helper method to create a temporary JSON file with robust error handling
  Future<File> _createJsonFile(Map<String, dynamic> jsonData) async {
    try {
      // Try to get platform-specific temporary directory
      Directory? tempDir;

      if (Platform.isAndroid || Platform.isIOS) {
        tempDir = await getTemporaryDirectory();
      } else {
        tempDir = Directory.systemTemp;
      }

      if (tempDir == null) {
        throw Exception('Could not find temporary directory');
      }

      final file = File('${tempDir.path}/data.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonData));
      return file;
    } catch (e) {
      print('Error creating JSON file: $e');

      // Fallback method
      try {
        final fallbackFile = File('/tmp/data.json');
        await fallbackFile
            .writeAsString(const JsonEncoder.withIndent('  ').convert(jsonData));
        return fallbackFile;
      } catch (fallbackError) {
        print('Fallback file creation failed: $fallbackError');

        // If all else fails, use an in-memory file
        final inMemoryFile = File.fromUri(Uri.file('/data.json'));
        await inMemoryFile
            .writeAsString(const JsonEncoder.withIndent('  ').convert(jsonData));
        return inMemoryFile;
      }
    }
  }

  // Upload to Flask server with improved error handling
  Future<void> _uploadToFlaskServer() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadResult = null;
      _downloadedImagePath = null;
    });

    try {
      final jsonData = {
        'name': userData['name'],
        'phoneNumber': userData['phoneNumber'],
        'message': widget.message,
        'urgency_color': _getColorName(widget.selectedColor),
        'location': locationData ?? {'latitude': 'Loading...', 'longitude': 'Loading...'}
      };

      var request = http.MultipartRequest('POST', Uri.parse('${Config.ipaddress}/embed'));

      var jsonFile = await _createJsonFile(jsonData);
      request.files.add(await http.MultipartFile.fromPath('json', jsonFile.path));

    if (widget.selectedImage != null) {
      File imageFile;
      if (widget.selectedImage!.startsWith('http') || widget.selectedImage!.startsWith('https')) {
        var response = await http.get(Uri.parse(widget.selectedImage!));
        var documentDirectory = await getApplicationDocumentsDirectory();
        imageFile = File('${documentDirectory.path}/temp_image.png');
        await imageFile.writeAsBytes(response.bodyBytes);
      } else {
        var documentDirectory = await getApplicationDocumentsDirectory();
        imageFile = File('${documentDirectory.path}/temp_image.png');
        ByteData data = await rootBundle.load(widget.selectedImage!);
        final buffer = data.buffer;
        await imageFile.writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      }

      if (!await imageFile.exists()) {
        setState(() {
          _uploadResult = 'Image file not found';
          _isUploading = false;
        });
        return;
      }

      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

      var response = await request.send();

      if (response.statusCode == 200) {
        var documentDirectory = await getApplicationDocumentsDirectory();
        var filePath = '${documentDirectory.path}/response_image_${DateTime.now().millisecondsSinceEpoch}.png';
        var file = File(filePath);
        
        await response.stream.pipe(file.openWrite());

        setState(() {
          _uploadResult = 'Upload successful. Image saved at $filePath';
          _downloadedImagePath = filePath;  // Store the path for download
          _isUploading = false;
        });

        print('Image saved at $filePath');
      } else {
        setState(() {
          _uploadResult = 'Upload failed: ${response.statusCode}';
          _isUploading = false;
        });
        print('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _uploadResult = 'Error: ${e.toString()}';
        _isUploading = false;
      });
      print('Error uploading to Flask server: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    // Prepare JSON data for display
    final jsonData = {
      'name': userData['name'],
      'phoneNumber': userData['phoneNumber'],
      'message': widget.message,
      'urgency_color': _getColorName(widget.selectedColor),
      'location':
          locationData ?? {'latitude': 'Loading...', 'longitude': 'Loading...'}
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black87,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.black87,
          elevation: 10,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Results',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.upload_file, color: Colors.white),
              onPressed: _uploadToFlaskServer,
              tooltip: 'Upload to Server',
            ),
            // New download button
            if (_downloadedImagePath != null)
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: _downloadImage,
                tooltip: 'Download Image',
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Upload Result Display
              if (_uploadResult != null)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: _uploadResult!.contains('successful')
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _uploadResult!,
                    style: TextStyle(
                      color: _uploadResult!.contains('successful')
                          ? Colors.green
                          : Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 20),

              // JSON Display
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        const JsonEncoder.withIndent('  ').convert(jsonData),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontFamily: 'monospace',
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // Image Display
              if (widget.selectedImage != null)
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: widget.selectedImage!.startsWith('http') ||
                            widget.selectedImage!.startsWith('https')
                        ? Image.network(
                            widget.selectedImage!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue.shade700),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade400,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(
                                        color: Colors.red.shade300,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Image.asset(
                            widget.selectedImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade400,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(
                                        color: Colors.red.shade300,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),

              // Upload Progress Indicator
              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
