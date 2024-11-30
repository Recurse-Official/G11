// lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ResultScreen extends StatefulWidget {
  final String message;
  final Color? selectedColor;
  final String? selectedImage;

  const ResultScreen({
    super.key, 
    required this.message, 
    this.selectedColor, 
    this.selectedImage
  });

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Map<String, dynamic>? locationData;
  Map<String, String> userData = {
    'name': 'Error: Unable to fetch name',
    'phoneNumber': 'Error: Unable to fetch phone number'
  };
  bool _isLoading = true;

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

Future<void> _fetchUserData() async {
  try {
    // Get the user's phone number from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userPhone = prefs.getString('userPhone');
    
    if (userPhone != null) {
      // Fetch user document from Firestore using phone number
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhone)
          .get();

      // Update state with user data
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
          userData = {
            'name': 'User not found',
            'phoneNumber': userPhone
          };
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

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, set default location
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
        // Permissions are denied, set default location
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
      // Permissions are permanently denied, set default location
      setState(() {
        locationData = {
          'latitude': 'Location permissions permanently denied',
          'longitude': 'Location permissions permanently denied'
        };
      });
      return;
    } 

    // When we reach here, permissions are granted and services are enabled
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best
      );

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

  @override
  Widget build(BuildContext context) {
    // Prepare JSON data
    final jsonData = {
      'name': userData['name'],
      'phoneNumber': userData['phoneNumber'],
      'message': widget.message,
      'urgency_color': _getColorName(widget.selectedColor),
      'location': locationData ?? {'latitude': 'Loading...', 'longitude': 'Loading...'}
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
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      JsonEncoder.withIndent('  ').convert(jsonData),
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
                    child: widget.selectedImage!.startsWith('http') || widget.selectedImage!.startsWith('https')
                        ? Image.network(
                            widget.selectedImage!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue.shade700
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}