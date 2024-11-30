// lib/screens/image_selection_screen.dart
import 'package:flutter/material.dart';
import 'image_categories.dart';

class ImageSelectionScreen extends StatefulWidget {
  final String categoryName;

  const ImageSelectionScreen({
    super.key, 
    required this.categoryName
  });

  @override
  _ImageSelectionScreenState createState() => _ImageSelectionScreenState();
}

class _ImageSelectionScreenState extends State<ImageSelectionScreen> {
  String? _selectedImage;

  @override
  Widget build(BuildContext context) {
    // Find the category with matching name
    final category = ImageCategory.getAllCategories()
        .firstWhere((cat) => cat.name == widget.categoryName);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryName} Images'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Horizontal Scrollable Images
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: category.images.length,
              itemBuilder: (context, index) {
                final image = category.images[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImage = image;
                    });
                  },
                  child: Container(
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
                            child: Text('Failed to load image',
                                style: TextStyle(color: Colors.red)),
                          );
                        },
                      ),
                    ),
                  ),
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
}