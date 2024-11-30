// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'image_categories.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedImage;

  @override
  Widget build(BuildContext context) {
    final categories = ImageCategory.getAllCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Selector'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Message Input Box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Enter your message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Message: ${_messageController.text}'),
                      ),
                    );
                  },
                ),
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),

          // Netflix-style Category Scrolls
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, categoryIndex) {
                final category = categories[categoryIndex];
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Heading
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, 
                        vertical: 8.0
                      ),
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Horizontal Scrollable Images for this Category
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: category.images.length,
                        itemBuilder: (context, imageIndex) {
                          final image = category.images[imageIndex];
                          
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImage = image;
                                });
                              },
                              child: Container(
                                width: 150,
                                decoration: BoxDecoration(
                                  border: _selectedImage == image
                                      ? Border.all(color: Colors.blue, width: 3)
                                      : null,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    image,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Text(
                                          'Failed to load image',
                                          style: TextStyle(color: Colors.red)
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Selected Image Display
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Selected Image:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Image.network(
                    _selectedImage!,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}